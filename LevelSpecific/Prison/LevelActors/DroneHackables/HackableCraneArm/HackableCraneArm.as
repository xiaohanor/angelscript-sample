event void CraneRemoveTutorial();

UCLASS(Abstract)
class AHackableCraneArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FSwarmHijackStartEvent OnHackingStarted;
	UPROPERTY()
	FSwarmHijackStopEvent OnHackingStopped;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComponent;

	UPROPERTY()
	CraneRemoveTutorial OnRemoveTutorial;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	UStaticMeshComponent TranslateMesh;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	USceneComponent YawRoot;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	UStaticMeshComponent ArmMeshA;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent CameraPivotComponent;
	FVector CameraWorldOffset;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent PitchRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	UStaticMeshComponent ArmMeshB;

	UPROPERTY(DefaultComponent, Attach = ArmMeshB)
	UStaticMeshComponent ArmMeshC;

	UPROPERTY(DefaultComponent, Attach = ArmMeshC)
	UStaticMeshComponent ArmMeshD;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	USceneComponent AttachPoint;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableCraneArmCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere, meta = (MakeEditWidget))
	FVector StartOffset = FVector(0.0, -100.0, 0.0);

	UPROPERTY(EditAnywhere, meta = (MakeEditWidget))
	FVector EndOffset = FVector(0.0, 100.0, 0.0);

	// Translation

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Translation")
	float TranslateSpeed = 500;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Translation")
	float TranslateDuration = 1;

	// FB TODO: A vector could be used instead of 3 floats, if we decide to not add any more axes
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedMoveAlpha;
	float MoveAlpha;
	FHazeAcceleratedFloat AccMoveAlpha;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Pitch")
	float PitchSpeed = 40;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Pitch")
	float MinPitch = -90.0;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Pitch")
	float MaxPitch = 20.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedPitchAlpha;
	float PitchAlpha;
	FHazeAcceleratedFloat AccPitchAlpha;

	// Yaw

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Yaw")
	float YawSpeed = 40;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Yaw")
	float MinYaw = -90.0;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Yaw")
	float MaxYaw = 0.0;

	// Spring

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Spring")
	float SpringStiffness = 100;

	UPROPERTY(EditAnywhere, Category = "Crane Arm|Spring")
	float SpringDamping = 0.4;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedYawAlpha;
	float YawAlpha;
	FHazeAcceleratedFloat AccYawAlpha;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedInput;	// X is Move, Y is Pitch, Z is Yaw

	float MoveInput;
	FVector2D RotateInput;

	const bool DEBUG_MAX_VALUES = false;

	float MaxMoveSpringSpeed;
	float MaxMoveInputSpeed;
	float MaxPitchSpringSpeed;
	float MaxPitchInputSpeed;
	float MaxYawSpringSpeed;
	float MaxYawInputSpeed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ClampCraneArm();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		HijackTargetableComp.OnHijackStartEvent.AddUFunction(this, n"HackingStarted");
		HijackTargetableComp.OnHijackStopEvent.AddUFunction(this, n"HackingStopped");

		ClampCraneArm();

		CameraWorldOffset = CameraComponent.GetWorldLocation() - CameraPivotComponent.GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DEBUG_MAX_VALUES)
		{
			float MoveSpringSpeed = GetMoveSpeedNormalized(true);
			float MoveSpringInput = GetMoveSpeedNormalized(false);

			float PitchSpringSpeed = GetArmPitchSpeedNormalized(true);
			float PitchInputSpeed = GetArmPitchSpeedNormalized(false);

			float YawSpringSpeed = GetArmYawSpeedNormalized(true);
			float YawInputSpeed = GetArmYawSpeedNormalized(false);

			PrintToScreen(f"{MoveSpringSpeed=}");
			PrintToScreen(f"{MoveSpringInput=}");

			PrintToScreen(f"{PitchSpringSpeed=}");
			PrintToScreen(f"{PitchInputSpeed=}");

			PrintToScreen(f"{YawSpringSpeed=}");
			PrintToScreen(f"{YawInputSpeed=}");


			MaxMoveSpringSpeed = Math::Max(MaxMoveSpringSpeed, MoveSpringSpeed);
			MaxMoveInputSpeed = Math::Max(MaxMoveInputSpeed, MoveSpringInput);

			MaxPitchSpringSpeed = Math::Max(MaxPitchSpringSpeed, PitchSpringSpeed);
			MaxPitchInputSpeed = Math::Max(MaxPitchInputSpeed, PitchInputSpeed);

			MaxYawSpringSpeed = Math::Max(MaxYawSpringSpeed, YawSpringSpeed);
			MaxYawInputSpeed = Math::Max(MaxYawInputSpeed, YawInputSpeed);

			PrintToScreen(f"{MaxMoveSpringSpeed=}");
			PrintToScreen(f"{MaxMoveInputSpeed=}");

			PrintToScreen(f"{MaxPitchSpringSpeed=}");
			PrintToScreen(f"{MaxPitchInputSpeed=}");
			
			PrintToScreen(f"{MaxYawSpringSpeed=}");
			PrintToScreen(f"{MaxYawInputSpeed=}");
		}
	}

	void ClampCraneArm()
	{
		// Clamp Location
		{
			FVector StartToEnd = EndOffset - StartOffset;
			if(StartToEnd.IsNearlyZero())
			{
				StartOffset = FVector(0.0, 100.0, 0.0);
				EndOffset = FVector(0.0, -100.0, 0.0);
				StartToEnd = EndOffset - StartOffset;
				PrintError("StartOffset and EndOffset cannot be identical!");
			}

			const float StartToEndDistance = Math::Max(StartToEnd.Size(), KINDA_SMALL_NUMBER);

			const FVector LineDirection = StartToEnd / StartToEndDistance;

			FVector ProjectedLocation = TranslateRoot.GetRelativeLocation().ProjectOnToNormal(LineDirection);

			// Make sure the projected location is between the end and start offsets
			{
				const FVector StartDiff = (ProjectedLocation - StartOffset).GetSafeNormal();
				const bool bIsBehindStart = StartDiff.DotProduct(LineDirection) < 0.0;

				const FVector EndDiff = (ProjectedLocation - EndOffset).GetSafeNormal();
				const bool bIsBehindEnd = EndDiff.DotProduct(LineDirection) > 0.0;

				if(bIsBehindStart)
					ProjectedLocation = StartOffset;
				else if(bIsBehindEnd)
					ProjectedLocation = EndOffset;
			}

			TranslateRoot.SetRelativeLocation(ProjectedLocation);

			const float ProjectedLocationDistance = (ProjectedLocation - StartOffset).Size();
			MoveAlpha = ProjectedLocationDistance / StartToEndDistance;
		}

		// Clamp Rotation
		{

			const float CurrentYaw = YawRoot.GetRelativeRotation().Yaw;
			const float ClampedYaw = Math::ClampAngle(CurrentYaw, MinYaw, MaxYaw);
			YawAlpha = Math::NormalizeToRange(ClampedYaw, MinYaw, MaxYaw);
			YawRoot.SetRelativeRotation(FRotator(0.0, ClampedYaw, 0.0));

			const float CurrentPitch = PitchRoot.GetRelativeRotation().Pitch;
			const float ClampedPitch = Math::ClampAngle(CurrentPitch, MinPitch, MaxPitch);
			PitchAlpha = Math::NormalizeToRange(ClampedPitch, MinPitch, MaxPitch);
			PitchRoot.SetRelativeRotation(FRotator(ClampedPitch, 0.0, 0.0));
		}

		SyncedMoveAlpha.SetValue(MoveAlpha);
		SyncedPitchAlpha.SetValue(PitchAlpha);
		SyncedYawAlpha.SetValue(YawAlpha);

		AccMoveAlpha.Value = MoveAlpha;
		AccPitchAlpha.Value = PitchAlpha;
		AccYawAlpha.Value = YawAlpha;
	} 
 
	UFUNCTION(NotBlueprintCallable)
	private void HackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		OnHackingStarted.Broadcast(HijackParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HackingStopped()
	{
		OnHackingStopped.Broadcast();
	}

	void UpdateCameraLocation()
	{
		FVector CameraLocation = CameraPivotComponent.GetWorldLocation() + CameraWorldOffset;
		FRotator CameraRotation = FRotator::MakeFromX(AttachPoint.WorldLocation - CameraLocation);
		CameraComponent.SetWorldLocationAndRotation(CameraLocation, CameraRotation);
	}

	void SyncInput() const
	{
		FVector Input = FVector(MoveInput, RotateInput.Y, RotateInput.X);
		SyncedInput.SetValue(Input);
	}

	void GetSyncedInput()
	{
		FVector Input = SyncedInput.GetValue();
		MoveInput = Input.X;
		RotateInput.Y = Input.Y;
		RotateInput.X = Input.Z;
	}

	UFUNCTION(BlueprintCallable)
	float GetMoveSpeed(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return AccMoveAlpha.Velocity;
		else
			return MoveInput;
	}

	UFUNCTION(BlueprintCallable)
	bool IsMoving(bool bUseSpringVelocity, float Threshold = 0.01) const
	{
		return Math::Abs(GetMoveSpeed(bUseSpringVelocity)) > Threshold;
	}

	UFUNCTION(BlueprintCallable)
	float GetMoveSpeedNormalized(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return Math::Saturate(Math::Abs(GetMoveSpeed(true)) * 5);
		else
			return Math::Saturate(Math::Abs(GetMoveSpeed(false)));
	}

	UFUNCTION(BlueprintCallable)
	int GetMoveDirection(bool bUseSpringVelocity, float Threshold = 0.01) const
	{
		if(!IsMoving(bUseSpringVelocity, Threshold))
			return 0;

		if(Math::Abs(GetMoveSpeed(bUseSpringVelocity)) > 0)
			return 1;
		else
			return -1;
	}

	UFUNCTION(BlueprintCallable)
	float GetYawSpeed(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return AccYawAlpha.Velocity;
		else
			return RotateInput.X;
	}

	UFUNCTION(BlueprintCallable)
	float GetPitchSpeed(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return AccPitchAlpha.Velocity;
		else
			return RotateInput.Y;
	}

	UFUNCTION(BlueprintCallable)
	bool IsArmRotating(bool bUseSpringVelocity, float Threshold = KINDA_SMALL_NUMBER) const
	{
		return IsArmYawing(bUseSpringVelocity, Threshold) || IsArmPitching(bUseSpringVelocity, Threshold);
	}

	UFUNCTION(BlueprintCallable)
	bool IsArmYawing(bool bUseSpringVelocity, float Threshold = KINDA_SMALL_NUMBER) const
	{
		return Math::Abs(GetYawSpeed(bUseSpringVelocity)) > Threshold;
	}

	UFUNCTION(BlueprintCallable)
	bool IsArmPitching(bool bUseSpringVelocity, float Threshold = KINDA_SMALL_NUMBER) const
	{
		return Math::Abs(GetPitchSpeed(bUseSpringVelocity)) > Threshold;
	}

	UFUNCTION(BlueprintCallable)
	int GetArmYawDirection(bool bUseSpringVelocity, float Threshold = KINDA_SMALL_NUMBER) const
	{
		if(!IsArmYawing(bUseSpringVelocity, Threshold))
			return 0;

		return int(Math::Sign(GetYawSpeed(bUseSpringVelocity)));
	}

	UFUNCTION(BlueprintCallable)
	int GetArmPitchDirection(bool bUseSpringVelocity, float Threshold = KINDA_SMALL_NUMBER) const
	{
		if(!IsArmPitching(bUseSpringVelocity, Threshold))
			return 0;

		return int(Math::Sign(GetPitchSpeed(bUseSpringVelocity)));
	}

	UFUNCTION(BlueprintCallable)
	float GetArmYawSpeedNormalized(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return Math::Saturate(Math::Abs(AccYawAlpha.Velocity * 3.7));
		else
			return Math::Saturate(Math::Abs(RotateInput.X));
	}

	UFUNCTION(BlueprintCallable)
	float GetArmPitchSpeedNormalized(bool bUseSpringVelocity) const
	{
		if(bUseSpringVelocity)
			return Math::Saturate(Math::Abs(AccPitchAlpha.Velocity * 1.23));
		else
			return Math::Saturate(Math::Abs(RotateInput.Y));
	}
};
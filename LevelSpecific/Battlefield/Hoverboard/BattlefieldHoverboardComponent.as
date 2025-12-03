struct FBattlefieldHoverboardAnimationParams
{
	UPROPERTY()	
	float VerticalSpeedWhileAirborne = 0.0;

	UPROPERTY()
	float LastLandingSpeed = 0;

	UPROPERTY()
	bool bIsJumpingOffGrind = false;

	UPROPERTY()
	bool bIsJumpingWhileGrinding = false;	

	UPROPERTY()
	bool bIsGrapplingToGrind = false;

	UPROPERTY()
	bool bIsJumpingToGrind = false;

	UPROPERTY()
	bool bIsJumpingBetweenGrinds = false;
}

class UBattlefieldHoverboardComponent : UActorComponent
{
	// SETUP
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ABattlefieldHoverboard> HoverboardClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UNiagaraSystem VisualRopeAsset = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FName AttachmentSocketName = n"LeftHand_IK";

	// SETTINGS
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset RidingCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UMovementSteppingSettings SteppingSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UMovementGravitySettings GravitySettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UMovementStandardSettings MovementStandardSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardGroundMovementSettings GroundMovementSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardAirMovementSettings AirMovementSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardGrindingSettings GrindSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardJumpSettings JumpSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardSwingSettings SwingSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardWallRunSettings WallRunSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardWallRunJumpSettings WallRunJumpSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardWallRunTransferSettings WallRunTransferSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UBattlefieldHoverboardTrickSettings TrickSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Death Settings")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Tricks")
	UBattlefieldHoverboardTrickList XTrickList;

	UPROPERTY(EditDefaultsOnly, Category = "Tricks")
	UBattlefieldHoverboardTrickList YTrickList;

	UPROPERTY(EditDefaultsOnly, Category = "Tricks")
	UBattlefieldHoverboardTrickList BTrickList;

	UPROPERTY(EditDefaultsOnly, Category = "Tricks")
	UForceFeedbackEffect TrickRumble;

	UPROPERTY(EditDefaultsOnly, Category = "Exit Animations")
	FHazePlaySlotAnimationParams ExitAnim_Enter;

	UPROPERTY(EditDefaultsOnly, Category = "Exit Animations")
	FHazePlaySlotAnimationParams ExitAnim_MH;

	AHazePlayerCharacter Player;
	ABattlefieldHoverboard Hoverboard;

	private UPlayerMovementComponent MoveComp; 
	private UCameraUserComponent CameraUserComp;
	private UBattlefieldHoverboardSplineBasedTurningComponent SplineBasedTurningComp;

	private bool bIsOn = false;
	bool bCanRunSpeedEffect = true;
	bool bIsGrounded = false;

	FBattlefieldHoverboardAnimationParams AnimParams;

	FRotator WantedRotation;
	FRotator CameraWantedRotation;
	FRotator NudgeWantedRotation;
	FHazeAcceleratedRotator AccNudgeRotation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedRotator AccYawAxis;
	FHazeAcceleratedFloat AccCameraYawAxisTilt;

	private float RotationDuration = 0.0;

	const float NudgeRotationThreshold = 2.0;
	const float NudgeRotationInterpBackSpeed = 40;
	const float NudgeRotationAccelerationDuration = 0.2;

	float TrickBoostSpeed = 0.0;

	bool bBackwardsSnipeEnabled = true;
	bool bHasFinished = false;
	bool bHasQueuedCavernSpeedInitialization = false;
	bool bSnowEffectsEnabled = true;

	float FinishTime = -1.0;
	float FinishPoints = -1.0;

	TOptional<bool> WonRace;
	AActor MioFinishLineActor;
	AActor ZoeFinishLineActor;

	TArray<ABattlefieldHoverboardSnipeVolume> SniperVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ResetWantedRotationToCurrentRotation();
		SetCameraWantedRotationToWantedRotation();
		AccRotation.SnapTo(Player.ActorRotation);
		
		Player.ApplyDefaultSettings(CameraControlSettings);
		Player.ApplyDefaultSettings(GroundMovementSettings);
		Player.ApplyDefaultSettings(AirMovementSettings);
		Player.ApplyDefaultSettings(GrindSettings);
		Player.ApplyDefaultSettings(JumpSettings);
		Player.ApplyDefaultSettings(SwingSettings);
		Player.ApplyDefaultSettings(GrappleSettings);
		Player.ApplyDefaultSettings(WallRunSettings);
		Player.ApplyDefaultSettings(WallRunJumpSettings);
		Player.ApplyDefaultSettings(WallRunTransferSettings);
		Player.ApplyDefaultSettings(TrickSettings);

		MoveComp = UPlayerMovementComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::Hidden, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Value("FinishTime", FinishTime)
			.Value("FinishPoints", FinishPoints)
		;
	}

	UFUNCTION(BlueprintCallable)
	void ToggleHoverboard(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(bIsOn)
				return;

			bIsOn = true;
		}
		else
		{
			if(!bIsOn)
				return;

			bIsOn = false;
		}
	}

	bool IsOn() const
	{
		return bIsOn;
	}

	void AddWantedRotation(float RotationSpeed, FVector Input, float DeltaTime)
	{
		if(SplineBasedTurningComp == nullptr)
			SplineBasedTurningComp = UBattlefieldHoverboardSplineBasedTurningComponent::Get(Player);

		if(SplineBasedTurningComp != nullptr
		&& SplineBasedTurningComp.bIsActive)
		{
			OverrideWithSplineBasedRotation(Input, DeltaTime);
			return;
		}

		if(Input.IsNearlyZero())
		{
			NudgeWantedRotation = Math::RInterpConstantTo(NudgeWantedRotation, FRotator::ZeroRotator, DeltaTime, NudgeRotationInterpBackSpeed);
			return;
		}

		if(Math::Abs(AccNudgeRotation.Value.Yaw) < NudgeRotationThreshold)
			NudgeWantedRotation.Yaw += Input.Y * RotationSpeed * DeltaTime;
		else
			WantedRotation.Yaw += Input.Y * RotationSpeed * DeltaTime;
	}

	void ResetWantedRotationToCurrentRotation(bool bFlatRotation = true)
	{
		FRotator NewWantedRotation = Player.ActorRotation;
		if(bFlatRotation)
		{
			NewWantedRotation.Pitch = 0.0;
			NewWantedRotation.Roll = 0.0;
		}

		WantedRotation = NewWantedRotation;
	}

	void SetCameraWantedRotationToWantedRotation()
	{
		CameraWantedRotation = WantedRotation;
	}

	void RotateTowardsWantedRotation(float TargetRotationDuration, float DeltaTime)
	{
		if(SplineBasedTurningComp == nullptr)
			SplineBasedTurningComp = UBattlefieldHoverboardSplineBasedTurningComponent::Get(Player);

		if(SplineBasedTurningComp != nullptr
		&& SplineBasedTurningComp.bIsActive)
			return;

		RotationDuration = Math::FInterpConstantTo(RotationDuration, TargetRotationDuration, DeltaTime, 0.5);
		AccNudgeRotation.AccelerateTo(NudgeWantedRotation, NudgeRotationAccelerationDuration, DeltaTime);
		AccRotation.AccelerateTo(WantedRotation, RotationDuration, DeltaTime);
	}


	FVector GetMovementInputWorldSpace() const
	{
		if(HasControl())
			return MoveComp.MovementInput;
		else
			return MoveComp.GetSyncedMovementInputForAnimationOnly();
	}

	FVector GetMovementInputPlayerSpace() const
	{
		FVector MovementInput;
		if(HasControl())
			MovementInput = MoveComp.MovementInput;
		else
			MovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
		MovementInput = Player.ActorRotation.RotateVector(MovementInput);
		return MovementInput;
	}

	FVector GetMovementInputCameraSpace() const
	{
		FVector MovementInput;
		if(HasControl())
			MovementInput = MoveComp.MovementInput;
		else
			MovementInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
		MovementInput = CameraUserComp.ControlRotation.RotateVector(MovementInput);
		return MovementInput;
	}

	FVector GetAnimRootOffset() const
	{
		return FVector(0, 0, GroundMovementSettings.DistanceFromGround);
	}

	private void OverrideWithSplineBasedRotation(FVector MovementInput, float DeltaTime)
	{
		auto Trigger = SplineBasedTurningComp.Trigger;
		FSplinePosition SplinePos = SplineBasedTurningComp.SplineActor.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FRotator InputRotation = FRotator(0, Trigger.MaxTurningFromSpline * MovementInput.Y, 0);
		FRotator TargetRotation = SplinePos.WorldRotation.Rotator() + InputRotation;
		TargetRotation.Pitch = 0.0;
		TargetRotation.Roll = 0.0;

		float TurningDuration = Trigger.TurningDurationWithInput;
		if(Math::Abs(MovementInput.Y) < 0.2)
			TurningDuration = Trigger.TurningDurationWithoutInput;
		AccRotation.AccelerateTo(TargetRotation, TurningDuration, DeltaTime);
	}

	UFUNCTION()
	void HideHoverboardForCutscene()
	{
		Hoverboard.SetActorHiddenInGame(true);
	}
}
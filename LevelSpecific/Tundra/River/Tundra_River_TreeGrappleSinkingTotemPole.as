class ATundra_River_TreeGrappleSinkingTotemPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent TotemsRoot;

	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent Totem1MeshComp;

	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent Totem2MeshComp;

	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent Totem3MeshComp;
	
	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent Totem4MeshComp;

	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent Totem5MeshComp;

	UPROPERTY(DefaultComponent, Attach = TotemsRoot)
	UStaticMeshComponent TotemTopMeshComp;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent TreeGrappleRoot;

	UPROPERTY(DefaultComponent, Attach = TreeGrappleRoot)
	UStaticMeshComponent TreeGrappleMeshComp;

	UPROPERTY(DefaultComponent, Attach = TreeGrappleRoot)
	UTundraTreeGuardianRangedInteractionTargetableComponent TreeGrappleTargetComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> MovingCamShake;

	UPROPERTY(EditAnywhere)
	bool bRotateClockwise = true;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 135;
	
	UPROPERTY(EditAnywhere)
	float RotationSpeed = 12;

	UPROPERTY(EditAnywhere)
	float MaxRotateAngle = 45;

	UPROPERTY(EditAnywhere)
	float MinHeight = -1400;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;

	bool bMoving = false;
	bool bMovingDown = false;
	bool bMoveLocked = true;
	float MoveAlpha;
	AHazePlayerCharacter ZoeRef;
	UCameraShakeBase MovingCamShakeRef;
	FHazeFrameForceFeedback FrameFFSettings;
	default FrameFFSettings.LeftMotor = 0.25;
	default FrameFFSettings.RightMotor = 0.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ZoeRef = Game::GetZoe();
		SetActorControlSide(ZoeRef);
		
		TreeGrappleTargetComp.OnStartInteract.AddUFunction(this, n"PlayerGrappleStarted");
		TreeGrappleTargetComp.OnLeaveGrapplePoint.AddUFunction(this, n"PlayerGrappleLeft");
		TreeGrappleTargetComp.OnStopInteract.AddUFunction(this, n"PlayerGrappleStopped");
	}

	UFUNCTION()
	private void PlayerGrappleLeft()
	{
		bMovingDown = false;
		bMoveLocked = false;
	}

	UFUNCTION()
	private void PlayerGrappleStarted()
	{
		bMovingDown = true;
		bMoveLocked = false;
	}

	UFUNCTION()
	private void PlayerGrappleStopped()
	{
		bMoveLocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMoveLocked)
			return;

		MovePole(DeltaSeconds);
		//RotatePole();
	}

	private void MovePole(float DeltaSeconds)
	{
		if(HasControl())
		{
			// Set target position
			float TargetHeight = bMovingDown ? MinHeight : 0;

			// Calculate move delta
			float ToTargetDelta = TargetHeight - MoveRoot.RelativeLocation.Z;

			float MoveDirection = bMovingDown && MoveRoot.RelativeLocation.Z > MinHeight ? -1 : !bMovingDown && MoveRoot.RelativeLocation.Z < 0 ? 1 : 0;

			float MoveDelta = MoveDirection * MoveSpeed * DeltaSeconds;

			if(Math::IsNearlyEqual(Math::Abs(MoveDelta), Math::Abs(ToTargetDelta)) || Math::Abs(MoveDelta) > Math::Abs(ToTargetDelta))
			{
				MoveDelta = ToTargetDelta;

				bMoving = false;

				if(MovingCamShakeRef != nullptr)
				{
					CrumbHandleFeedback(false);
				}
			}
			else
			{
				bMoving = true;
				
				if(MovingCamShakeRef == nullptr)
				{
					CrumbHandleFeedback(true);
				}
			}

			MoveAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, MinHeight), FVector2D(0, 1), MoveRoot.RelativeLocation.Z);

			FVector MoveDeltaVector = FVector(0, 0, MoveDelta);

			// Add move delta to position
			MoveRoot.SetRelativeLocation(MoveRoot.RelativeLocation + MoveDeltaVector);
			SyncedLocation.Value = MoveRoot.GetRelativeLocation();
		}
		else
		{
			MoveRoot.SetRelativeLocation(SyncedLocation.Value);
		}
	}

	private void RotatePole()
	{

		if(HasControl())
		{
			if(!bMoving)
				return;

			float CurrentYaw = Math::Lerp(0, bRotateClockwise ? MaxRotateAngle : -MaxRotateAngle, MoveAlpha);
			FRotator NewRotation = FRotator(0, CurrentYaw, 0);

			if(bMovingDown)
			{
				//ZoeRef.RootComponent.SetRelativeRotation(NewRotation + FRotator(0, -45, 0));
			}

			MoveRoot.SetRelativeRotation(NewRotation * RotationSpeed);
			SyncedRotation.Value = MoveRoot.GetRelativeRotation();
		}
		else
		{
			MoveRoot.SetRelativeRotation(SyncedRotation.Value);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHandleFeedback(bool Start)
	{
		if(Start)
		{
			ZoeRef.SetFrameForceFeedback(FrameFFSettings);
			MovingCamShakeRef = ZoeRef.PlayCameraShake(MovingCamShake, this);
		}
		else
		{
			bMoveLocked = true;
			ZoeRef.StopCameraShakeInstance(MovingCamShakeRef);
			MovingCamShakeRef = nullptr;
		}
	}
};
class UDanceShowdownCameraManager : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	TArray<AHazeCameraActor> Cameras;

	FRotator CameraOriginalRotation;
	FRotator CameraTargetRotation;
	FVector CameraOriginalLocation;
	FVector CameraTargetLocation;
	FHazeAcceleratedRotator AccRot;
	FHazeAcceleratedVector AccLoc;
	AHazeCameraActor CurrentCamera;

	UPROPERTY(EditAnywhere)
	const float FailZoomStrength = 150;

	UPROPERTY(EditAnywhere)
	const float VerticalAngleOffset = 1;

	UPROPERTY(EditAnywhere)
	const float HorizontalAngleOffset = 1.5;

	UPROPERTY(EditAnywhere)
	bool bUseSpring = true;

	//Using acceleration
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bUseSpring", EditConditionHides))
	const float AccelerationTime = 0.2;

	//Using spring
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseSpring", EditConditionHides))
	const float SpringStiffness = 50;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseSpring", EditConditionHides))
	const float SpringDamping = 0.7;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DanceShowdown::GetManager().PoseManager.OnNewPoseEvent.AddUFunction(this, n"OnNewPose");
		DanceShowdown::GetManager().PoseManager.OnPlayerFailedEvent.AddUFunction(this, n"OnFailed");
		DanceShowdown::GetManager().FaceMonkeyManager.OnBothMonkeysRemovedEvent.AddUFunction(this, n"OnRecover");
		
		CurrentCamera = Cameras[0];
		CameraOriginalRotation = CurrentCamera.ActorRotation;
		CameraTargetRotation = CameraOriginalRotation;
		CameraOriginalLocation = CurrentCamera.ActorLocation;
		CameraTargetLocation = CameraOriginalLocation;
		AccRot.SnapTo(CameraOriginalRotation);
		AccLoc.SnapTo(CameraOriginalLocation);
	}


	UFUNCTION()
	private void OnRecover(float Time)
	{
		CameraTargetLocation = CameraOriginalLocation;
	}

	UFUNCTION()
	private void OnFailed(UDanceShowdownPlayerComponent Player)
	{
		CameraTargetRotation = CameraOriginalRotation;
		CameraTargetLocation = CameraOriginalLocation + CameraTargetRotation.ForwardVector * FailZoomStrength;
	}

	UFUNCTION(BlueprintCallable)
	void UpdateCamera()
	{
		CurrentCamera = Cast<AHazeCameraActor>(Game::Mio.GetCurrentlyUsedCamera().Owner);
		//CurrentCamera = Cameras[DanceShowdown::GetManager().RhythmManager.GetCurrentStage()];
		CameraOriginalLocation = CurrentCamera.ActorLocation;
		CameraTargetLocation = CameraOriginalLocation;
		AccLoc.SnapTo(CameraTargetLocation);
		CameraOriginalRotation = CurrentCamera.ActorRotation;
		CameraTargetRotation = CameraOriginalRotation;
		AccRot.SnapTo(CameraOriginalRotation);
	}

	UFUNCTION()
	private void OnNewPose(EDanceShowdownPose NewPose)
	{
		CameraTargetRotation = CameraOriginalRotation;

		switch(NewPose)
		{
			case EDanceShowdownPose::Up:
				CameraTargetRotation += FRotator(VerticalAngleOffset, 0, 0);
				break;

			case EDanceShowdownPose::Down:
				CameraTargetRotation -= FRotator(VerticalAngleOffset, 0, 0);
				break;

			case EDanceShowdownPose::Right:
				CameraTargetRotation += FRotator(0, HorizontalAngleOffset, 0);
				break;

			case EDanceShowdownPose::Left:
				CameraTargetRotation -= FRotator(0, HorizontalAngleOffset, 0);
				break;

			default:
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bUseSpring)
		{
			AccRot.SpringTo(CameraTargetRotation, SpringStiffness, SpringDamping, DeltaSeconds);
			AccLoc.SpringTo(CameraTargetLocation, SpringStiffness, SpringDamping, DeltaSeconds);
		}
		else
		{
			AccRot.AccelerateTo(CameraTargetRotation, AccelerationTime, DeltaSeconds);
			AccLoc.AccelerateTo(CameraTargetLocation, AccelerationTime, DeltaSeconds);
		}

		CurrentCamera.SetActorLocationAndRotation(AccLoc.Value, AccRot.Value);
	}
};
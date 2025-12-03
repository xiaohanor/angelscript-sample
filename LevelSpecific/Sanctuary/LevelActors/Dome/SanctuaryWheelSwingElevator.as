class ASanctuaryWheelSwingElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WheelRootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ChainRootComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	float ChainDistance = 3300.0;
	float WheelRadius = 300.0;

	float WindUpDuration = 7.0; // 3.0
	float RetractDuration = 1.5;

	bool bGrabbed = false;
	UPROPERTY(BlueprintReadOnly)
	FHazeAcceleratedFloat AccChainProgress;
	float TargetProgress = 0.0;

	bool bUpper = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");

		TargetProgress = ChainDistance * 0.50;
		AccChainProgress.SnapTo(TargetProgress);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if (bGrabbed)
		// {
		// 	if (TargetProgress < ChainDistance)
		// 		TargetProgress += (ChainDistance / WindUpDuration) * DeltaSeconds;

		// 	AccChainProgress.AccelerateTo(TargetProgress, 4.0, DeltaSeconds);
		// }
		// else
		// {
		// 	if (TargetProgress > 0.0)
		// 		TargetProgress -= (ChainDistance / RetractDuration) * DeltaSeconds;

		// 	AccChainProgress.SpringTo(TargetProgress, 20.0, 1.0, DeltaSeconds);
		// }

		if (bGrabbed)
		{
			if (bUpper && TargetProgress < ChainDistance)
				TargetProgress += (ChainDistance / WindUpDuration) * DeltaSeconds;

			else if (TargetProgress > 0.0)
				TargetProgress -= (ChainDistance / WindUpDuration) * DeltaSeconds;

				float FFFrequency = 30.0;
				float FFIntensity = 0.4;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Game::Zoe.SetFrameForceFeedback(FF);
		}

		AccChainProgress.AccelerateTo(TargetProgress, 2.0, DeltaSeconds);

		float ChainAlpha = Math::Abs(AccChainProgress.Value);

		ChainRootComp.SetRelativeLocation(-FVector::UpVector * (ChainDistance - ChainAlpha));
		WheelRootComp.SetRelativeRotation(FRotator(0.0, 0.0, ChainAlpha / 5.0));
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (TargetComponent == TargetComp)
			bUpper = true;
		else
			bUpper = false;

		bGrabbed = true;
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bGrabbed = false;
	}
};
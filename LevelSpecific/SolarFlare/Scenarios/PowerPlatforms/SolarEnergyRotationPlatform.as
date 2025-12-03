enum ESolarRotationPlatformType
{
	Pitch,
	Roll
}

class ASolarEnergyRotationPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SecondRotationRoot;

	bool bIsActive = false;

	UPROPERTY(EditDefaultsOnly)
	ESolarRotationPlatformType FormingPlatformRotationType;

	UPROPERTY(EditDefaultsOnly)
	float AxisEndAmount;

	UPROPERTY(DefaultComponent)
	USolarEnergyPulseResponseComponent PulseResponseComp;

	float RotationStartDelay = 0.0;
	float DelayTime;

	float RotationEnd;
	float RotationStart;

	// UPROPERTY(EditAnywhere)
	// ASolarEnergyPulseSpline EnergySpline;

	UPROPERTY(EditDefaultsOnly)
	float AccelerationDuration = 1.5;

	UPROPERTY(EditAnywhere)
	float ActivationDuration = 4.0;
	float ActivationTime;

	//TODO Add bounciness logic

	FHazeAcceleratedFloat MainAxisValue;
	FHazeAcceleratedFloat SideAxisValue;
	FRotator StartingRotation;

	FVector StartTranslation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingRotation = MeshRoot.RelativeRotation;

		switch(FormingPlatformRotationType)
		{
			case ESolarRotationPlatformType::Pitch:
				RotationStart = MeshRoot.RelativeRotation.Pitch;
				break;

			case ESolarRotationPlatformType::Roll:
				RotationStart = MeshRoot.RelativeRotation.Roll;
				break;
		}

		RotationEnd = RotationStart + AxisEndAmount;

		MainAxisValue.SnapTo(RotationStart);
		SideAxisValue.SnapTo(RotationStart);

		PulseResponseComp.SolarEnergyPulseStarted.AddUFunction(this, n"SolarEnergyPulseStarted");
		PulseResponseComp.SolarEnergyPulseStopped.AddUFunction(this, n"SolarEnergyPulseStopped");

		// EnergySpline.TargetActors.AddUnique(this);
		// EnergySpline.AddTargetActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsActive)
			MainAxisValue.AccelerateTo(RotationEnd, AccelerationDuration / 5.0, DeltaSeconds);
		else	
			MainAxisValue.AccelerateTo(RotationStart, AccelerationDuration, DeltaSeconds);

		FRotator EndRotMain = FRotator(MainAxisValue.Value, StartingRotation.Yaw, StartingRotation.Roll);
		MeshRoot.RelativeRotation = EndRotMain;

		// FVector EndLoc;

		// if (bIsActive)
		// {
		// 	SideAxisValue.AccelerateTo(RotationEnd, AccelerationDuration / 5.0, DeltaSeconds);
			
		// 	if (Time::GameTimeSeconds > DelayTime)
		// 		MainAxisValue.AccelerateTo(RotationEnd, AccelerationDuration / 5.0, DeltaSeconds);
		// }
		// else
		// {
		// 	SideAxisValue.AccelerateTo(RotationStart, AccelerationDuration, DeltaSeconds);
		// 	MainAxisValue.AccelerateTo(RotationStart, AccelerationDuration, DeltaSeconds);
		// 	EndLoc = StartTranslation;
		// }

		// D
		// FRotator EndRotSide;

		// switch(FormingPlatformRotationType)
		// {
		// 	case ESolarRotationPlatformType::Pitch:
		// 		EndRotMain = FRotator(MainAxisValue.Value, StartingRotation.Yaw, StartingRotation.Roll);
		// 		EndRotSide = FRotator(SideAxisValue.Value, StartingRotation.Yaw, StartingRotation.Roll);
		// 		break;

		// 	case ESolarRotationPlatformType::Roll:
		// 		EndRotMain = FRotator(StartingRotation.Pitch, StartingRotation.Yaw, MainAxisValue.Value);
		// 		EndRotSide = FRotator(StartingRotation.Pitch, StartingRotation.Yaw, SideAxisValue.Value);
		// 		break;
		// }

		// // SecondRotationRoot.RelativeRotation = EndRotSide;
		// MeshRoot.RelativeRotation = EndRotMain;

		// if (Time::GameTimeSeconds > ActivationTime)
		// 	bIsActive = false;
	}

	UFUNCTION()
	void SolarEnergyPulseStarted()
	{
		bIsActive = true;
		// DelayTime = Time::GameTimeSeconds + RotationStartDelay;
		// ActivationTime = Time::GameTimeSeconds + ActivationDuration;
	}
	
	UFUNCTION()
	void SolarEnergyPulseStopped()
	{
		bIsActive = false;
	}
}
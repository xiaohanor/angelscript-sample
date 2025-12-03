
UCLASS(Abstract)
class UWorld_Prison_Stealth_Interactable_HackableWaterGear_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	TArray<FAkSoundPosition> SoundPositions;
	const float MAX_STICK_ROTATION_SPEED = 3000;

	UPROPERTY(BlueprintReadOnly)
	AHackableWaterGear HackableWaterGear;

	AHackableGearsManager Manager;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEmitter MazeWheelEmitter;

	UPROPERTY()
	float VisualRotationSpeed = 0;

	UFUNCTION(BlueprintPure)
	float GetRotationSpeed()
	{
		// To support networking we configure it to follow one of the water wheels rotation changes.
		return VisualRotationSpeed;
		// This isn't networked.
		//return Math::GetMappedRangeValueClamped(
		//	FVector2D(-MAX_STICK_ROTATION_SPEED, MAX_STICK_ROTATION_SPEED), 
		//	FVector2D(-1.0, 1.0), HackableWaterGear.RotationSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HackableWaterGear = Cast<AHackableWaterGear>(HazeOwner);
		Manager = TListedActors<AHackableGearsManager>().GetSingle();

		const int NumWaterWheels = HackableWaterGear.Wheels.Num() - 1; // Last wheel in array should be the maze wheel;
		SoundPositions.SetNum(NumWaterWheels);

		for(int i = 0; i < NumWaterWheels; ++i)
		{
			SoundPositions[i].SetPosition(HackableWaterGear.Wheels[i].ActorLocation);
		}

		DefaultEmitter.SetMultiplePositions(SoundPositions);
		// For networking, track the rotation
		DefaultEmitter.AttachEmitterTo(HackableWaterGear.Wheels[0].FanRotationRoot);
		MazeWheelEmitter.AttachEmitterTo(HackableWaterGear.Wheels.Last().RootComponent);

		Manager.OperationTrigger.OnPlayerEnter.AddUFunction(this, n"OnMagnetDroneEnterMazeWheel");
		Manager.OperationTrigger.OnPlayerLeave.AddUFunction(this, n"OnMagnetDroneExitMazeWheel");
	}

	UFUNCTION(BlueprintEvent)
	void OnMagnetDroneEnterMazeWheel(AHazePlayerCharacter Player)
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnMagnetDroneExitMazeWheel(AHazePlayerCharacter Player)
	{		
	}
}

UCLASS(Abstract)
class UWorld_Skyline_Nightclub_Alley_Spot_PerchLight_WaveGrid_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible, Category = "Emitters")
	UHazeAudioEmitter PerchLightsMultiEmitter;

	UPROPERTY(NotVisible, Category = "Emitters")
	UHazeAudioEmitter DangerLightsMultiEmitter;

	UPROPERTY(BlueprintReadWrite)
	float PerchPitchValue = 0.0;

	ASkylineWaveGrid WaveGrid;
	
	UPROPERTY(BlueprintReadOnly)
	float WaveAlpha = 0;

	private float SinPos = 0;

	private TArray<AActor> DangerLights;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WaveGrid = Cast<ASkylineWaveGrid>(HazeOwner);	

		for(auto& Actor : WaveGrid.Actors)
		{
			// We can't perch on danger lights
			auto DangerLight = Cast<ASkylinePerchLightDangerous>(Actor);
			if(DangerLight != nullptr)
				continue;

			auto PerchComp = UPerchPointComponent::Get(Actor);
			PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerEnterPerchOnLight");
			PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerExitPerchOnLight");
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnterPerchOnLight(AHazePlayerCharacter Player, UPerchPointComponent PerchComp) {}	

	UFUNCTION(BlueprintEvent)
	void OnPlayerExitPerchOnLight(AHazePlayerCharacter Player, UPerchPointComponent PerchComp) {}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<FAkSoundPosition> MultiPositions;
		TArray<FAkSoundPosition> DangerPositions;		

		FVector TargetWaveApexLocation;
		FVector TargetLowPoint = FVector(0, 0, BIG_NUMBER);

		for(auto& Actor : WaveGrid.Actors)
		{
			auto ActorLocation = Actor.ActorLocation;
			
			auto DangerLight = Cast<ASkylinePerchLightDangerous>(Actor);
			if(DangerLight != nullptr)
			{
				DangerPositions.Add(FAkSoundPosition(ActorLocation));
			}
			else
			{
				MultiPositions.Add(FAkSoundPosition(ActorLocation));
			}

			if(ActorLocation.Z > TargetWaveApexLocation.Z)
				TargetWaveApexLocation = ActorLocation;

			if(ActorLocation.Z < TargetLowPoint.Z)
				TargetLowPoint = ActorLocation;
		}

		PerchLightsMultiEmitter.AudioComponent.SetMultipleSoundPositions(MultiPositions, AkMultiPositionType::MultiDirections);
		DangerLightsMultiEmitter.AudioComponent.SetMultipleSoundPositions(DangerPositions, AkMultiPositionType::MultiDirections);

		WaveAlpha = Math::Sin(SinPos);
		WaveAlpha = (WaveAlpha + 1) / 2;
		SinPos += DeltaSeconds;

		PerchPitchValue = Math::FInterpTo(PerchPitchValue, 0.0, DeltaSeconds, 3.0);	
	}
}
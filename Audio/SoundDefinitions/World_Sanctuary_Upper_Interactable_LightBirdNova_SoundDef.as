
UCLASS(Abstract)
class UWorld_Sanctuary_Upper_Interactable_LightBirdNova_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlayerStartPerchOnParticle(FLightBirdNovaParticlePerchEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnNovaIlluminated(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerStopPerchOnParticle(FLightBirdNovaParticlePerchEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnNovaDelluminated(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter NovaParticlesMultiEmitter;

	ASanctuaryLightBirdNova Nova; 
	TArray<FAkSoundPosition> ParticleSoundPositions;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"NovaParticlesMultiEmitter")
		{
			bUseAttach = false;
			return false;
		}

		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Nova = Cast<ASanctuaryLightBirdNova>(HazeOwner);
		ParticleSoundPositions.SetNum(Nova.NumNovaParticles);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<FVector> NovaParticleLocations;
		Nova.GetNovaParticlesLocations(NovaParticleLocations);

		for(int i = 0; i < Nova.NumNovaParticles; ++i)
		{
			ParticleSoundPositions[i] = FAkSoundPosition(NovaParticleLocations[i]);
		}
		
		NovaParticlesMultiEmitter.AudioComponent.SetMultipleSoundPositions(ParticleSoundPositions);
	}

}
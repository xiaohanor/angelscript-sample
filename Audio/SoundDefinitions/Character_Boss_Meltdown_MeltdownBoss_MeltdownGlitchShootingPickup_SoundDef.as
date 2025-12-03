
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_MeltdownGlitchShootingPickup_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPowerupCollected(FMeltdownGlitchShootingPickupPowerupParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPrePowerupReachedGlitch(){}

	UFUNCTION(BlueprintEvent)
	void OnPickupStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnPreAllReachedTarget(){}

	UFUNCTION(BlueprintEvent)
	void OnPowerupDelayedSpawned(FMeltdownGlitchShootingDelayedSpawnPowerupParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPickupFinished(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownGlitchShootingPickup GlitchPickup;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UHazeAudioEmitter GlitchPickupsMultiEmitter;

	UFUNCTION(BlueprintEvent)
	void OnPlayerStartedInteracting(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction, UInteractionComponent InteractionComponent) {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GlitchPickup = Cast<AMeltdownGlitchShootingPickup>(HazeOwner);
		GlitchPickup.OnPlayerStartedInteracting.AddUFunction(this, n"OnPlayerStartedInteracting");
		
		TArray<FAkSoundPosition> GlitchPowerUpSoundPositions;
		const int NumGlitchPowerups = GlitchPickup.Powerups.Num();
		GlitchPowerUpSoundPositions.SetNum(NumGlitchPowerups);

		for(int i = 0; i < NumGlitchPowerups; ++i)
		{
			GlitchPowerUpSoundPositions[i].SetPosition(GlitchPickup.Powerups[i].ActorLocation);
		}

		GlitchPickupsMultiEmitter.SetMultiplePositions(GlitchPowerUpSoundPositions);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}	

	UFUNCTION(BlueprintPure)
	float GetGlitchButtonMashProgress()
	{
		return 
		(Game::Mio.GetButtonMashProgress(GlitchPickup.ButtonMashInstigatorTag) + 
		Game::Zoe.GetButtonMashProgress(GlitchPickup.ButtonMashInstigatorTag)) / 2;
	}
}
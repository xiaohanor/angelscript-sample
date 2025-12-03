
UCLASS(Abstract)
class UWorld_Shared_Spot_SideStory_Portal_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlayersEnteringSideStory(){}

	UFUNCTION(BlueprintEvent)
	void OnExitSideStoryComplete(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerEnteredInteraction(FSideGlitchInteractionPlayerParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UHazeAudioRuntimeEffectSystem EffectsSystem;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, EditFixedSize)
	TArray<UHazeAudioEvent> MusicTrackEvents;
	default MusicTrackEvents.SetNum(4);
	UPROPERTY(BlueprintReadOnly, EditConst)
	TArray<FHazeAudioPostEventInstance> MusicTrackEventInstances;
	default MusicTrackEventInstances.SetNum(4);

	UPROPERTY(BlueprintReadWrite)
	int NumMusicTracks = 0;

	UPROPERTY()
	float FadeInDuration = 5;

	UPROPERTY()
	float FadeInTimer = 0;

	ASideGlitchInteractionActor SideInteractionActor;

	UFUNCTION(BlueprintPure)
	float ModifyAlphaByFadeIn(const float& Target, const float& BaseValue = 1) const
	{
		if (FadeInTimer < FadeInDuration)
		{
			auto Alpha = Math::Clamp(FadeInTimer/FadeInDuration, 0, 1);
			
			return Math::Lerp(BaseValue, Target, Alpha);
		}

		return Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SideInteractionActor.IsActorDisabled())
			return false;

		if(SideInteractionActor.bTriggered)	
			return false;

		if(Game::GetMio().bIsParticipatingInCutscene)
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SideInteractionActor.IsActorDisabled())
			return true;

		if(SideInteractionActor.bTriggered)
			return true;

		if(Game::GetMio().bIsParticipatingInCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SideInteractionActor = Cast<ASideGlitchInteractionActor>(HazeOwner);
		EffectsSystem = Game::GetSingleton(UHazeAudioRuntimeEffectSystem); 
		
		for(auto& MusicTrackEvent : MusicTrackEvents)
		{
			if(MusicTrackEvent != nullptr)
				++NumMusicTracks;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FadeInTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (FadeInTimer < FadeInDuration)
			FadeInTimer += DeltaSeconds;
	}

	UFUNCTION(BlueprintCallable)
	void SetRuntimeEffectAlpha(FHazeAudioRuntimeEffectInstance& Effect, const float Alpha)
	{
		if (!Effect.IsValid())
			return;

		Effect.SetAlpha(Alpha);
	}

	UFUNCTION(BlueprintCallable)
	void ReleaseEffect(FHazeAudioRuntimeEffectInstance& Effect)
	{
		if (!Effect.IsValid())
			return;
		
		Effect.Release();
	}
}
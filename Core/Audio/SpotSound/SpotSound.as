class ASpotSound : AHazeSpotSound
{
	UPROPERTY(EditInstanceOnly, OverrideComponent = SpotSoundComponent)
	USpotSoundComponent OverrideSpotSoundComponent;

	UFUNCTION(BlueprintCallable)
	void PostSpotEvent(UHazeAudioEvent Event)
	{
		if(Event != nullptr && OverrideSpotSoundComponent.Emitter != nullptr)
		{
			OverrideSpotSoundComponent.Emitter.PostEvent(Event);
		}
	}

	UFUNCTION(BlueprintCallable)
	void Start()
	{
		SpotComponent.Start();
	}

	UFUNCTION(BlueprintCallable)
	void Stop()
	{
		SpotComponent.Stop();
	}

	UFUNCTION(BlueprintPure)
	USpotSoundComponent GetSpotComponent() property
	{
		return OverrideSpotSoundComponent;
	}
}
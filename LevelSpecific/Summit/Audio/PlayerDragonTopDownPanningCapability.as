class UPlayerDragonTopDownPanningCapability : UHazePlayerCapability
{
	AHazeActor DragonActor;
	UPlayerTeenDragonComponent DragonComp;	

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<USoundDefBase>> DragonSoundDefs;

	TArray<UHazeAudioEmitter> DragonEmitters;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		DragonActor = Cast<AHazeActor>(DragonComp.DragonMesh.Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DragonComp.bTopDownMode;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !DragonComp.bTopDownMode;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto& SoundDefClass : DragonSoundDefs)
		{
			TArray<UHazeAudioEmitter> SoundDefEmitters;
			USoundDefContextComponent DragonSoundDefComp = USoundDefContextComponent::Get(DragonActor);
			if(DragonSoundDefComp.GetSoundDefEmitters(SoundDefClass, SoundDefEmitters))
				DragonEmitters.Append(SoundDefEmitters);
			else
			{
				USoundDefContextComponent PlayerSoundDefComp = USoundDefContextComponent::Get(Player);
				if(PlayerSoundDefComp.GetSoundDefEmitters(SoundDefClass, SoundDefEmitters))
					DragonEmitters.Append(SoundDefEmitters);
			}
		}

		for(auto& Emitter : DragonEmitters)
		{
			Emitter.SetRTPC(Audio::Rtpc_Spatialization_SpeakerPanning_Mix, 0.0, 0.0);
			Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_FR, 1.0, 0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto& Emitter : DragonEmitters)
		{
			Emitter.SetRTPC(Audio::Rtpc_Spatialization_SpeakerPanning_Mix, 1.0, 0.0);
			Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_FR, 0.0, 0.0);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D _;
		float PanningValue = 0.0;
		float _Y;
		Audio::GetScreenPositionRelativePanningValue(Player.ActorLocation, _, PanningValue, _Y);

		for(auto& Emitter : DragonEmitters)
		{
			Emitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningValue, 0.0);
		}
	}
}
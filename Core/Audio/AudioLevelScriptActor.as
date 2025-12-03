class AAudioLevelScriptActor : AHazeLevelScriptActor
{	
	UPROPERTY()
	UHazeAudioBusMixer StaticMix = nullptr;

	UPROPERTY()
	FSoundDefReference MixingSoundDef;

	UPROPERTY()
	UPlayerDefaultAudioDeathSettings OverrideDeathFilteringSettings = nullptr;

	UPROPERTY(Transient, NotVisible)
	FHazeAudioStaticLevelMix LevelMix;

	UPROPERTY()
	UPlayerDefaultProxyEmitterActivationSettings DefaultProxyActivationSettings;

	UFUNCTION(BlueprintEvent)
	bool ShouldActivateProxyEmitter(UObject SoundDefOwner, FName TagName, float32& InterpolationTime)
	{
		devCheck(false, "When calling RequestAuxProxyEmitters from an audio level you must override ShouldActivateProxyEmitter!");
		return false; 
	}

	UFUNCTION(BlueprintCallable)
	void RequestAuxProxyEmitters(AHazeActor Actor, UHazeAudioAuxBus AuxBus, FName Tag, const int Priority = 1, UHazeAudioAuxBus VOAuxBus = nullptr, UHazeAudioAuxBus ReturnBus = nullptr,
		const float InBusVolume = 0.0, const float AttenuationScaling = 1.0, 
		const float ReverbVolume = 0.0, const float OutpusBusVolume = 0.0, 
		const float InterpolationTime = 0.5, const float SourcePassthroughAlpha = 0, const bool bIncludeVO = true)
	{
		if(!IsValid(Actor) || AuxBus == nullptr)
			return;

		FHazeProxyEmitterRequest ProxyRequest;
		ProxyRequest.OnProxyRequest.BindUFunction(this, n"ShouldActivateProxyEmitter");

		ProxyRequest.Instigator = FInstigator(this, Tag);
		ProxyRequest.Target = Actor;
		ProxyRequest.Priority = Priority;
		ProxyRequest.AuxBus = AuxBus;
		ProxyRequest.ReturnAuxBus = ReturnBus;
		ProxyRequest.InBusVolume = InBusVolume;
		ProxyRequest.AttenuationScaling = AttenuationScaling;
		ProxyRequest.ReverbSendVolume = ReverbVolume;
		ProxyRequest.OutBusVolume = OutpusBusVolume;
		ProxyRequest.InterpolationTime = InterpolationTime;
		ProxyRequest.SourcePassthroughAlpha = SourcePassthroughAlpha;	

		Actor.RequestAuxSendProxy(ProxyRequest);

		// If actor is a player also do the request for the VO-emitter
		// We do it as a seperate request instead of linking so that we can turn it off later
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr && bIncludeVO)
		{
			auto VOEmitter = Audio::GetPlayerVoEmitter(Player);
			ProxyRequest.AuxBus = VOAuxBus != nullptr ? VOAuxBus : AuxBus;
			ProxyRequest.Target = VOEmitter;

			VOEmitter.RequestAuxSendProxy(ProxyRequest);
		}		
	}

	UFUNCTION(BlueprintCallable)
	void RequestAuxProxyVO(AHazePlayerCharacter Player, UHazeAudioAuxBus AuxBus, FName Tag, const int Priority = 1, UHazeAudioAuxBus ReturnBus = nullptr,
			const float InBusVolume = 0.0, const float AttenuationScaling = 1.0, 
			const float ReverbVolume = 0.0, const float OutpusBusVolume = 0.0, 
			const float InterpolationTime = 0.5, const float SourcePassthroughAlpha = 0)
	{
		if(!IsValid(Player) || AuxBus == nullptr)
			return;

		FHazeProxyEmitterRequest ProxyRequest;
		ProxyRequest.OnProxyRequest.BindUFunction(this, n"ShouldActivateProxyEmitter");

		ProxyRequest.Instigator = FInstigator(this, Tag);
		ProxyRequest.Priority = Priority;
		ProxyRequest.AuxBus = AuxBus;
		ProxyRequest.ReturnAuxBus = ReturnBus;
		ProxyRequest.InBusVolume = InBusVolume;
		ProxyRequest.AttenuationScaling = AttenuationScaling;
		ProxyRequest.ReverbSendVolume = ReverbVolume;
		ProxyRequest.OutBusVolume = OutpusBusVolume;
		ProxyRequest.InterpolationTime = InterpolationTime;
		ProxyRequest.SourcePassthroughAlpha = SourcePassthroughAlpha;

		auto VOEmitter = Audio::GetPlayerVoEmitter(Player);
		ProxyRequest.AuxBus = AuxBus;
		ProxyRequest.Target = VOEmitter;

		VOEmitter.RequestAuxSendProxy(ProxyRequest);		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachMixingSoundDef();
		StartMixer();
		SetDefaultProxyActivationSettings();
		SetDeathFilteringSettings();
	}

	const FSoundDefReference& GetMixingSoundDef()
	{
		if (MixingSoundDef.SoundDef.IsValid())
			return MixingSoundDef;

		auto HazeGameInstance = Cast<UHazeGameInstance>(GameInstance);
		return HazeGameInstance.GlobalAudioDataAsset.DefaultMixingSoundDef;
	}

	void AttachMixingSoundDef()
	{
		const auto& NextMixingSoundDef = GetMixingSoundDef();
		if (NextMixingSoundDef.SoundDef.IsValid() == false)
			return;
		
		auto HazeActor = SpawnActor(AHazeActor, Level = GetLevel());
		NextMixingSoundDef.SpawnSoundDefAttached(HazeActor);
	}

	void StartMixer()
	{
		if (StaticMix == nullptr)
			return;

		LevelMix.Start(this, StaticMix, GetLevel());
	}

	void SetDefaultProxyActivationSettings()
	{
		if(DefaultProxyActivationSettings == nullptr)
			return;

		for(auto Player : Game::GetPlayers())
		{
			Player.ApplySettings(DefaultProxyActivationSettings, this, EHazeSettingsPriority::Gameplay);
		}
	}

	void SetDeathFilteringSettings()
	{
		if(OverrideDeathFilteringSettings == nullptr)
			return;

		for(auto Player : Game::GetPlayers())
		{
			Player.ApplySettings(OverrideDeathFilteringSettings, this);
		}
	}
}
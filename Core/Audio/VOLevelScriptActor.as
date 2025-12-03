UCLASS(Abstract, HideCategories = "Actor Tick Replication Rendering Collision Disable Cooking")
class AVOLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	TArray<FSoundDefReference> SoundDefs;

	UPROPERTY()
	EHazeSelectPlayer AttachToPlayer;

	UPROPERTY()
	UVODamageDeathSettings DamageAndDeathSetting;

	private bool bActorsLoaded = false;

	bool AwaitActors(const FSoundDefReference SoundDefRef)
	{
		if (bActorsLoaded)
			return false;

		for (const auto& NameAndActorRef : SoundDefRef.ActorRefs)
		{
			auto ActorRef = NameAndActorRef.GetValue();
			
			if(ActorRef.IsNull())
				continue;

			auto Actor = ActorRef.Get();
			if (Actor == nullptr)
				return true;
			if (!Actor.HasActorBegunPlay())
				return true;
		}

		bActorsLoaded = true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachSoundDefs();

		if (DamageAndDeathSetting != nullptr)
		{
			for (auto Player: Game::Players)
			{
				Player.ApplySettings(DamageAndDeathSetting, this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (DamageAndDeathSetting != nullptr)
		{
			for (auto Player: Game::Players)
			{
				Player.ClearSettingsByInstigator(this);
			}
		}

		if (SoundDefs.Num() == 0)
			return;
		
		auto Players = Game::GetPlayersSelectedBy(AttachToPlayer);

		for (auto Player : Players)
		{
			for (const auto& SoundDefRef : SoundDefs)
			{
				if (!SoundDefRef.IsValid())
					continue;

				SoundDefRef.RemoveFromActor(Player, this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AttachSoundDefs();
	}

	void AttachSoundDefs()
	{
		for (const auto& SoundDefRef : SoundDefs)
		{
			if (!SoundDefRef.IsValid())
				continue;

			if (AwaitActors(SoundDefRef))
				return;
		}

		SetActorTickEnabled(false);

		auto Players = Game::GetPlayersSelectedBy(AttachToPlayer);

		for (auto Player : Players)
		{
			for (auto SoundDef : SoundDefs)
			{
				SoundDef.SpawnSoundDefAttached(Player, InInstigator = this);

				for (auto Pair : SoundDef.ActorRefs)
				{
					AHazeActor LinkedHazeActor = Cast<AHazeActor>(Pair.Value.Get());
					if (LinkedHazeActor != nullptr)
					{
						EffectEvent::LinkActorToReceiveEffectEventsFrom(Player, LinkedHazeActor);
					}
				}
			}
		}
	}

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
		const float InterpolationTime = 0.5, const float SourcePassthroughAlpha = 0)
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
		if(Player != nullptr)
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
}
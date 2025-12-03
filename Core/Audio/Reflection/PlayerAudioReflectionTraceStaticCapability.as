class UPlayerAudioReflectionTraceStaticCapability : UPlayerAudioReflectionTraceCapability
{
	default CapabilityTags.Remove(Audio::Tags::DefaultReflectionTracing);
	default CapabilityTags.Remove(Audio::Tags::LevelSpecificTracingBlocking);
	default CapabilityTags.Add(Audio::Tags::FullscreenReflectionTracing);

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Setup()
	{
		PlayerComponent = Player.PlayerAudioComponent;
		ReverbComponent = PlayerComponent.GetReverbComponent();
		ReflectionComponent = UAudioReflectionComponent::GetOrCreate(Player);
	}

   	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Zone = ReverbComponent.GetPrioritizedReverbZone();
		return Zone != nullptr && Zone.GetStaticReflectionAsset() != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return LastZone == nullptr || LastZone.GetStaticReflectionAsset() == nullptr;
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void OnActivated()
	{
		Player.BlockCapabilities(Audio::Tags::DefaultReflectionTracing, this);
		Player.BlockCapabilities(Audio::Tags::FullscreenReflectionTracing, this);

		LastZone = ReverbComponent.GetPrioritizedReverbZone();
		UpdateSends();
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultReflectionTracing, this);
		Player.UnblockCapabilities(Audio::Tags::FullscreenReflectionTracing, this);
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void TickActive(float DeltaTime)
	{
		auto CurrentZone = ReverbComponent.GetPrioritizedReverbZone();
		
		if (CurrentZone == LastZone)
			return;
		
		LastZone = CurrentZone;
		UpdateSends();
	}

	void UpdateSends()
	{
		auto Zone = LastZone;
		if (Zone.GetStaticReflectionAsset() == nullptr)
			return;

		ReflectionComponent.OnZoneChanged(Zone, Zone.GetReflectionAsset());
	}

}
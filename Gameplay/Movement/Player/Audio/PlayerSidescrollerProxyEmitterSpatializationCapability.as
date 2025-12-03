class UPlayerSidescrollerProxyEmitterSpatializationCapability : UPlayerProxyEmitterSpatializationBaseCapability
{
	default CapabilityTags.Add(Audio::Tags::SidescrollerProxyEmitter);
	default ProxyTag = Audio::Tags::SidescrollerProxyEmitter;
	default InterpolationTime = 1.0;

	// Set on attenuation curve in Wwise
	const float DEFAULT_AUX_BUS_ATTENUATION_DISTANCE = 3000.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		#if TEST
		if(bBypass)
			return false;
		#endif
		
		if(!ProxyActivationSettings.bCanActivate)
			return false;

		if(Player.bIsParticipatingInCutscene)
			return false;

		if (Game::IsInLoadingScreen())
			return false;

		if(Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::SideScroller)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		#if TEST
		if(bBypass)
			return true;
		#endif

		if(Player.bIsParticipatingInCutscene)
			return true;

		if (Game::IsInLoadingScreen())
			return true;

		if(Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::SideScroller)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Player.BlockCapabilities(Audio::Tags::DefaultProxyEmitter, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Player.UnblockCapabilities(Audio::Tags::DefaultProxyEmitter, this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnRequestProxyEmitters(UObject Object, FName EmitterName, float32& outInterpolationTime)
	{
		outInterpolationTime = float32(InterpolationTime);

		if (!IsActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		auto Log = TEMPORAL_LOG(Player, "Audio/AuxProxy");
		Log.Value("Player Default Sidescroller;Crossfade Alpha", InterpAlpha).
		Value("Player Default Sidescroller;Listener Lerp Alpha", ListenerLerpAlpha).
		Value("Player Default Sidescroller;Scaled Attenuation Distance: ", DEFAULT_AUX_BUS_ATTENUATION_DISTANCE * ProxyRequest.AttenuationScaling);		
	}
}
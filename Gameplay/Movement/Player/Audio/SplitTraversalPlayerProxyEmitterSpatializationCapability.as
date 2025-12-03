 class USplitTraversalPlayerProxyEmitterSpatializationCapability : UPlayerDefaultProxyEmitterSpatializationCapability
{
	default CapabilityTags.Remove(Audio::Tags::DefaultProxyEmitter);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificProxyEmitter);

	FVector SplitOffset(500000.0, 0.0, 0.0);

	UPlayerFoliageAudioComponent FoliageComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		FoliageComponent = UPlayerFoliageAudioComponent::GetOrCreate(Player);
	}

	bool InScifi() const
	{
		if (Player.ActorLocation.DistSquared(SplitOffset) < Player.ActorLocation.SizeSquared())
			return true;

		return false;
	}

	FVector GetPlayerViewLocation() const override property
	{
		if (Player.IsZoe() && InScifi())
			return Player.ViewLocation + SplitOffset;

		return Player.ViewLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(Audio::Tags::DefaultProxyEmitter, this);

		if (FoliageComponent != nullptr) 
			FoliageComponent.MakeupGainAlpha = 0;

		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultProxyEmitter, this);

		if (FoliageComponent != nullptr) 
			FoliageComponent.MakeupGainAlpha = 1;

		Super::OnDeactivated();
	}

	private void SetScreenPositionPanning() override
	{
		FVector2D LeftScreenLocation;
		SceneView::ProjectWorldToScreenPosition(Game::Mio, Player.ActorLocation, LeftScreenLocation);
		
		float ScaledPanning = Math::GetMappedRangeValueClamped(FVector2D(0.2, 0.8), FVector2D(-1.0, 1.0), LeftScreenLocation.X);	
		ScaledPanning *= Audio::GetPanningRuleMultiplier();
		AudioComponent::SetGlobalRTPC(LRPanningRTPCID, ScaledPanning, 0);

		auto FoliageVolume = Math::GetMappedRangeValueClamped(FVector2D(-.05, 0), FVector2D(0, 1.0), ScaledPanning);	
		if (FoliageComponent != nullptr)
			FoliageComponent.MakeupGainAlpha = FoliageVolume;

		Player.PlayerAudioComponent.Panning = ScaledPanning;
	}
}
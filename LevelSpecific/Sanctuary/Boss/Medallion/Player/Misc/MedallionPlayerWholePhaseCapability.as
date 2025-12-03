class UMedallionPlayerWholePhaseCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		if (Player.IsMio())
			Player.ActivateCamera(RefsComp.Refs.SplitSidescrollerCameraMio, 0.0, this, EHazeCameraPriority::Medium);
		if (Player.IsZoe())
			Player.ActivateCamera(RefsComp.Refs.SplitSidescrollerCameraZoe, 0.0, this, EHazeCameraPriority::Medium);
		Player.BlockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.BlockCapabilities(DarkPortal::Tags::DarkPortalAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.DeactivateCameraByInstigator(this);
		Player.UnblockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.UnblockCapabilities(DarkPortal::Tags::DarkPortalAim, this);
	}
};
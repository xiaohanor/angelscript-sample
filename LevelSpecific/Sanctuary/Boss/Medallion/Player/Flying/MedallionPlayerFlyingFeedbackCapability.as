class UMedallionPlayerFlyingFeedbackCapability : UHazePlayerCapability
{
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerAssetsComponent AssetsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		AssetsComp = UMedallionPlayerAssetsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!MedallionComp.IsMedallionCoopFlying())
			return false;
			if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MedallionComp.IsMedallionCoopFlying())
			return true;
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpeedEffect::RequestSpeedEffect(Player, 0.2, this, EInstigatePriority::Normal, bUsePlayerMovement = false);
		if (AssetsComp != nullptr && AssetsComp.StartFlyingVFX != nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(AssetsComp.StartFlyingVFX, Player.ActorCenterLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpeedEffect::ClearSpeedEffect(Player, this);
	}
};
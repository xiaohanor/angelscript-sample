class UMedallionPlayerSidescrollerPerspectiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionSidescrollerTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;

	bool bManualActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;

		if (MedallionComp.IsFlyingNotReturning())
			return false;

		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMedallionPlayerSidescrollerDeactivationParams& Params) const
	{
		if (MedallionComp.IsFlyingNotReturning() || RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
		{
			Params.bNatural = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::SideScroller, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionPlayerSidescrollerDeactivationParams Params)
	{
		Player.ClearGameplayPerspectiveMode(this);
	}
};
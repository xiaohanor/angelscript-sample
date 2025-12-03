class UMedallionPlayerMergeHealthOverrideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerReferencesComponent RefsComp;

	UMedallionPlayerAssetsComponent AssetsComp;
	bool bApplied = false;

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
		if (Player.IsPlayerDead())
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge1)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge2)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Merge3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AssetsComp = UMedallionPlayerAssetsComponent::Get(Player);
		if (AssetsComp != nullptr && AssetsComp.MergePhaseHealthSettings != nullptr)
		{
			bApplied = true;
			Player.ApplySettings(AssetsComp.MergePhaseHealthSettings, this, EHazeSettingsPriority::Override);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bApplied)
			Player.ClearSettingsByInstigator(this);
		bApplied = false;
	}
};
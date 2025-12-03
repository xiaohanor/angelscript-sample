class UMedallionPlayerMergePhaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		
		if (!IsInSideScroller())
			return false;
		
		if (Game::Mio.GetHorizontalDistanceTo(Game::Zoe) > MedallionConstants::Merge::MergePhaseDistance)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	bool IsInSideScroller() const
	{
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Sidescroller1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Sidescroller2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::Sidescroller3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		switch (RefsComp.Refs.HydraAttackManager.Phase)
		{
			case EMedallionPhase::Sidescroller1:
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Merge1);
			break;
			case EMedallionPhase::Sidescroller2:
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Merge2);
			break;
			case EMedallionPhase::Sidescroller3:
				RefsComp.Refs.HydraAttackManager.SetPhase(EMedallionPhase::Merge3);
			break;
			default:
				//devCheck(false, "unsupported transition!");
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};
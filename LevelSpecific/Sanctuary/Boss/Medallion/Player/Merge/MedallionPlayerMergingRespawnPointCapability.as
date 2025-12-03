class UMedallionPlayerMergingRespawnPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerReferencesComponent RefsComp;

	UPlayerRespawnComponent RespawnComponent;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		RespawnComponent = UPlayerRespawnComponent::Get(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (!MedallionComp.bHasMergedFocus)
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
		if (!MedallionComp.bHasMergedFocus)
		 	return true;
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
		FOnRespawnOverride Delegate;
		Delegate.BindUFunction(MedallionComp, n"GetMergeRespawnLocation");
		RespawnComponent.ApplyRespawnOverrideDelegate(this, Delegate, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComponent.ClearRespawnOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SanctuaryMedallionHydraDevToggles::Draw::MergeRespawnPoints.IsEnabled())
		{
			FRespawnLocation Unused;
			bool bMeh = MedallionComp.GetMergeRespawnLocation(Player, Unused);
		}
	}

};
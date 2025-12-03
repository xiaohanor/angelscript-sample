class UMedallionPlayerGloryKillDebugHideOtherHydrasCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionGloryKill);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerGloryKillComponent GloryKillComp;
	ASanctuaryBossMedallionHydra SelectedHydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsZoe())
			return false;
		if (RefsComp.Refs == nullptr)
			return false;
		if (GloryKillComp.AttackedHydra == nullptr)
			return false;
		if (!SanctuaryMedallionHydraDevToggles::Hydra::HideOtherHydrasInGloryKill.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SanctuaryMedallionHydraDevToggles::Hydra::HideOtherHydrasInGloryKill.IsEnabled())
			return true;
		if (GloryKillComp.AttackedHydra == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SelectedHydra = GloryKillComp.AttackedHydra;
		{
			for (ASanctuaryBossMedallionHydra RefHydra : RefsComp.Refs.Hydras)
			{
				if (RefHydra == SelectedHydra)
					continue;
				RefHydra.SetActorHiddenInGame(true);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		{
			for (ASanctuaryBossMedallionHydra RefHydra : RefsComp.Refs.Hydras)
			{
				if (RefHydra == SelectedHydra)
					continue;
				RefHydra.SetActorHiddenInGame(false);
			}
		}
	}
};
class USanctuaryBossMedallionHydraStrangleCapability : UHazeCapability
{
	USanctuaryBossMedallionHydraMovePivotComponent MoveHeadPivotComp;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 101;

	ASanctuaryBossMedallionHydra Hydra;
	UMedallionPlayerGloryKillComponent MioGloryKillComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		MioGloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Game::Mio);
		MoveHeadPivotComp = USanctuaryBossMedallionHydraMovePivotComponent::GetOrCreate(Hydra);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Hydra.DecapitatedHead == nullptr)
			return false;
		if (MioGloryKillComp.GloryKillState != EMedallionGloryKillState::EnterSequence)
			return false;
		if (MioGloryKillComp.AttackedHydra != Hydra)
			return false;
		return true;
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MioGloryKillComp.GloryKillState == EMedallionGloryKillState::EnterSequence)
			return false;
		if (MioGloryKillComp.GloryKillState == EMedallionGloryKillState::Strangle)
			return false;
		if (Hydra.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hydra.HeadPivotBlockers.AddUnique(MedallionConstants::Tags::StrangleBlockHeadPivot);
		Hydra.OneshotAnimationThenWait(EFeatureTagMedallionHydra::StrangleStruggle);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()	
	{
		Hydra.AddActorVisualsBlock(MedallionHydraTags::HydraVisibilityDeathBlocker);
	}
};
class USanctuaryBossMedallionHydraBallistaAggroCapability : UHazeCapability
{
	ASanctuaryBossMedallionHydra Hydra;
	UMedallionPlayerReferencesComponent RefsComp;
	USanctuaryBossMedallionHydraAnimComponent AnimationComponent;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	EMedallionPhase EnterPhase;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		AnimationComponent = USanctuaryBossMedallionHydraAnimComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Hydra.bDead)
			return false;
		if (!IsInBallistaAiming())
			return false;
		if (!Hydra.AttackQueue.IsEmpty())
			return false;
		if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::LaserForward)
			return false;
		if (Hydra.LaserActor.bActive)
			return false;
		if (Hydra.bIsBallistaAttacked)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Hydra.bDead)
			return true;
		if (!IsInBallistaAiming())
			return true;
		if (!Hydra.AttackQueue.IsEmpty())
			return true;
		if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::LaserForward)
			return true;
		if (Hydra.bIsBallistaAttacked)
			return true;
		return false;
	}

	bool IsInBallistaAiming() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaPlayersAiming2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaArrowShot1)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaArrowShot2)
			return true;
		if (RefsComp.Refs.HydraAttackManager.Phase == EMedallionPhase::BallistaArrowShot3)
				return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		EnterPhase = RefsComp.Refs.HydraAttackManager.Phase;
		Hydra.AppendAnimation(EFeatureTagMedallionHydra::BallistaAggro, EFeatureSubTagMedallionHydra::Start, true);
		Hydra.AppendAnimation(EFeatureTagMedallionHydra::BallistaAggro, EFeatureSubTagMedallionHydra::Mh, false, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Hydra.bDead)
			return;
		if (Hydra.LaserActor.bActive)
			return;
		if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::LaserForward)
			return;
		if (EnterPhase == RefsComp.Refs.HydraAttackManager.Phase)
			return;
		if (Hydra.bIsBallistaAttacked)
			return;

		if (EnterPhase > RefsComp.Refs.HydraAttackManager.Phase) // canceled, probably players got lasered while trying to ballista
			Hydra.OneshotAnimation(EFeatureTagMedallionHydra::BallistaAggroCanceled, 3);
		else
		{
			Hydra.AppendAnimation(EFeatureTagMedallionHydra::BallistaAggro, EFeatureSubTagMedallionHydra::End, true);
		}
	}
};
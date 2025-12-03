class USanctuaryCompanionAviationEvaluateStopPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UHazeMovementComponent MoveComp;
	ASanctuaryBossArenaHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Owner);
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		if (Hydras.Num() > 0)
			Hydra = Cast<ASanctuaryBossArenaHydra>(Hydras.Single);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;

		if (DeactiveDuration < Network::PingRoundtripSeconds * 2.0) // Don't spam toggle capa in network when hydra is defeated
			return false;

		if (HasKilledLastHydra())
			return true;

		if (IsInAttackCapabilities())
			return false;

		if (!AviationComp.HasDestination())
			return false;

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (!DestinationData.IsValid())
			return true;

		if (DestinationData.HasRuntimeSpline())
		{
			if (AviationComp.bControlIsAtEndOfMovementSpline)
				return true;
		}
		else
		{
			FVector ToDestination = DestinationData.GetLocation() - Player.ActorLocation;
			float DistanceToDestination = ToDestination.Size();
			if (DistanceToDestination < AviationComp.Settings.StopAviationDistance)
				return true;
		}

		return false;
	}

	bool HasKilledLastHydra() const
	{
		if (Hydra == nullptr)
			return false;
		return Hydra.IsDefeated();
	}

	bool IsInAttackCapabilities() const
	{
		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
			return true;

		if (AviationComp.AviationState == EAviationState::TryExitAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (AviationComp.HasDestination())
			AviationComp.RemoveCurrentDestination(true, this);
		if (!AviationComp.HasDestination())
			AviationComp.StopAviation();

		if (HasKilledLastHydra())
			AviationComp.SetAviationState(EAviationState::None);

		AviationComp.ResetEndOfMovementSpline();
	}
};


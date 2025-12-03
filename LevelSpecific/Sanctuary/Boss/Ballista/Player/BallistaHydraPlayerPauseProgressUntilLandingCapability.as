class UBallistaHydraPlayerPauseProgressUntilLandingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerReferencesComponent RefsComp;
	UBallistaHydraActorReferencesComponent BallistaRefsComp;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		BallistaRefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (bActivated)
			return false;
		if (RefsComp.Refs == nullptr)
			return false;
		if (BallistaRefsComp.Refs == nullptr)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase < EMedallionPhase::Ballista1)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::BallistaPlayersAiming3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsOnWalkableGround())
			return false;
		if (Player.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bActivated = true;
		BallistaRefsComp.Refs.Spline.PauseProgressInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallistaRefsComp.Refs.Spline.PauseProgressInstigators.Remove(this);
	}
};
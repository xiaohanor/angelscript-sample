class UPlayerAdultDragonKillOutsideBoundaryCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;
	AAdultDragonBoundarySpline BoundarySpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);
		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.IsPlayerRespawning() || Player.IsPlayerDead())
			return;

		float _;
		if (BoundarySpline.GetIsOutsideBoundary(Player.ActorLocation, _))
		{
			Player.KillPlayer();
		}
	}
};
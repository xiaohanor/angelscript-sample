class USkylineAttackShipCrashPOICapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ASkylineAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineAttackShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AttackShip.bIsCrashing)
			return false;

		if (AttackShip.IsActorDisabled())
			return false;

		if (AttackShip.CrashSpline == nullptr)
			return false;

		if (TListedActors<ASkylineAttackShip>().Num() > 1)
			return false;

		if (!IsPlayersGrounded())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackShip.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazePointOfInterestFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToActor(AttackShip);

		FApplyPointOfInterestSettings POISettings;
		POISettings.Duration = 0.0;
		POISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Slow;

		for (auto Player : Game::Players)
		{
			Player.ApplyPointOfInterest(this, FocusTarget, POISettings, 3.0);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsPlayersGrounded() const
	{
		for (auto Player : Game::Players)
		{
			if (!Player.IsOnWalkableGround())
				return false;
		}

		return true;
	}
}
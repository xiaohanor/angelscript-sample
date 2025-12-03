class USanctuaryBossInsideBoatUserConstrainCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsOnBoat())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsOnBoat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.OverrideResolver(USanctuaryBossInsideBoatConstainMovementResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(USanctuaryBossInsideBoatConstainMovementResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsOnBoat() const
	{
		if (!MoveComp.HasGroundContact())
			return false;

		TListedActors<ASanctuaryBossInsideBoat> Boats;
		for (ASanctuaryBossInsideBoat Boat : Boats)
		{
			if (MoveComp.GroundContact.Actor == Boat)
				return true;
		}

		return false;
	}
};
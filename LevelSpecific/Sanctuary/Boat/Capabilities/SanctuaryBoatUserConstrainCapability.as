class USanctuaryBoatUserConstrainCapability : UHazeCapability
{
	default CapabilityTags.Add(SanctuaryBoatTags::Boat);
	default CapabilityTags.Add(SanctuaryBoatTags::BoatPlayerConstrain);

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
		MoveComp.OverrideResolver(USanctuaryBoatUserConstrainMovementResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(USanctuaryBoatUserConstrainMovementResolver, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsOnBoat() const
	{
		if (!MoveComp.HasGroundContact())
			return false;

		TListedActors<ASanctuaryBoat> Boats;
		for (auto Boat : Boats)
		{
			if (MoveComp.GroundContact.Actor == Boat)
				return true;
		}

		return false;
	}
};
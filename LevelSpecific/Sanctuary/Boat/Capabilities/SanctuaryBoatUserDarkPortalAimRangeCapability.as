class USanctuaryBoatUserDarkPortalAimRangeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UDarkPortalUserComponent DarkPortalUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DarkPortalUserComp = UDarkPortalUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DarkPortalUserComp == nullptr)
			return false;

		if (!IsNearBoat())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DarkPortalUserComp == nullptr)
			return true;

		if (!IsNearBoat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DarkPortalUserComp.bUseBoatAimingRange = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DarkPortalUserComp.bUseBoatAimingRange = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsNearBoat() const
	{
		TListedActors<ASanctuaryBoat> Boats;
		for (auto Boat : Boats)
		{
			if (Owner.GetDistanceTo(Boat) < 2000.0)
				return true;
		}

		return false;
	}
};
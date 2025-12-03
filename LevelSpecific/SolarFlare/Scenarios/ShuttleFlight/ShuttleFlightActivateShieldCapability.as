class UShuttleFlightActivateShieldCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShuttleFlightActivateShieldCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareShuttle Shuttle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Shuttle = TListedActors<ASolarFlareShuttle>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Shuttle.ActivateShield();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Shuttle.DeactivateShield();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}
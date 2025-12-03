class USanctuaryFlightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Flight");
	default DebugCategory = n"Movement";
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlightComp = USanctuaryFlightComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return FlightComp.bFlying;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !FlightComp.bFlying;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"BaseMovement", this);
		FlightComp.OnStartFlying.Broadcast(FlightComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FlightComp.OnStopFlying.Broadcast(FlightComp);
		Player.UnblockCapabilities(n"BaseMovement", this);
	}
}


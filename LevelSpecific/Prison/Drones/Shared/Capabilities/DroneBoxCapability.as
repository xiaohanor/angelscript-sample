class UDroneBoxCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::DroneDashCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::WeaponAim))
			return false;

		if (WasActionStopped(ActionNames::WeaponAim))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Print("BoxFox");
	}

}
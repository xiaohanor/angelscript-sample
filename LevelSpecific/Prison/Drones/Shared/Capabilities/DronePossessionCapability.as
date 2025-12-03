
/**
 * 'Handle' the Drone possession on the player side. 
 * 	Needs to be handled via capability, If want the auto-possession to work. sigh.
 */

 class UDronePossessionCapability : UHazePlayerCapability
 {
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	UDroneComponent DroneComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UDroneComponent::Get(Player);
		check(DroneComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneComp.PossessDrone();
		DroneComp.ApplyOutline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DroneComp.ClearOutline();
		DroneComp.UnpossessDrone();
	}

 }
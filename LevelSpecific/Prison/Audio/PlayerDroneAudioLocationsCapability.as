class UPlayerDroneAudioCapabilityLocationsCapability : UHazePlayerCapability
{
	UDroneComponent DroneComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UDroneComponent::Get(Player);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DroneComp.IsPossessed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DroneComp.IsPossessed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		USphereComponent DroneSphereComp = USphereComponent::Get(Player, n"DroneCollision");
		Audio::OverridePlayerComponentAttach(Player, DroneSphereComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Audio::ResetPlayerComponentAttach(Player);
	}
}
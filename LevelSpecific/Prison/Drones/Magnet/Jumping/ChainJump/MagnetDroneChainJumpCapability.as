class UMagnetDroneChainJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 200;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneChainJumpComponent ChainJumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		ChainJumpComp = UMagnetDroneChainJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DroneComp.Settings.bAllowChainingMagneticSurfacesWhileJumping)
			return false;

		if(!JumpComp.StartedJumpingThisOrLastFrame())
			return false;

		if(!AttachedComp.DetachedThisFrame())
			return false;

		if(!IsActioning(MagnetDrone::MagnetInput))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!JumpComp.IsJumping())
			return true;

		if(!IsActioning(MagnetDrone::MagnetInput))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ChainJumpComp.ApplyChainJump(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ChainJumpComp.ClearChainJump(this);
	}
}
class UMagnetDroneAttachToBoatMeshRotationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(MagnetDroneTags::AttachToBoat);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 90;

	UMagnetDroneAttachToBoatComponent AttachToBoatComp;
	UMagnetDroneComponent DroneComp;

	AHazePlayerCharacter SwarmDrone;

	FQuat RotationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);

		SwarmDrone = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachToBoatComp.IsAttachedToBoat())
			return false;

		if(!AttachToBoatComp.bHasLandedOnBoat)
			return false;

		if(AttachToBoatComp.bIsPerformingRelativeJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachToBoatComp.IsAttachedToBoat())
			return true;

		if(!AttachToBoatComp.bHasLandedOnBoat)
			return true;

		if(AttachToBoatComp.bIsPerformingRelativeJump)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(MagnetDroneTags::MagnetDroneUpdateMeshRotation, this);
		
		RotationOffset = SwarmDrone.ActorTransform.InverseTransformRotation(DroneComp.DroneMesh.ComponentQuat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneUpdateMeshRotation, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat Rotation = SwarmDrone.ActorTransform.TransformRotation(RotationOffset);
		DroneComp.DroneMesh.SetWorldRotation(Rotation);
	}
};
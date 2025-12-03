class UMagnetDroneMeshRotationSocketCapability : UHazePlayerCapability
{
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneMeshRotationSocket);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 110;

	UHazeMovementComponent MoveComp;
	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UPoseableMeshComponent DroneMesh;

	FTransform PreviousSurfaceTransform;

	float LocalPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachedComp.IsAttachedToSocket())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachedComp.IsAttachedToSocket())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneMesh = Cast<UPoseableMeshComponent>(DroneComp.GetDroneMeshComponent());

		PreviousSurfaceTransform = AttachedComp.AttachedData.GetSocketComp().GetWorldTransform();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Rotate together with the magnetic socket
		auto MagneticSocket = AttachedComp.AttachedData.GetSocketComp();

		// If we have a surface component, check the delta transform and apply it as rotation to drone mesh
		if(MagneticSocket != nullptr)
		{
			const FTransform CurrentGroundTransform = MagneticSocket.GetWorldTransform();

			const FQuat RelativeRotation = PreviousSurfaceTransform.InverseTransformRotation(DroneMesh.GetWorldRotation().Quaternion());
			DroneMesh.SetWorldRotation(CurrentGroundTransform.TransformRotation(RelativeRotation));

			PreviousSurfaceTransform = CurrentGroundTransform;
		}
	}
}
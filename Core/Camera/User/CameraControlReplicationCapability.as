
class UCameraControlReplicationCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraReplication);
	default BlockExclusionTags.Add(CameraTags::CameraReplication);

    default DebugCategory = CameraTags::Camera;
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10; // Just after camera control

	UCameraUserComponent User;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
		User.ReplicatedCameraInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		User.ReplicatedCameraInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		User.ReplicatedCameraInstigators.Add(this);
	}
};
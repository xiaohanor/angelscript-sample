
// This updates the entire camera system, including all active cameras. 
// If blocked, camera view will remain static.
class UCameraUpdateCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
   	default DebugCategory = CameraTags::Camera;

	UCameraUserComponent User;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		User.AddComponentTickBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		User.RemoveComponentTickBlocker(this);
	}

}
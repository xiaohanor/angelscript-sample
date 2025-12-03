// While this capability is active camera shakes, anims and post processing modifiers will be applied
class UCameraModifierCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraModifiers);

    default DebugCategory = CameraTags::Camera;

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		UHazeCameraUserComponent User = UHazeCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.BlockModifiers(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		UHazeCameraUserComponent User = UHazeCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.UnblockModifiers(this);
	}

}
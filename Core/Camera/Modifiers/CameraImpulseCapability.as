// While this capability is active camera impulses will be applied. If blocked, any ongoing impulses will blend out rapidly and no new ones will have an effect.
class UCameraImpulseCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraImpulses);

    default DebugCategory = CameraTags::Camera;

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		UHazeCameraUserComponent User = UHazeCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.BlockCameraImpulses(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		UHazeCameraUserComponent User = UHazeCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.UnBlockCameraImpulses(this);
	}
}
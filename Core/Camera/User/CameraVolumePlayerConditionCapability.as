// Camera volume settings will only be pushed when this capability is active
class UCameraVolumePlayerConditionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::CameraVolumePlayerConditionCapability);

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
}
class UAudioGameplayDebugCapabilityBase : UHazeCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return AudioDebug::IsEnabled(EHazeAudioDebugType::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !AudioDebug::IsEnabled(EHazeAudioDebugType::Gameplay);
	}
}
class UIslandJetpackDashFOVIncreaseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UIslandJetpackComponent JetpackComp;
	UIslandJetpackSettings JetpackSettings;
	UCameraSettings CamSettings;

	FHazeAcceleratedFloat AcceleratedFOV;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
		CamSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSince = Time::GetGameTimeSince(JetpackComp.TimeOfDash);
		if(TimeSince > JetpackSettings.DashFOVIncreaseDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Math::IsNearlyZero(AcceleratedFOV.Value))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedFOV.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CamSettings.FOV.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSince = Time::GetGameTimeSince(JetpackComp.TimeOfDash);
		if(TimeSince < JetpackSettings.DashFOVIncreaseDuration)
			AcceleratedFOV.AccelerateTo(JetpackSettings.DashFOVIncreaseAmount, JetpackSettings.DashFOVAccelerationDuration, DeltaTime);
		else
			AcceleratedFOV.AccelerateTo(0.0, JetpackSettings.DashFOVDecelerationDuration, DeltaTime);

		CamSettings.FOV.ApplyAsAdditive(AcceleratedFOV.Value, this, 0.0);
	}
}
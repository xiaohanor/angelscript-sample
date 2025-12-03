class UPlayerAdultDragonCameraLagCapability : UHazePlayerCapability
{
	// Forward-plane lag
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonCamera);
	default CapabilityTags.Add(CapabilityTags::BlockedWhileDead);
	default DebugCategory = n"AdultDragon";
	//default CapabilityTags.Add(n"BlockedWhileDead");

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerAdultDragonComponent DragonComp;
	UCameraUserComponent CameraUser;

	FHazeAcceleratedVector AccLocation;

	const float SpringStiffnessMaxIdealDistance = 18;
	const float SpringDampingMaxIdealDistance = 0.5;

	const float SpringStiffnessMinIdealDistance = 200;
	const float SpringDampingMinIdealDistance = 1.0;

	const float MinIdealDistance = 1500;
	const float MaxIdealDistance = 4000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bCameraShouldLagBehind = false;
		Player.ClearCameraSettingsByInstigator(this);
		CameraUser.CameraSettings.CameraOffset.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccLocation.SnapTo(Player.ActorCenterLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Lerp stiffness and damping based on current ideal distance
		float IdealDistance = CameraUser.CameraSettings.IdealDistance.Value;
		float Alpha = Math::Saturate(Math::NormalizeToRange(IdealDistance, MinIdealDistance, MaxIdealDistance));
		float Stiffness = Math::Lerp(SpringStiffnessMinIdealDistance, SpringStiffnessMaxIdealDistance, Alpha);
		float Damping = Math::Lerp(SpringDampingMinIdealDistance, SpringDampingMaxIdealDistance, Alpha);

		AccLocation.SpringTo(Player.ActorCenterLocation, Stiffness, Damping, DeltaTime);

		FVector Offset = (AccLocation.Value - Player.ActorCenterLocation).VectorPlaneProject(Player.ActorForwardVector);
		Offset.X = 0;

		if (Offset.ContainsNaN())
			return;

		CameraUser.CameraSettings.CameraOffset.ApplyAsAdditive(Offset, this, 0, EHazeCameraPriority::VeryHigh);
	}
}
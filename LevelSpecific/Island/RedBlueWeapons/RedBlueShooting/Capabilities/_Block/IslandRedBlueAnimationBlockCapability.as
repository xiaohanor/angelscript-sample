class UIslandRedBlueAnimationBlockCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerFloorMotionComponent FloorMotionComp;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	ULocomotionFeatureLanding LandingFeature;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		LandingFeature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureLanding);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Time::GetGameTimeSince(FloorMotionComp.LastLandedTime) > 0.7)
			return false;

		float VerticalLandingSpeed = FloorMotionComp.AnimData.VerticalLandingSpeed;
		if (VerticalLandingSpeed < LandingFeature.LandHighThreshold)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GetGameTimeSince(FloorMotionComp.LastLandedTime) > 0.7)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueBlockedWhileInAnimation, this);
		WeaponUserComp.TimeOfUnblockWeaponsFromAnimation.Set(Time::GetGameTimeSeconds());
	}
}
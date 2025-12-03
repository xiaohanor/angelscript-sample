class UAdultDragonFreeFlyingRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonStrafeRespawn);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UAdultDragonStrafeSettings StrafeSettings;
	UAdultDragonFreeFlyingComponent FlyingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
		FlyingComp = UAdultDragonFreeFlyingComponent::Get(Player);
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
	void OnActivated()
	{
		Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter RespawnPlayer, FRespawnLocation& OutLocation)
	{
		auto SplinePosition = FlyingComp.RubberBandSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorCenterLocation);
		SplinePosition.Move(500);

		OutLocation.RespawnPoint = nullptr;
		OutLocation.RespawnTransform = SplinePosition.WorldTransform;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearRespawnPointOverride(this);
	}
};
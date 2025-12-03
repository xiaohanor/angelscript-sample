class UTeenDragonTopDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerTeenDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DragonComp.bTopDownMode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DragonComp.bTopDownMode)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FCameraFrustumBoundarySettings Settings;
		// Settings.MinimumDistanceFromFrustum = 300;
		Settings.ViewWorldSpaceOffset = FVector(0.0, 0.0, 100);
		Boundary::ApplyMovementConstrainToCameraFrustum(Player, Settings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boundary::ClearMovementConstrainToCameraFrustum(Player, this);
	}
};
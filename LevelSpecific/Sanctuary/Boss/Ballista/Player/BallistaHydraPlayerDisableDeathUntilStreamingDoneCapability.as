class UBallistaHydraPlayerDisableDeathFirstFramesCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	bool bFirstTime = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bFirstTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 3.0)
			return true;
		if (Player.IsOnWalkableGround())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bFirstTime = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};
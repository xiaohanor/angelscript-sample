/**
 * When Zoe is in SideScroller mode, and we are not in the SplineLock volume:
 * - Activate spline lock on Zoe
 */
class UHackableGearsSplineLockCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 110; // After SideScroller

	AHackableGearsManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AHackableGearsManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Manager.bSideScrollerActive)
			return false;

		if(!Manager.SplineLockTrigger.IsPlayerInside(Game::Zoe))
			return false;

		if(Manager.TransitionToOperationRotatingArm.bMagnetAttached)
			return false;

		if(Game::Zoe.IsPlayerDead() || Game::Zoe.IsPlayerRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.bSideScrollerActive)
			return true;

		if(!Manager.SplineLockTrigger.IsPlayerInside(Game::Zoe))
			return true;

		if(Manager.TransitionToOperationRotatingArm.bMagnetAttached)
			return true;

		if(Game::Zoe.IsPlayerDead() || Game::Zoe.IsPlayerRespawning())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.bSplineLocked = true;

		FPlayerMovementSplineLockProperties LockProperties;
		LockProperties.LockType = EPlayerSplineLockPlaneType::SplinePlane;
		Game::Zoe.LockPlayerMovementToSpline(Manager.SplineLockSplineActor, this, EInstigatePriority::Normal, LockProperties);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.bSplineLocked = false;

		Game::Zoe.UnlockPlayerMovementFromSpline(this);
	}
};
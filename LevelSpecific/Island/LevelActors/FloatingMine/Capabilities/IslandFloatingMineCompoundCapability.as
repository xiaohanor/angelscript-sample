class UIslandFloatingMineCompoundCapability : UHazeCompoundCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
			// Explode
			.Try(n"IslandFloatingMineExplodeCapability")
			// Fall
			.Try(n"IslandFloatingMineFallCapability")
			// Follow
			.Try(n"IslandFloatingMinePlayerFollowCapability")
			// Patrol
			.Try(n"IslandFloatingMinePatrolCapability");
		;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
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
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}
}
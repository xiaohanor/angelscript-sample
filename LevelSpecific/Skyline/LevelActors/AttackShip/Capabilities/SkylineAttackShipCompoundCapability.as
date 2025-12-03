class USkylineAttackShipCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			// States
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundRunAll()
					.Add(USkylineAttackShipCrashCapability())
				)
				.Try(UHazeCompoundRunAll()
					.Add(USkylineAttackShipSplineFollowCapability())
					.Add(USkylineAttackShipProjectileLaunchCapability())
				)
			)
			.Add(USkylineAttackShipMoveToCapability())
			.Add(USkylineAttackShipMovementCapability())
			.Add(USkylineAttackShipCrashPOICapability())
		;
	}
}
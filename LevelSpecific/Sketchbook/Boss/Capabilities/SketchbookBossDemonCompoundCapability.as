class USketchbookBossDemonCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	ASketchbookBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASketchbookBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSelector()
				.Try(USketchbookBossDeadCapability())
				.Try(USketchbookBossIdleCapability())
				.Try(USketchbookBossEnterArenaCapability())
				.Try(USketchbookBossCrushTextCapability())
				.Try(USketchbookBossTrajectoryJumpCapability())
				.Try(USketchbookBossJumpToEdgeCapability())
				.Try(USketchbookBossFlyToCornerCapability())
				.Try(USketchbookBossDiagonalProjectileCapability())
			)
		;
	}
}

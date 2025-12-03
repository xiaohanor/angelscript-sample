class UPrisonBossCompoundCapability : UHazeCompoundCapability
{
	default CapabilityTags.Add(n"PrisonBossCompound");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSelector()
				.Try(UPrisonBossStunnedCapability())
				.Try(UPrisonBossPlayerDeadCapability())
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossGrabPlayerEnterCapability())
					.Then(UPrisonBossGrabPlayerChokeCapability())
					.Then(UPrisonBossGrabPlayerExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossSpiralEnterCapability())
					.Then(UPrisonBossSpiralAttackCapability())
					.Then(UPrisonBossSpiralExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossWaveSlashEnterCapability())
					.Then(UPrisonBossWaveSlashAttackCapability())
					.Then(UPrisonBossWaveSlashExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossCloneEnterCapability())
					.Then(UPrisonBossCloneDuplicateCapability())
					.Then(UPrisonBossCloneAttackCapability())
					.Then(UPrisonBossCloneExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossGroundTrailEnterCapability())
					.Then(UPrisonBossGroundTrailAttackCapability())
					.Then(UPrisonBossGroundTrailExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossHackableMagneticProjectileEnterCapability())
					.Then(UPrisonBossHackableMagneticProjectileThrowCapability())
					.Then(UPrisonBossHackableMagneticProjectileHitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossDashSlashEnterCapability())
					.Then(UPrisonBossDashSlashAttackCapability())
					.Then(UPrisonBossDashSlashExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossHorizontalSlashEnterCapability())
					.Then(UPrisonBossHorizontalSlashAttackCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossZigZagEnterCapability())
					.Then(UPrisonBossZigZagAttackCapability())
					.Then(UPrisonBossZigZagExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossMagneticSlamValidationCapability())
					.Then(UPrisonBossMagneticSlamEnterCapability())
					.Then(UPrisonBossMagneticSlamAttackCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossScissorsEnterCapability())
					.Then(UPrisonBossScissorsAttackCapability())
					.Then(UPrisonBossScissorsExitCapability())
				)
				.Try(UHazeCompoundSequence()
					.Then(UPrisonBossPlatformDangerZoneCapability())
				)
				.Try(UPrisonBossIdleCapability())
			)
			;
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
		ResetCompoundNodes();
	}
}
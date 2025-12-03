struct FSkylineBallBossSmallBossJumpData
{
	bool bCanJump = false;
}

class USkylineBallBossSmallBossJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	ASkylineBallBossSmallBoss SmallBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossJumpData& Params) const
	{
		if (!SmallBoss.bDoJump)
			return false;

		Params.bCanJump = CanJump();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossJumpData Params)
	{
		SmallBoss.bDoJump = false;
		if (Params.bCanJump)
		{
			SmallBoss.RollSpeedTimeLike.Reverse();
			SmallBoss.JumpTimeLike.PlayFromStart();
			USkylineSmallBossMiscVOEventHandler::Trigger_SmallBossJump(SmallBoss);
		}
	}

	bool CanJump() const
	{
		if (!SmallBoss.bActive)
			return false;

		if (SmallBoss.JumpTimeLike.IsPlaying())
			return false;

		if (SmallBoss.bLaserActive)
			return false;

		if (SmallBoss.bWeak)
			return false;

		return true;
	}
};
struct FSkylineBallBossSmallBossActionNodeJumpCapabilityData
{
}

class USkylineBallBossSmallBossActionNodeJumpCapability : UHazeCapability
{
	FSkylineBallBossSmallBossActionNodeJumpCapabilityData Params;
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	USkylineBallBossSmallBossJumpActionComponent BossComp;
	ASkylineBallBossSmallBoss SmallBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossJumpActionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossActionNodeJumpCapabilityData& ActivationParams) const
	{
		if (BossComp.Queue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossActionNodeJumpCapabilityData ActivationParams)
	{
		SmallBoss.bDoJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}

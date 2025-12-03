struct FSkylineBallBossSmallBossActionNodeProjectileData
{
	EHazeSelectPlayer SelectedPlayer;
	AHazePlayerCharacter TargetPlayer;
}

class USkylineBallBossSmallBossActionNodeProjectileCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);

	ASkylineBallBossSmallBoss SmallBoss;
	USkylineBallBossSmallBossProjectileActionComponent BossComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossProjectileActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossActionNodeProjectileData& ActivationParams) const
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
	void OnActivated(FSkylineBallBossSmallBossActionNodeProjectileData ActivationParams)
	{
		SmallBoss.ProjectileTargetPlayer = ActivationParams.TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}

}

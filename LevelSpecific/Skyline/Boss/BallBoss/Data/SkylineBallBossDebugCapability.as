class USkylineBallBossDebugCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	USkylineBallBossActionsComponent BossComp;
	ASkylineBallBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);

		SkylineBallBossDevToggles::BallBossCategory.MakeVisible();
	}
};




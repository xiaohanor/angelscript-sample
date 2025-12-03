UCLASS(Abstract)
class USkylineBallBossChildCapability : UHazeChildCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	
	ASkylineBallBoss BallBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}
}
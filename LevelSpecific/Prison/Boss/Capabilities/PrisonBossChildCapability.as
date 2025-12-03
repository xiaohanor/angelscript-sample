class UPrisonBossChildCapability : UHazeChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	APrisonBoss Boss;
	UPrisonBossAttackDataComponent AttackDataComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
		AttackDataComp = Boss.AttackDataComp;
	}
}
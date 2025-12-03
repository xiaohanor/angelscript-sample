namespace ChallengeMode
{

enum EBossRushActiveMode
{
	RegularGameplay,
	BossRushActive,
}

UFUNCTION(BlueprintCallable, Category = "Challenge Mode", Meta = (ExpandEnumAsExecs = "OutActiveMode"))
void BossRushCompleteCurrentBoss(EBossRushActiveMode&out OutActiveMode)
{
	OutActiveMode = EBossRushActiveMode::RegularGameplay;
}

}
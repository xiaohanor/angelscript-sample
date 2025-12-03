class USkylineGeckoTeam : UHazeTeam
{
	float LastGeckoBladeHitTime = -BIG_NUMBER;
	TPerPlayer<int> NumSequencePounce;
	float LastAttackTime = -BIG_NUMBER;
	float LastMemberJoinedTime = -BIG_NUMBER;
	AActor LastThrownAtTarget = nullptr;
	
	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		Super::OnMemberJoined(Member);
		LastMemberJoinedTime = Time::GameTimeSeconds;
	}
}

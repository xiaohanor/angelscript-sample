
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_MeltdownBossPhaseTwoHomingBall_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SpawnHomingBall(FMeltdownBossPhaseTwoHomingBallSpawnParams Params){}

	UFUNCTION(BlueprintEvent)
	void StartUnSpawnHomingBall(FMeltdownBossPhaseTwoHomingBallSpawnParams Params){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseTwo Rader;
	AMeltdownBossPhaseTwoBarrageAttack BarrageAttack;
	TArray<AMeltdownBossPhaseTwoHomingBall> HomingBalls;
	TArray<FAkSoundPosition> HomingBallsSoundPositions;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BarrageAttack = Cast<AMeltdownBossPhaseTwoBarrageAttack>(HazeOwner);
		Rader = TListedActors<AMeltdownBossPhaseTwo>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Rader.bIsSummoningSharks;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Rader.bIsSummoningSharks == false && HomingBalls.IsEmpty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(BarrageAttack.GetActiveHomingBalls(HomingBalls))
		{
			const int NumHomingBalls = HomingBalls.Num();
			HomingBallsSoundPositions.Empty();
			HomingBallsSoundPositions.SetNum(NumHomingBalls);

			for(int i = 0; i < NumHomingBalls; ++i)
			{
				HomingBallsSoundPositions[i].SetPosition(HomingBalls[i].ActorLocation);
			}

			DefaultEmitter.SetMultiplePositions(HomingBallsSoundPositions);
		}
	}
}
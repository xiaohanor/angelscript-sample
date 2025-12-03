struct FLocomotionFeatureSkydiveHydraBossAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData MhVar2;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlayRndSequenceData RndMh;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData EnterSmash;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData TelegraphSmash;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData Smash;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData ReturnSmash;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData EnterFireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData TelegraphFireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData FireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData ReturnFireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData Interaction;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData Roar;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData RoarStart;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData RoarMh;

	UPROPERTY(BlueprintReadOnly, Category = "OldPhase")
	FHazePlaySequenceData RoarStop;
}

struct FLocomotionFeatureHydraBossArenaAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
	FHazePlaySequenceData ProjectileAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
	FHazePlaySequenceData WaveAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
	FHazePlaySequenceData RainAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackLunge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackBite;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackRetreat;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ToAttack")
	FHazePlaySequenceData ToAttackProjectile;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData IncomingStrangleStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData IncomingStrangleMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
    FHazePlaySequenceData StrangleStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData FriendStrangleStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData StrangleMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlayBlendSpaceData StrangleBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData FriendStrangleMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData StrangleHurt;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData FriendStrangleHurt;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData FreeStrangle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData FriendDeath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData Submerge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData Emerge;
}

class ULocomotionFeatureHydraBoss : UHazeLocomotionFeatureBase
{
	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHydraBossArenaAnimData ArenaAnimData;

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkydiveHydraBossAnimData SkydiveAnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

struct FLocomotionFeatureBallBossPortalAnimData
{
	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData EnterBallBoss;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData AttackMh1;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData Attack1;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData AttackMh2;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData Attack2;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData AttackMh3;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData Attack3;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData AttackMh4;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData Attack4;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData AttackMh5;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData Attack5;

	UPROPERTY(Category = "BallBossPortal")
	FHazePlaySequenceData FreakOut;
}

class ULocomotionFeatureBallBossPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"BallBossPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBallBossPortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

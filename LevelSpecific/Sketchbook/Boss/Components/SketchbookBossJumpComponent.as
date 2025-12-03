class USketchbookBossJumpComponent : UActorComponent
{
	FVector LandingLocation;

	int JumpsInRow;

	const int JumpsToDo = 2;

	const float JumpingYaw = 50;

	UPROPERTY(EditDefaultsOnly)
	const float JumpSpeed = 300;

	UPROPERTY(EditDefaultsOnly)
	const float FallSpeed = 300;

	UPROPERTY(EditDefaultsOnly)
	const float JumpHeight = 500;

	UPROPERTY(EditDefaultsOnly)
	const float WaitAfterJumpDuration = 1.5;
};
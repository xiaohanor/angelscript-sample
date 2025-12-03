class USanctuaryBabyWormSettings : UHazeComposableSettings
{
	// Flee when player is within this range
	UPROPERTY(Category = "Flee")
	float FleeRange = 900.0;

	UPROPERTY(Category = "Flee")
	float FleeMoveSpeed = 800.0;

	// How long the worm stays grabbed while in single grab
	UPROPERTY(Category = "Grabbed")
	float GrabbedSingleDuration = 3.0;
}

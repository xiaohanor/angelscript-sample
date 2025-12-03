class USkylineDroneBossSettings : UHazeComposableSettings
{
	// Time before we can enter a new phase after the previous one has ended.
	UPROPERTY(EditDefaultsOnly, Category = "Drone")
	float PhaseInterval = 4.0;
}
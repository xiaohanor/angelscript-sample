class UPrisonSwarmMovementSettings : UHazeComposableSettings
{
	// How fast player will accelerate to max speed
	UPROPERTY(Category = "Swarm Drone | Grounded")
	float AccelerationInterpSpeed = 5.0;

	// How much the bots cluster together
	UPROPERTY(Category = "Swarm Bots | Grounded")
	float StickTogetherMultiplier = 5.0;
}
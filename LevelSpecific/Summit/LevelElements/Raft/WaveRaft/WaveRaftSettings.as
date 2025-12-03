class UWaveRaftSettings : UHazeComposableSettings
{
	/** How fast the raft goes */
	UPROPERTY(Category = "Speed")
	float RaftForwardTargetSpeed = 2500.0;

	/** How long it takes for the raft to reach the target speed */
	UPROPERTY(Category = "Speed")
	float RaftForwardAccelerationDuration = 0.5;

	UPROPERTY(Category = "Buoyancy")
	float BuoyancyPerUnitUnderwater = 1.0;

	/** How long it takes to accelerate to the turn speed */
	UPROPERTY(Category = "Paddle Breaking")
	float WaveRaftTurnDuration = 1;

	/** How long it takes to slow down to 0 turn speed */
	UPROPERTY(Category = "Paddle Breaking")
	float WaveRaftTurnBrakeDuration = 2;

	UPROPERTY(Category = "Paddle Breaking")
	float YawPerPaddle = 4;

	UPROPERTY(Category = "Paddle Breaking")
	float MaxYawFromSpline = 50.0;

	/** How frequent the raft rocks from side to side */
	UPROPERTY(Category = "Bobbing")
	float RockFrequency = 5.17 * 1.2;

	/** How much the raft rocks as a maximum */
	UPROPERTY(Category = "Bobbing")
	float RockMagnitude = 1.0;

	/** How frequent the raft bobs up and down */
	UPROPERTY(Category = "Bobbing")
	float UpwardsBobbingFrequency = 5.15 * 1.2;

	/** How much the raft bobs up and down as a maximum */
	UPROPERTY(Category = "Bobbing")
	float UpwardsBobbingMagnitude = 10.0;

	UPROPERTY(Category = "Stagger")
	float StaggerSpeedThreshold = 200.0;

	UPROPERTY(Category = "Stagger")
	float StaggerSpeedBigHitThreshold = 500.0;

	UPROPERTY(Category = "Stagger")
	float StaggerMinDuration = 0.2;

	UPROPERTY(Category = "WaveRaft")
	float DefaultNoPaddleRotateBackInterpSpeed = 5.0;

	UPROPERTY(Category = "AutoSteering")
	bool bUseAutoSteering = false;

	UPROPERTY(Category = "AutoSteering")
	bool bForceAirborne = false;

	/** When auto steering, how long it takes for the raft rotation to accelerate towards the spline */
	UPROPERTY(Category = "AutoSteering")
	float AutoSteeringDuration = 1;

	UPROPERTY(Category = "WaveRaft")
	float GravityForce = 1800;
}
class UPaddleRaftSettings : UHazeComposableSettings
{
	// How long it takes to paddle
	UPROPERTY(Category = "Paddling")
	float PaddleTime = 1.2;

	// How long it takes to switch paddle side
	UPROPERTY(Category = "Paddling")
	float PaddleSwitchTime = 0.6;

	// How much rotation speed we get when players aren't paddling on opposite sides [DEG/s]
	UPROPERTY(Category = "Paddling")
	float PlayerPaddleRotationSpeed = 30;

	// Bonus rotation speed when both players are paddling on same side [DEG/s]
	UPROPERTY(Category = "Paddling")
	float SameSideBonusRotationSpeed = 20;

	// How much forward speed we get when a player paddles [cm/s]
	UPROPERTY(Category = "Paddling")
	float ForwardSpeedAccelerationPerPlayer = 50;

	// Bonus forward acceleration when players are paddling on opposite sides [cm/s]
	UPROPERTY(Category = "Paddling")
	float OppositeSideBonusAcceleration = 40;

	UPROPERTY(Category = "Paddling")
	float RaftMaxRotationSpeed = 30;

	UPROPERTY(Category = "Speed")
	float ForwardDeceleration = 0.2;

	UPROPERTY(Category = "Speed")
	float SidewaysDeceleration = 4.0;

	UPROPERTY(Category = "Speed")
	float MaxRaftSpeed = 500.0;

	UPROPERTY(Category = "Rotation")
	float RaftRotationSlowdownSpeed = 8;

	//Acceleration in splineforward
	UPROPERTY(Category = "Water Current")
	float RapidsAcceleration = 0;

	UPROPERTY(Category = "Water Current")
	float RapidsRotationAlignmentMaxSpeed = 0;

	UPROPERTY(Category = "Water Current")
	float RapidsReAlignmentAlphaOffset = 0.0;

	UPROPERTY(Category = "Buoyancy")
	float BuoyancyPerUnitUnderwater = 1.0;

	UPROPERTY(Category = "Stagger")
	float StaggerSpeedThreshold = 200.0;

	UPROPERTY(Category = "Stagger")
	float StaggerSpeedBigHitThreshold = 400.0;

	UPROPERTY(Category = "Stagger")
	float StaggerFrontAlignmentThreshold = 0.8;

	UPROPERTY(Category = "Stagger")
	float StaggerMinDuration = 0.5;

	UPROPERTY(Category = "Stagger")
	float StaggerMaxDuration = 1.0;
}
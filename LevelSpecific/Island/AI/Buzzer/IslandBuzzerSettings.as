class UIslandBuzzerSettings : UHazeComposableSettings
{
	// Cost of laser attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost LaserGentlemanCost = EGentlemanCost::XSmall;

	// At what range does the laser behaviour activate
	UPROPERTY(Category = "Laser")
	float LaserRange = 1500.0;

	// This is how far two try shooting with the laser, when we are within LaserRange
	UPROPERTY(Category = "Laser")
	float LaserTraceDistance = 1800.0;

	UPROPERTY(Category = "Laser")
	float LaserDamageInterval = 0.1;

	UPROPERTY(Category = "Laser")
	float LaserPlayerDamagePerSecond = 0.35;

	UPROPERTY(Category = "Laser")
	float LaserValidAngle = 45;

	UPROPERTY(Category = "Laser")
	float LaserFollowSpeed = 400;

	UPROPERTY(Category = "Laser")
	float LaserDuration = 2;

	UPROPERTY(Category = "WalkerRepulsion")
	float WalkerRepulsionForce = 200;

	UPROPERTY(Category = "WalkerRepulsion")
	float WalkerRepulsionLength = 450;

	UPROPERTY(Category = "WalkerRepulsion")
	float WalkerRepulsionMaxRange = 600;

	UPROPERTY(Category = "WalkerRepulsion")
	float WalkerRepulsionMinRange = 350;

	UPROPERTY(Category = "Wobble")
	float WobbleAmplitude = 50.0;

	UPROPERTY(Category = "Wobble")
	float WobbleFrequency = 0.5;

	UPROPERTY(Category = "CombatMove")
	float CombatMoveSpeed = 1800;

	UPROPERTY(Category = "CombatMove")
	float CombatMoveHeight = 200;

	// At this distance from any player we use avoid height
	UPROPERTY(Category = "CombatMove")
	float CombatMoveAvoidDistance = 700;

	UPROPERTY(Category = "CombatMove")
	float CombatMoveAvoidHeight = 300;

	UPROPERTY(Category = "CombatMove")
	float CombatMoveUnderneathHeight = 150;

	// Try to stay at least at this distance from the target
	UPROPERTY(Category = "CombatMove")
	float CombatMoveMinDistance = 1000;

	// Max distance we fly away from walker if Walker is in turtling mode
	UPROPERTY(Category = "Turtling")
	float WalkerMaxDistance = 1500;

	UPROPERTY(Category = "Damage")
	float RedBlueDamage = 0.2;

	UPROPERTY(Category = "Chase")
	float ChaseHeight = 300.0;

	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 800.0;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 1000.0;
}
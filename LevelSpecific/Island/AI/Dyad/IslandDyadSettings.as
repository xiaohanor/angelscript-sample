class UIslandDyadSettings : UHazeComposableSettings
{
	// Cost of laser attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost LaserGentlemanCost = EGentlemanCost::XSmall;

	// At what range does the laser behaviour activate between two Dyads
	UPROPERTY(Category = "Laser")
	float LaserRange = 1500.0;

	UPROPERTY(Category = "Laser")
	float LaserDamageInterval = 0.1;

	UPROPERTY(Category = "Laser")
	float LaserPlayerDamagePerSecond = 0.25;

	// Max distance we fly away from walker if Walker is in turtling mode
	UPROPERTY(Category = "Turtling")
	float WalkerMaxDistance = 1500;

	UPROPERTY(Category = "Damage")
	float ForceFieldRedBlueDamage = 0.2;

	UPROPERTY(Category = "ForceField")
	float ForceFieldReplenishAmountPerSecond = 0.1;
}

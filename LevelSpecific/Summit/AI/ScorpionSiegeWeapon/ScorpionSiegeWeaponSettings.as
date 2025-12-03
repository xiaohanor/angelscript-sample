class UScorpionSiegeWeaponSettings : UHazeComposableSettings
{
	// Target must be within this angle in front for attacks to be performed
	UPROPERTY(Category = "Attack|Angle")
	float ValidAttackAngle = 5.0;

	// Gentleman cost of weapon attacks
	UPROPERTY(Category = "Attack|Cost")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Attack|Cooldown")
	float AttackTokenCooldown = 2.0;

	// How long should it take to turn towards target?
	UPROPERTY(Category = "Move|Turn")
	float TurnDuration = 3.0;

	// How long should it take to repair (for one operator)?
	UPROPERTY(Category = "Repair")
	float RepairDuration = 10.0;
}

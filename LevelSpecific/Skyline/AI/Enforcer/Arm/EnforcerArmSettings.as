class UEnforcerArmSettings : UHazeComposableSettings
{
	// How long should it take from start to impact to attack (does not include recovery)
	UPROPERTY()
	float AttackDuration = 0.1;

	// Stun the attacked target for this long
	UPROPERTY()
	float AttackTargetStunDuration = 1.0;

	// Look for targets within this range
	UPROPERTY()
	float TargetDetectionRange = 600.0;

	// Deal this much damage to the player
	UPROPERTY()
	float PlayerAttackDamage = 0.1;

	// Push back the target with this much power
	UPROPERTY()
	float AttackPushbackPower = 2000.0;

	// Take this long for the arm to return to its default position after an action
	UPROPERTY()
	float ReturnDuration = 0.5;
}
class UEnforcerGrenadeSettings : UHazeComposableSettings
{
	// Never throw grenades until combat has been active for a while
	UPROPERTY(Category = "Grenade")
	float InitialPause = 5.0;

	// Minimum interval between any grenades being thrown in the game
	UPROPERTY(Category = "Grenade")
	float GlobalMinInterval = 5.0;

	UPROPERTY(Category = "Grenade")
	float MinRange = 600.0;

	UPROPERTY(Category = "Grenade")
	float MaxRange = 2000.0;

	// Only throw grenades at players who stay within this radius for more than PlayerNotMovingDuration seconds
	UPROPERTY(Category = "Grenade")
	float PlayerNotMovingRadius = 400.0;

	// Only throw grenades at players who stay within PlayerNotMovingRadius for more than this many seconds
	UPROPERTY(Category = "Grenade")
	float PlayerNotMovingDuration = 1.0;

	UPROPERTY(Category = "Grenade")
	EGentlemanCost GentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Grenade")
	float TelegraphDuration = 0.0; // 0.0 is animation duration

	UPROPERTY(Category = "Grenade")
	float AnticipationDuration = 0.0; // 0.0 is animation duration

	UPROPERTY(Category = "Grenade")
	float ActionDuration = 0.0; // 0.0 is animation duration

	UPROPERTY(Category = "Grenade")
	float RecoveryDuration = 0.0; // 0.0 is animation duration

	UPROPERTY(Category = "Grenade")
	float Damage = 1.0;

	UPROPERTY(Category = "Grenade")
	float AIDamage = 1.0;

	UPROPERTY(Category = "Grenade")
	float BlastRadius = 450.0;

	UPROPERTY(Category = "Grenade")
	float ThrowSpeed = 1000.0;

	UPROPERTY(Category = "Grenade")
	float TargetPredictionDuration = 0.0; // Skip until we trace 

	UPROPERTY(Category = "Grenade")
	float Gravity = 982.0 * 3.0;

	UPROPERTY(Category = "Grenade")
	float LandedFuseTime = 2.75;

	UPROPERTY(Category = "Grenade")
	float MaxDuration = 10.0;

	UPROPERTY(Category = "Grenade")
	float PostExplosionRemainDuration = 2.0; // So effects stuff can stay attached and active for a while e.g.
}

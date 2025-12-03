namespace ArenaHydraTags
{
	const FName ArenaHydra = n"ArenaHydra";
	const FName SplineRunHydra = n"SplineRunHydra";
	const FName Rotation = n"Rotation";
	const FName Action = n"Action";

	const FName HydraProjectile = n"HydraProjectile";
	const FName HydraRain = n"HydraRain";
	const FName HydraWave = n"HydraWave";

	const FName ExtraHydraLook = n"ExtraHydraLook";
};

enum EArenaHydraDeadType
{
	Alive,
	Decapitated,
	Disabled
}
class UArenaHydraSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "General")
	EArenaHydraDeadType DeathType = EArenaHydraDeadType::Decapitated;
	UPROPERTY(Category = "General")
	float DeathAnimationDuration = 3.0;

	UPROPERTY(Category = "General")
	float HeadPivotInterpolationDuration = 3.0;
	UPROPERTY(Category = "General")
	float FreeStrangleDuration = 3.0;
	UPROPERTY(Category = "General")
	float SurfaceDuration = 4.0;
	UPROPERTY(Category = "General")
	float EmergeAfterDeathDuration = 3.0;

	UPROPERTY(Category = "ToAttack")
	float ApproachDuration = 0.0;
	UPROPERTY(Category = "ToAttack")
	float RetractDuration = 1.5;
	UPROPERTY(Category = "ToAttack")
	float ToAttackHydraInFrontOfPlayerDistance = 0.0;
	UPROPERTY(Category = "ToAttack")
	float ToAttackHydraSidewaysOfPlayerDistance = 0.0;
	UPROPERTY(Category = "General")
	float ToAttackAvoidPlayerDistance = 5000.0;


	UPROPERTY(Category = "RainAttack")
	float RainProjectileAnticipationDuration = 2.3;
	UPROPERTY(Category = "RainAttack")
	float RainDelay = 4.0;
	UPROPERTY(Category = "RainAttack")
	float RainRecoverDuration = 6.0;

	// Bite
	UPROPERTY(Category = "ToAttack Bite")
	float BiteTriggerDistanceToPlayer = 6000.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteHurtDistanceToPlayer = 1.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteCooldown = 2.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteInFrontOfPlayerDistance = 2000.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteHorizontalOffset = 500.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteVerticalOffset = 500.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteArcHeight = 0.0;

	UPROPERTY(Category = "ToAttack Bite")
	float BiteLungeDuration = 2.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteDownDuration = 0.5;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteRetractDuration = 3.0;

	UPROPERTY(Category = "ToAttack Bite")
	float BiteDelayLeftHead = 0.0;
	UPROPERTY(Category = "ToAttack Bite")
	float BiteDelayRightHead = 1.0;

	// Normal / Arena Projectile
	UPROPERTY(Category = "Arena Projectile")
	float ArenaProjectileAnticipationDuration = 0.4;
	UPROPERTY(Category = "Arena Projectile")
	float ArenaProjectileAttackDuration = 2.5;

	UPROPERTY(Category = "ToAttack AnticipateSequence")
	float AnticipateSequenceTriggerDistanceToPlayer = 5000.0; // Maybe modify the ProjectileStopShootNearPlayerDistance too

	// ToAttack Projectile
	UPROPERTY(Category = "Projectile")
	bool bShootTwiceIfAlone = true;
	UPROPERTY(Category = "Projectile")
	float ProjectileStopShootNearPlayerDistance = 5000;

	UPROPERTY(Category = "Projectile")
	float ProjectileAnimationAnticipationDuration = 0.5;
	UPROPERTY(Category = "Projectile")
	float ProjectileAnimationDuration = 0.5;

	UPROPERTY(Category = "Projectile")
	float ProjectileTargetSpotSecondsInFrontOfPlayer = 1.0;
	UPROPERTY(Category = "Projectile")
	float ProjectileInterval = 3.5;
	UPROPERTY(Category = "Projectile")
	float LeftHeadProjectileDelay = 3.5;
	UPROPERTY(Category = "Projectile")
	float RightHeadProjectileDelay = 3.5 + ProjectileInterval * 0.5;

	// The anticlimax phase is when you've defeated the hydra, it dives down and then re-emerges with more heads
	UPROPERTY(Category = "AntiClimax Phase")
	float DelayAfterDeathToAntiClimax = 4.0;
	UPROPERTY(Category = "AntiClimax Phase")
	float DelayAfterAntiClimaxToSkydive = 8.0;

	UPROPERTY(Category = "AntiClimax Phase")
	float HydraEmergeRadiusOffset = 3000.0;

	UPROPERTY(Category = "AntiClimax Phase")
	float BubblingWaterVFXCooldown = 0.1;
	UPROPERTY(Category = "AntiClimax Phase")
	float BubblingWaterVFXAreaSpread = 5000;
};

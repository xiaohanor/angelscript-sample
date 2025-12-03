struct FPrisonBossAnimationData
{
	bool bIsIdling = false;

	bool bIsStunned = false;
	bool bIsAirborneStunned = false;

	bool bIsEnteringSpiral = false;
	bool bIsSpiralling = false;
	bool bIsExitingSpiral = false;

	bool bIsEnteringWaveSlash = false;
	bool bIsWaveSlashing = false;
	bool bIsExitingWaveSlash = false;

	bool bIsEnteringClone = false;
	bool bIsDuplicatingClone = false;
	bool bClonesAttacking = false;
	bool bIsTelegraphingClone = false;
	bool bIsAttackingClone = false;
	bool bIsExitingClone = false;

	bool bIsEnteringGroundTrail = false;
	bool bIsGroundTrailing = false;
	bool bIsExitingGroundTrail = false;

	bool bIsEnteringHackableMagneticProjectile = false;
	bool bIsSpawningHackableMagneticProjectile = false;
	bool bIsLaunchingHackableMagneticProjectile = false;
	bool bHackableMagneticProjectileHitReaction = false;

	bool bIsEnteringDashSlash = false;
	bool bIsDashSlashAttacking = false;
	bool bIsDashSlashTelegraphing = false;
	bool bDashSlashReachedEnd = false;
	bool bIsExitingDashSlash = false;

	bool bIsEnteringHorizontalSlash = false;
	bool bIsHorizontalSlashing = false;

	bool bIsSpawningPlatformDangerZone = false;

	bool bIsEnteringZigZag = false;
	bool bZigZagAttacking = false;
	bool bIsExitingZigZag = false;

	bool bIsEnteringScissors = false;
	bool bIsScissorsAttacking = false;
	bool bIsExitingScissors = false;

	bool bIsGrabbingDebris = false;
	bool bIsLaunchingDebris = false;
	bool bDebrisActive = false;

	FVector2D IdleBlendSpaceValue;

	bool bIsControlled = false;
	FVector2D ControlledBlendSpaceValue;
	bool bHoldingDebris = false;

	bool bHacked = false;

	bool bIsEnteringMagneticSlam = false;
	bool bMagneticSlamHitReaction = false;
	bool bIsExitingMagneticSlam = false;
	bool bIsExitingMagneticSlamNoBlast = false;

	bool bGrabbingPlayer = false;

	bool bSpawningDonut = false;
}
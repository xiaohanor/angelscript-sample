class UPrisonBossAnimInstance : UHazeAnimInstanceBase
{
	APrisonBoss BossActor;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPrisonBossAttackType CurrentAttackType;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDarkMioScytheAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlying = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIdling = true;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D IdleBlendSpaceValue = FVector2D::ZeroVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsControlled = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ControlledBlendSpaceValue = FVector2D::ZeroVector;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHoldingDebris = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsStunned = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAirborneStunned = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringSpiral = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSpiralling = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingSpiral = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringWaveSlash = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsWaveSlashing = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingWaveSlash = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringClone = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDuplicatingClone = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bClonesAttacking = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTelegraphingClone = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAttackingClone = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsExitingClone = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringGroundTrail = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGroundTrailing = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingGroundTrail = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringHackableMagneticProjectile = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSpawningHackableMagneticProjectile = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchingHackableMagneticProjectile = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHackableMagneticProjectileHitReaction = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringDashSlash = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashSlashTelegraphing = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashSlashAttacking = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashSlashReachedEnd = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingDashSlash = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringHorizontalSlash = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHorizontalSlashing = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSpawningPlatformDangerZone = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringZigZag = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZigZagAttacking = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingZigZag = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringScissors = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsScissorsAttacking = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLeavingScissors = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbingDebris = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchingDebris = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDebrisActive = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDeflectingDebris = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHacked = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringMagneticSlam = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMagneticSlamHitReaction = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsExitingMagneticSlam = false;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsExitingMagneticSlamNoBlast = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbingPlayer = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSpawningDonut = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		BossActor = Cast<APrisonBoss>(HazeOwningActor);
		if (BossActor != nullptr)
			AnimData = BossActor.AnimFeature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if (BossActor == nullptr)
			return;

		CurrentAttackType = BossActor.CurrentAttackType;

		bIsEnteringSpiral = BossActor.AnimationData.bIsEnteringSpiral;
		bIsSpiralling = BossActor.AnimationData.bIsSpiralling;
		bIsLeavingSpiral = BossActor.AnimationData.bIsExitingSpiral;

		bIsEnteringWaveSlash = BossActor.AnimationData.bIsEnteringWaveSlash;
		bIsWaveSlashing = BossActor.AnimationData.bIsWaveSlashing;
		bIsLeavingWaveSlash = BossActor.AnimationData.bIsExitingWaveSlash;

		bIsEnteringClone = BossActor.AnimationData.bIsEnteringClone;
		bIsDuplicatingClone = BossActor.AnimationData.bIsDuplicatingClone;
		bClonesAttacking = BossActor.AnimationData.bClonesAttacking;
		bIsTelegraphingClone = BossActor.AnimationData.bIsTelegraphingClone;
		bIsAttackingClone = BossActor.AnimationData.bIsAttackingClone;

		bIsEnteringGroundTrail = BossActor.AnimationData.bIsEnteringGroundTrail;
		bIsGroundTrailing = BossActor.AnimationData.bIsGroundTrailing;
		bIsLeavingGroundTrail = BossActor.AnimationData.bIsExitingGroundTrail;

		bIsEnteringHackableMagneticProjectile = BossActor.AnimationData.bIsEnteringHackableMagneticProjectile;
		bIsSpawningHackableMagneticProjectile = BossActor.AnimationData.bIsSpawningHackableMagneticProjectile;
		bIsLaunchingHackableMagneticProjectile = BossActor.AnimationData.bIsLaunchingHackableMagneticProjectile;
		bHackableMagneticProjectileHitReaction = BossActor.AnimationData.bHackableMagneticProjectileHitReaction;

		bIsEnteringDashSlash = BossActor.AnimationData.bIsEnteringDashSlash;
		bIsDashSlashTelegraphing = BossActor.AnimationData.bIsDashSlashTelegraphing;
		bIsDashSlashAttacking = BossActor.AnimationData.bIsDashSlashAttacking;
		bDashSlashReachedEnd = BossActor.AnimationData.bDashSlashReachedEnd;
		bIsLeavingDashSlash = BossActor.AnimationData.bIsExitingDashSlash;

		bIsEnteringHorizontalSlash = BossActor.AnimationData.bIsEnteringHorizontalSlash;
		bIsHorizontalSlashing = BossActor.AnimationData.bIsHorizontalSlashing;

		bIsSpawningPlatformDangerZone = BossActor.AnimationData.bIsSpawningPlatformDangerZone;

		bIsEnteringZigZag = BossActor.AnimationData.bIsEnteringZigZag;
		bZigZagAttacking = BossActor.AnimationData.bZigZagAttacking;
		bIsLeavingZigZag = BossActor.AnimationData.bIsExitingZigZag;

		bIsEnteringScissors = BossActor.AnimationData.bIsEnteringScissors;
		bIsScissorsAttacking = BossActor.AnimationData.bIsScissorsAttacking;
		bIsLeavingScissors = BossActor.AnimationData.bIsExitingScissors;

		bIsGrabbingDebris = BossActor.AnimationData.bIsGrabbingDebris;
		bIsLaunchingDebris = BossActor.AnimationData.bIsLaunchingDebris;
		bDebrisActive = BossActor.AnimationData.bDebrisActive;

		bIsIdling = BossActor.AnimationData.bIsIdling;
		IdleBlendSpaceValue = BossActor.AnimationData.IdleBlendSpaceValue;

		bIsStunned = BossActor.AnimationData.bIsStunned;
		bIsAirborneStunned = BossActor.AnimationData.bIsAirborneStunned;

		bIsControlled = BossActor.AnimationData.bIsControlled;
		ControlledBlendSpaceValue = BossActor.AnimationData.ControlledBlendSpaceValue;
		bHoldingDebris = BossActor.AnimationData.bHoldingDebris;

		bHacked = BossActor.AnimationData.bHacked;

		bIsEnteringMagneticSlam = BossActor.AnimationData.bIsEnteringMagneticSlam;
		bMagneticSlamHitReaction = BossActor.AnimationData.bMagneticSlamHitReaction;
		bIsExitingMagneticSlam = BossActor.AnimationData.bIsExitingMagneticSlam;
		bIsExitingMagneticSlamNoBlast = BossActor.AnimationData.bIsExitingMagneticSlamNoBlast;

		bIsGrabbingPlayer = BossActor.AnimationData.bGrabbingPlayer;

		bIsSpawningDonut = BossActor.AnimationData.bSpawningDonut;
	}
}
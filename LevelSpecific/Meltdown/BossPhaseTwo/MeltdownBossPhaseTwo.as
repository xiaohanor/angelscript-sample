enum EMeltdownPhaseTwoAttack
{
	None,

	LavaSword,

	Trident,

	SpaceBat,
	SpaceShips,
	SpaceBomber,
}

class AMeltdownBossPhaseTwo : AMeltdownBoss
{
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseTwoLavaSwordAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseTwoTridentAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseTwoSpaceBatAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseTwoSpaceShipsAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UMeltdownPhaseTwoSpaceBomberAttackCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseTwoFireSword FireSword;
	UPROPERTY()
	TSubclassOf<AMeltdownPhaseTwoLavaSwordShockwave> SwordShockwaveClass;
	
	UPROPERTY(EditAnywhere)
	AMeltdownBossTrident Trident;
	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseTwoBarrageAttack TridentBarrageAttack;

	UPROPERTY()
	TSubclassOf<AMeltdownBossTridentForwardSlam> TridentForwardSlamClass;

	UPROPERTY()
	EMeltdownPhaseTwoAttack CurrentAttack;

	uint32 LastLeftAttackFrame;
	uint32 LastRightAttackFrame;
	uint32 LastDownAttackFrame;

	float TelegraphAttackPosition = 0.0;

	EMeltdownPhasTwoTridentHitLocation TridentHitLocation;
	bool bIsSummoningSharks = false;
	bool bIsSlammingTrident = false;
	uint32 LastTridentAttackFrame;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseTwoBat Bat;
	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseTwoSpaceBatAsteroid> AsteroidClass;

	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseTwoSpaceShip> SpaceShipClass;
	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseTwoBomber> BomberClass;
	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseTwoBomb> BombClass;

	UPROPERTY(EditAnywhere)
	AActor SpaceArenaLocation;

	bool bIsFiringBombs = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		FireSword.Rader = this;
	}

	UFUNCTION()
	void StartAttack(EMeltdownPhaseTwoAttack Attack)
	{
		CurrentAttack = Attack;
	}

	UFUNCTION()
	void StopAttacking()
	{
		CurrentAttack = EMeltdownPhaseTwoAttack::None;
	}

	UFUNCTION(DevFunction)
	void DestroyAllAsteroids()
	{
		for (AMeltdownBossPhaseTwoSpaceBatAsteroid Asteroid : TListedActors<AMeltdownBossPhaseTwoSpaceBatAsteroid>().CopyAndInvalidate())
		{
			if (IsValid(Asteroid))
				Asteroid.DestroyActor();
		}
		for (AMeltdownBossPhaesTwoSpaceBatFireTrail Trail : TListedActors<AMeltdownBossPhaesTwoSpaceBatFireTrail>().CopyAndInvalidate())
		{
			if (IsValid(Trail))
				Trail.DestroyActor();
		}
	}
}
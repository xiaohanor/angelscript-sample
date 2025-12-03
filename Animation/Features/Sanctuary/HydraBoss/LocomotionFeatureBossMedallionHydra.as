// WHEN ADDING MORE ANIMATIONS, PLEASE ALSO ADD SUPPORT IN BOTTOM OF SanctuaryBossMedallionHydraAnimComponent.as
struct FLocomotionFeatureBossMedallionHydraAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
    FHazePlayRndSequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|IdleState")
    FHazePlaySequenceData MhStart;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlayRndSequenceData MhFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData MhFlyingStart;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData ProjectileSingleFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData RoarStartFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData RoarMhFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData RoarEndFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData SubmergeFlying;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Flying")
	FHazePlaySequenceData EmergeFlying;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|Submerge")
	FHazePlaySequenceData Submerge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Emerge")
	FHazePlaySequenceData Emerge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlaySequenceData Death;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
	FHazePlayBlendSpaceData StrangleStruggle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Roar")
	FHazePlaySequenceData RoarStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Roar")
	FHazePlaySequenceData RoarMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Roar")
	FHazePlaySequenceData RoarEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Bite")
	FHazePlaySequenceData BiteStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Bite")
	FHazePlaySequenceData BiteMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Bite")
	FHazePlaySequenceData BiteEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BiteUnder")
	FHazePlaySequenceData BiteUnderStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BiteUnder")
	FHazePlaySequenceData BiteUnderMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BiteUnder")
	FHazePlaySequenceData BiteUnderEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Cheerlead")
	FHazePlaySequenceData CheerleadStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Cheerlead")
	FHazePlaySequenceData CheerleadMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Cheerlead")
	FHazePlaySequenceData CheerleadEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|WaveAttack")
	FHazePlaySequenceData WaveAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|WaveAttack")
	FHazePlaySequenceData WaveAttackAction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|WaveAttack")
	FHazePlaySequenceData WaveAttackEnd;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|RainAttack")
	FHazePlaySequenceData RainAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|RainAttack")
	FHazePlaySequenceData RainAttackAction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|RainAttack")
	FHazePlaySequenceData RainAttackEnd;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|ProjectileSingle")
	FHazePlaySequenceData ProjectileSingleAction;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|ProjectileFlying")
	FHazePlaySequenceData ProjectileFlyingAction;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|ProjectileTripple")
	FHazePlaySequenceData ProjectileTrippleStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ProjectileTripple")
	FHazePlaySequenceData ProjectileTrippleAction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ProjectileTripple")
	FHazePlaySequenceData ProjectileTrippleEnd;

	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|MachineGun")
	FHazePlaySequenceData MachineGunStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MachineGun")
	FHazePlaySequenceData MachineGunAction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MachineGun")
	FHazePlaySequenceData MachineGunEnd;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserOver")
	FHazePlaySequenceData LaserOverStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserOver")
	FHazePlaySequenceData LaserOverActionMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserOver")
	FHazePlaySequenceData LaserOverEnd;
	

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserForward")
	FHazePlaySequenceData LaserForwardStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserForward")
	FHazePlaySequenceData LaserForwardAction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|LaserForward")
	FHazePlaySequenceData LaserForwardEnd;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaMh;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaProjectileSingle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaProjectileTripple;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaRoarStart;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaRoarMh;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaRoarEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaAggroStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaAggroMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaAggroEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaAggroCanceled;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|BallistaAggro")
	FHazePlaySequenceData BallistaAggroDeath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Meteor")
	FHazePlaySequenceData MeteorSpawn;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Meteor")
	FHazePlaySequenceData MeteorFire;
}

class ULocomotionFeatureBossMedallionHydra : UHazeLocomotionFeatureBase
{
	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly)
	FLocomotionFeatureBossMedallionHydraAnimData MedallionAnimData;
}

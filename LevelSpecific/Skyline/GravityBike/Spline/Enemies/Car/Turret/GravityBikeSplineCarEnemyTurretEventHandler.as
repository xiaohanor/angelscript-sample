struct FGravityBikeSplineCarEnemyTurretFireEventData
{
	UPROPERTY()
	UGravityBikeSplineCarEnemyTurretMuzzleComponent MuzzleComp;

	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FVector EndLocation;
};

struct FGravityBikeSplineCarEnemyTurretHitEventData
{
	UPROPERTY()
	UGravityBikeSplineCarEnemyTurretMuzzleComponent MuzzleComp;

	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FHitResult HitResult;
};

UCLASS(Abstract)
class UGravityBikeSplineCarEnemyTurretEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineCarEnemy CarEnemy;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UGravityBikeSplineCarEnemyTurretComponent TurretComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		TurretComp = CarEnemy.TurretComp;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire(FGravityBikeSplineCarEnemyTurretFireEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FGravityBikeSplineCarEnemyTurretHitEventData EventData) {}
};
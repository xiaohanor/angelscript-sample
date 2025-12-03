struct FSkylineFlyingCarEnemyTurretFireEventData
{
	UPROPERTY()
	USkylineFlyingCarEnemyTurretMuzzleComponent MuzzleComp;

	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FVector EndLocation;
};

struct FSkylineFlyingCarEnemyTurretHitEventData
{
	UPROPERTY()
	USkylineFlyingCarEnemyTurretMuzzleComponent MuzzleComp;

	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FHitResult HitResult;
};

UCLASS(Abstract)
class USkylineFlyingCarEnemyTurretEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ASkylineFlyingCarEnemyWithTurret CarEnemy;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	USkylineFlyingCarEnemyTurretComponent TurretComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<ASkylineFlyingCarEnemyWithTurret>(Owner);
		TurretComp = CarEnemy.TurretComp;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire(FSkylineFlyingCarEnemyTurretFireEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FSkylineFlyingCarEnemyTurretHitEventData EventData) {}
};
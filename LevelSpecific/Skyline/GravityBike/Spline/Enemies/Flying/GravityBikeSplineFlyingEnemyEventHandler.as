struct FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData
{
	UPROPERTY()
	FVector Impulse;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	AGravityBikeSplineFlyingEnemy HitFlyingEnemy;

	FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData(
		FVector InImpulse,
		FVector InImpactPoint,
		AGravityBikeSplineFlyingEnemy InHitFlyingEnemy
	)
	{
		Impulse = InImpulse;
		ImpactPoint = InImpactPoint;
		HitFlyingEnemy = InHitFlyingEnemy;	
	}
};

struct FGravityBikeSplineFlyingEnemyOnReflectOffWallEventData
{
	UPROPERTY()
	FVector ReflectionImpulse;

	UPROPERTY()
	FVector WallImpactPoint;

	UPROPERTY()
	FVector WallImpactNormal;

	FGravityBikeSplineFlyingEnemyOnReflectOffWallEventData(
		FVector InReflectionImpulse,
		FVector InWallImpactPoint,
		FVector InWallImpactNormal,
	)
	{
		ReflectionImpulse = InReflectionImpulse;
		WallImpactPoint = InWallImpactPoint;
		WallImpactNormal = InWallImpactNormal;
	}
};

UCLASS(Abstract)
class UGravityBikeSplineFlyingEnemyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBikeSplineFlyingEnemy FlyingEnemy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingEnemy = Cast<AGravityBikeSplineFlyingEnemy>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpacted(FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReflectOffWall(FGravityBikeSplineFlyingEnemyOnReflectOffWallEventData EventData) {}
};
struct FGravityBikeSplineEnemyMissileOnGrabbedEventData
{
	UPROPERTY()
	AHazePlayerCharacter GrabbedByPlayer;
}

struct FGravityBikeSplineEnemyMissileOnDroppedEventData
{
	UPROPERTY()
	AHazePlayerCharacter DroppedByPlayer;
}

struct FGravityBikeSplineEnemyMissileOnHitEventData
{
	UPROPERTY()
	AActor HitActor;

	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	FVector HitNormal;
};

UCLASS(Abstract)
class UGravityBikeSplineEnemyMissileEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	AGravityBikeSplineEnemyMissile Missile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<AGravityBikeSplineEnemyMissile>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed(FGravityBikeSplineEnemyMissileOnGrabbedEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDropped(FGravityBikeSplineEnemyMissileOnDroppedEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(FGravityBikeSplineEnemyMissileOnHitEventData EventData)
	{
	}
};
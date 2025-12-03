struct FFlyingCarEnemyDamageData
{
	UPROPERTY()
	float DamageAmount = 0;

	UPROPERTY()
	float RemainingHealth = 0;
}

struct FFlyingCarEnemyOnHitOtherCarEventData
{
	UPROPERTY()
	FVector HitOtherCarImpulse;

	UPROPERTY()
	FVector HitOtherCarImpactPoint;

	UPROPERTY()
	ASkylineFlyingCarEnemy OtherCar;

	FFlyingCarEnemyOnHitOtherCarEventData(
		FVector InHitOtherCarImpulse,
		FVector InHitOtherCarImpactPoint,
		ASkylineFlyingCarEnemy InOtherCar
	)
	{
		HitOtherCarImpulse = InHitOtherCarImpulse;
		HitOtherCarImpactPoint = InHitOtherCarImpactPoint;
		OtherCar = InOtherCar;	
	}
};

struct FFlyingCarEnemyOnReflectOffWallEventData
{
	UPROPERTY()
	FVector ReflectionImpulse;

	UPROPERTY()
	FVector WallImpactPoint;

	UPROPERTY()
	FVector WallImpactNormal;

	FFlyingCarEnemyOnReflectOffWallEventData(
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

struct FFlyingCarEnemyDestroyedData
{
	FFlyingCarEnemyDestroyedData(USceneComponent _AttachComponent)
	{
		AttachComponent = _AttachComponent;
	}

	UPROPERTY()
	USceneComponent AttachComponent;
}

class UFlyingCarEnemyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ASkylineFlyingCarEnemy CarEnemy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeDamage(FFlyingCarEnemyDamageData DamageData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed(FFlyingCarEnemyDestroyedData DestroyData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWidgetAdd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitOtherCar(FFlyingCarEnemyOnHitOtherCarEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByOtherCar(FFlyingCarEnemyOnHitOtherCarEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReflectOffWall(FFlyingCarEnemyOnReflectOffWallEventData EventData) {}
}
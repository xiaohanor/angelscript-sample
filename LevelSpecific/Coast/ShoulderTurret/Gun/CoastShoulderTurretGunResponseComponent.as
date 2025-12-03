struct FCoastShoulderTurretBulletHitParams
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	float Damage = 0.0;

	UPROPERTY()
	UPrimitiveComponent HitComponent;

	UPROPERTY()
	AHazeActor PlayerInstigator;
}

event void FOnCoastShoulderTurretBulletHit(FCoastShoulderTurretBulletHitParams Params);

class UCoastShoulderTurretGunResponseComponent : USceneComponent
{
	// Called when hit by bullet
	UPROPERTY()
	FOnCoastShoulderTurretBulletHit OnBulletHit;
}
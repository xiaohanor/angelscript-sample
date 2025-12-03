struct FCoastShoulderTurretShotEffectParams
{
	UPROPERTY()
	FVector ShotDirection;

	UPROPERTY()
	UHazeSkeletalMeshComponentBase TurretMesh;

	UPROPERTY()
	FName SocketName;
}

struct FCoastShoulderTurretShotImpactEffectParams
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	UPrimitiveComponent HitComponent;
}

UCLASS(Abstract)
class UCoastShoulderTurretEffectHandler : UHazeEffectEventHandler
{
	// Called when bullet fired
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletFired(FCoastShoulderTurretShotEffectParams Params) {}

	// Called when bullet impacts something
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletImpact(FCoastShoulderTurretShotImpactEffectParams Params) {}
}
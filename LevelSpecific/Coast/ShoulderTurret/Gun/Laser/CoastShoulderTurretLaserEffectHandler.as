struct FCoastShoulderTurretLaserToggleEffectParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase TurretMesh;

	UPROPERTY()
	FName SocketName;
}

struct FCoastShoulderturretLaserShootingEffectParams
{
	UPROPERTY()
	FVector LaserStart;

	UPROPERTY()
	FVector LaserEnd;
}

struct FCoastShoulderTurretLaserImpactEffectParams
{
	UPROPERTY()
	UPrimitiveComponent HitComponent;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

UCLASS(Abstract)
class UCoastShoulderTurretLaserEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartShooting(FCoastShoulderTurretLaserToggleEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedShooting(FCoastShoulderTurretLaserToggleEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhileLaserShooting(FCoastShoulderturretLaserShootingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WhileLaserImpacting(FCoastShoulderTurretLaserImpactEffectParams Params) {}

}
struct FAdultDragonAcidBoltImpactParams
{
	UPROPERTY()
	FVector HitPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

struct FAdultDragonAcidBoltFireParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}

UCLASS(Abstract)
class UAdultDragonAcidProjectileEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileImpactExplosion(FAdultDragonAcidBoltImpactParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileFire(FAdultDragonAcidBoltFireParams Params) {}
}
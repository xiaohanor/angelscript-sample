struct FAdultDragonSpikeImpactParams
{
	UPROPERTY()
	FVector HitPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

struct FAdultDragonSpikeFireParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}

UCLASS(Abstract)
class UAdultDragonSpikeProjectileEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpikeProjectileImpactExplosion(FAdultDragonSpikeImpactParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpikeProjectileFire(FAdultDragonSpikeFireParams Params) {}
}
struct FAdultDragonAcidChargeProjectileStartedParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}
struct FAdultDragonAcidChargeProjectileReleasedParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}

struct FAdultDragonAcidChargeProjectileFinishedParams
{
	UPROPERTY()
	UHazeCharacterSkeletalMeshComponent DragonMesh;
}

struct FAdultDragonAcidChargeProjectileImpactParams
{
	UPROPERTY()
	FVector HitPoint;

	UPROPERTY()
	FVector ImpactNormal;
}

UCLASS(Abstract)
class UAdultDragonAcidChargeProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidChargeProjectileChargeStarted(FAdultDragonAcidChargeProjectileStartedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidChargeProjectileChargeReleased(FAdultDragonAcidChargeProjectileReleasedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidChargeProjectileChargeFinished(FAdultDragonAcidChargeProjectileFinishedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidChargeProjectileImpact(FAdultDragonAcidChargeProjectileImpactParams Params) {}
}
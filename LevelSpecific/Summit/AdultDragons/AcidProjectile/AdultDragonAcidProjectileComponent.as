event void FAdultAcidDragonOnProjectileFired();

UCLASS(Abstract)
class UAdultDragonAcidProjectileComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AAdultDragonAcidProjectile> AcidProjectileClass;

	FAdultAcidDragonOnProjectileFired OnProjectileFired;
};
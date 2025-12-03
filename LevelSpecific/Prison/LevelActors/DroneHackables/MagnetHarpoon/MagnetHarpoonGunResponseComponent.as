UCLASS(NotBlueprintable)
class UMagnetHarpoonGunResponseComponent : UActorComponent
{
	UPROPERTY()
	FMagnetGunAttachEvent OnHarpoonAttached;

	UPROPERTY()
	FMagnetGunAttachEvent OnHarpoonDetached;
}

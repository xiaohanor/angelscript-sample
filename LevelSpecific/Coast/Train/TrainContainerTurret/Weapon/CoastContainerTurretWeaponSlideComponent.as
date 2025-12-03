class UCoastContainerTurretWeaponSlideComponent : UActorComponent
{
	ACoastContainerTurretWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Weapon = Cast<ACoastContainerTurretWeapon>(Owner);
	}
}
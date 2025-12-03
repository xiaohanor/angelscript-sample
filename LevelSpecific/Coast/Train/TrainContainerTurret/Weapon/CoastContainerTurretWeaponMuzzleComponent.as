class UCoastContainerTurretWeaponMuzzleComponent : USceneComponent
{
	ACoastContainerTurretWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Weapon = Cast<ACoastContainerTurretWeapon>(Owner);
	}
}
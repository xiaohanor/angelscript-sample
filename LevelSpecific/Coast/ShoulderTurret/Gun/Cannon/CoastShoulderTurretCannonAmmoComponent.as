event void FCoastShoulderTurretCannonAmmoChangeEvent(int NewAmmoCount);

class UCoastShoulderTurretCannonAmmoComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretCannonAmmoChangeEvent OnAmmoChanged;

	AHazePlayerCharacter Player;
	UCoastShoulderTurretComponent TurretComp;
	UPlayerAimingComponent AimComp;

	ACoastShoulderTurret Turret;
	UCoastShoulderTurretCannonSettings GunSettings;

	int CurrentAmmoCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		Turret = TurretComp.Turret;
		GunSettings = UCoastShoulderTurretCannonSettings::GetSettings(Player);

		CurrentAmmoCount = GunSettings.MaxAmmoCount;
	}

	void ChangeAmmo(int NewAmmoCount)
	{
		CurrentAmmoCount = NewAmmoCount;
		CurrentAmmoCount = Math::Clamp(CurrentAmmoCount, 0, GunSettings.MaxAmmoCount);
		OnAmmoChanged.Broadcast(CurrentAmmoCount);
	}
};

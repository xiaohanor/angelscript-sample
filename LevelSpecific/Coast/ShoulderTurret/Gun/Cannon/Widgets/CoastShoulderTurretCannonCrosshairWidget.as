class UCoastShoulderTurretCannonCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BlueprintReadOnly)
	ACoastShoulderTurret Turret;
	
	UPROPERTY(BlueprintReadOnly)
	UCoastShoulderTurretCannonAmmoComponent AmmoComp;

	UPROPERTY(BlueprintReadWrite)
	TArray<UCoastShoulderTurretCannonShotWidget> ShotWidgets;
	
	UCoastShoulderTurretComponent TurretComp;
	UCoastShoulderTurretCannonSettings CannonSettings;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AmmoComp = UCoastShoulderTurretCannonAmmoComponent::Get(Player);
		TurretComp = UCoastShoulderTurretComponent::Get(Player);

		Turret = TurretComp.Turret;

		CannonSettings = UCoastShoulderTurretCannonSettings::GetSettings(Player);
	}
}
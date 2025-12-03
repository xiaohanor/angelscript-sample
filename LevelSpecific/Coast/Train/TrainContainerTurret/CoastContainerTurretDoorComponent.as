class UCoastContainerTurretDoorComponent : USceneComponent
{
	ACoastContainerTurret Turret;
	bool DoOpen;
	bool IsOpen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Turret = Cast<ACoastContainerTurret>(Owner);
	}

	UFUNCTION()
	void Open()
	{
		DoOpen = true;
	}
}
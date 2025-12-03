UCLASS(Abstract)
class ACoastContainerTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UCoastContainerTurretDoorComponent TurretDoor;

	UPROPERTY(DefaultComponent)
	UCoastContainerTurretFallComponent FallComp;

	UPROPERTY(DefaultComponent)
	USceneComponent WeaponComp;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"CoastContainerTurretOpenDoorCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CoastContainerTurretFallCapability");	
	// default CapabilityComp.DefaultCapabilities.Add(n"CoastContainerTurretDetectTargetCapability");

	UPROPERTY()
	TSubclassOf<ACoastContainerTurretWeapon> WeaponClass;
	ACoastContainerTurretWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true);
		Weapon.MakeNetworked(this, n"TurretWeapon");
		Weapon.Turret = this;
		FinishSpawningActor(Weapon);
		Weapon.AttachToComponent(WeaponComp, AttachmentRule = EAttachmentRule::SnapToTarget);
		FallComp.PrepareFall();
	}

	UFUNCTION(BlueprintCallable)
	void Open()
	{
		TurretDoor.Open();
	}

	UFUNCTION(BlueprintCallable)
	void Fall(float OpenDelay)
	{
		FallComp.Fall();
		FallComp.OpenDelay = OpenDelay;
	}
}
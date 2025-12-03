class UCoastShoulderTurretGunComponent : USceneComponent
{
	/* The order it shoots in
	goes 0 -> upwards, any canon you set to the same index fires at the same time*/
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	int ShootIndex = 0;

	UHazeSkeletalMeshComponentBase TurretSkelMeshComp;

	ACoastShoulderTurret Turret;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Turret = Cast<ACoastShoulderTurret>(Owner);
		Turret.Guns.Add(this);
		Player = Turret.Player;

		TurretSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(GetChildComponent(0));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Turret.Guns.Remove(this);
	}
};
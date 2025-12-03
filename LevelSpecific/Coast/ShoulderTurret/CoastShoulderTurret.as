
event void FCoastShoulderTurretStartShootingEvent();
event void FCoastShoulderTurretStoppedShootingEvent();
event void FCoastShoulderTurretHitEvent();
event void FCoastShoulderTurretAimToggleEvent();

class ACoastShoulderTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretHitEvent OnShotHit;

	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretStartShootingEvent OnStartShooting;

	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretStoppedShootingEvent OnStoppedShooting;

	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretAimToggleEvent OnStartAiming;

	UPROPERTY(BlueprintReadOnly)
	FCoastShoulderTurretAimToggleEvent OnStoppedAiming;

	TArray<UCoastShoulderTurretGunComponent> Guns;

	AHazePlayerCharacter Player;

	TInstigated<bool> ActiveInstigators;
	TInstigated<bool> AimInstigators;
	bool bIsShooting = false; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	bool TurretIsActive() const
	{
		return ActiveInstigators.Get();
	}

	bool IsAiming() const
	{
		return AimInstigators.Get();
	}

	bool IsShooting() const
	{
		return bIsShooting;
	}
};
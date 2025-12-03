class UCoastContainerTurretFallComponent : UActorComponent
{
	ACoastContainerTurret Turret;
	bool bFall;
	bool bFell;
	float OpenDelay;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandCameraShake;
	UPROPERTY()
	UForceFeedbackEffect LandForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Turret = Cast<ACoastContainerTurret>(Owner);
	}

	UFUNCTION()
	void Fall()
	{
		bFall = true;
	}

	void PrepareFall()
	{
		Turret.AddActorVisualsBlock(this);
		Turret.Weapon.AddActorVisualsBlock(this);
	}

	void StartFall()
	{
		Turret.RemoveActorVisualsBlock(this);
		Turret.Weapon.RemoveActorVisualsBlock(this);
	}
}
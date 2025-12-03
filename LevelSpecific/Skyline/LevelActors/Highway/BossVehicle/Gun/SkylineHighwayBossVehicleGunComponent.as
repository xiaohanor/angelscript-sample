class USkylineHighwayBossVehicleGunComponent : UActorComponent
{
	AHazeActor HazeOwner;
	TInstigated<bool> bHasAim;
	FRotator AimRotation;
	float Duration;
	bool bInUse;
	bool bIsInBarrage = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		DisableVolley();
	}

	void SetAim(FRotator _AimRotation, float _Duration, FInstigator Instigator)
	{
		AimRotation = _AimRotation;
		Duration = _Duration;
		bHasAim.Apply(true, Instigator);
	}

	void CancelAim(FInstigator Instigator)
	{
		bHasAim.Clear(Instigator);
	}

	void EnableVolley()
	{
		if(HazeOwner.IsCapabilityTagBlocked(n"Volley"))
			HazeOwner.UnblockCapabilities(n"Volley", this);
	}

	void DisableVolley()
	{
		if(!HazeOwner.IsCapabilityTagBlocked(n"Volley"))
			HazeOwner.BlockCapabilities(n"Volley", this);
	}
}
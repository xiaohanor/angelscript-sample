class UCoastBossDroneComponent : UStaticMeshComponent
{
	UPROPERTY(EditAnywhere)
	bool bIsWeakpoint = false;

	UPROPERTY(EditAnywhere)
	bool bDisabledInPhase = false;

	UPROPERTY(EditAnywhere)
	bool bIsShootyDrone = false;

	UPROPERTY(EditAnywhere)
	int DroneID = 0;

	int opCmp(UCoastBossDroneComponent Other) const
	{
		if (DroneID < Other.DroneID)
			return -1;
		else if (DroneID > Other.DroneID)
			return 1;
		return 0;
	}

	void Become(const UCoastBossDroneComponent& Other)
	{
		bIsWeakpoint = Other.bIsWeakpoint;
		bDisabledInPhase = Other.bDisabledInPhase;
		bIsShootyDrone = Other.bIsShootyDrone;
	}

};
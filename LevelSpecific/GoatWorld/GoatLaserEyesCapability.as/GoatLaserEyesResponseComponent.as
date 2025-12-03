event void FGoatLaserEyesStartEvent();
event void FGoatLaserEyesStopEvent();
event void FGoatLaserEyesUpdateEvent();

class UGoatLaserEyesResponseComponent : UActorComponent
{
	UPROPERTY()
	FGoatLaserEyesStartEvent OnLaserEyesStart;

	UPROPERTY()
	FGoatLaserEyesStopEvent OnLaserEyesStop;

	UPROPERTY()
	FGoatLaserEyesUpdateEvent OnLaserEyesUpdate;

	bool bLasered = false;

	void StartLaser()
	{
		bLasered = true;
		OnLaserEyesStart.Broadcast();
	}

	void StopLaser()
	{
		bLasered = false;
		OnLaserEyesStop.Broadcast();
	}

	void Update()
	{
		OnLaserEyesUpdate.Broadcast();
	}

	UFUNCTION(BlueprintPure)
	bool IsLasered()
	{
		return bLasered;
	}
}
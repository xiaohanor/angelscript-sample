class UMagneticFieldEventHandlerVFX : UMagneticFieldEventHandler
{
	UFUNCTION(BlueprintOverride)
	void StartedCharging()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Charging(FMagneticFieldChargingData ChargeData)
	{
	}

	UFUNCTION(BlueprintOverride)
	void FinishedCharging()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Stopped()
	{

	}
}
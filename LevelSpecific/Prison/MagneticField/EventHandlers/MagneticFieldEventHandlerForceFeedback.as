class UMagneticFieldEventHandlerForceFeedback : UMagneticFieldEventHandler
{
	UPROPERTY()
	UForceFeedbackEffect BurstForceFeedback;

	UFUNCTION(BlueprintOverride)
	void StartedCharging()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Charging(FMagneticFieldChargingData ChargeData)
	{
		float FFIntensity = Math::Lerp(0.0, 0.2, ChargeData.ChargeAlpha);
		Player.SetFrameForceFeedback(FFIntensity, FFIntensity, 0.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void FinishedCharging()
	{
		ForceFeedback::PlayWorldForceFeedback(BurstForceFeedback, MagneticFieldComp.GetMagneticFieldCenterPoint(), true, n"MagneticFieldBurst", MagneticField::GetTotalRadius() * 0.75, MagneticField::GetTotalRadius() * 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void Stopped()
	{

	}
}
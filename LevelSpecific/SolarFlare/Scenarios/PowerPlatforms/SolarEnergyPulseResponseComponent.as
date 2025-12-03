event void FOnSolarEnergyPulseStarted();
event void FOnSolarEnergyPulseStopped();

class USolarEnergyPulseResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSolarEnergyPulseStarted SolarEnergyPulseStarted;

	UPROPERTY()
	FOnSolarEnergyPulseStopped SolarEnergyPulseStopped;

	UFUNCTION()
	void EnergyPulseStart()
	{
		SolarEnergyPulseStarted.Broadcast();
	}

	UFUNCTION()
	void EnergyPulseStop()
	{
		SolarEnergyPulseStopped.Broadcast();
	}
}

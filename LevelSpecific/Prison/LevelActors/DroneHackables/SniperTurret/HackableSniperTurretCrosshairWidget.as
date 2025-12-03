class UHackableSniperTurretCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BlueprintReadOnly)
	AHackableSniperTurret SniperTurret;

	UPROPERTY(BlueprintReadOnly)
	float StartTime;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		StartTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintPure)
	float GetTimeSinceStart() const
	{
		return Time::GameTimeSeconds - StartTime;
	}
}
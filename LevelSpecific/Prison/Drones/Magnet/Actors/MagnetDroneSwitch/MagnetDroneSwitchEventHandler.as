UCLASS(Abstract)
class UMagnetDroneSwitchEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AMagnetDroneSwitch MagnetDroneSwitch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetDroneSwitch = Cast<AMagnetDroneSwitch>(Owner);
	}
	
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attached(FOnMagnetDroneAttachedParams EventData)
    {
    }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Detached(FOnMagnetDroneDetachedParams EventData)
    {
    }
}
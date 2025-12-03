struct FOnMachinaryPlayerStartedZipline
{
	UPROPERTY()
	AHazePlayerCharacter HangingPlayer;
}

UCLASS(Abstract)
class USolarFlareVOMachinaryZiplineEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMachinaryPlayerStartedZipline(FOnMachinaryPlayerStartedZipline Params)
	{
	}
};
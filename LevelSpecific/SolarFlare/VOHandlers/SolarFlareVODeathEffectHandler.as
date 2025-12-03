struct FOnSolarFlareDeathParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USolarFlareVODeathEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarFlareDeath(FOnSolarFlareDeathParams Params)
	{
	}
};
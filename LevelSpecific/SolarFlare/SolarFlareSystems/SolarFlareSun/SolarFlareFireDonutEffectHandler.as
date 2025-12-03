struct FOnSolarDonutWaveImpactPlayersParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareFireDonutEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarDonutWaveImpactPlayers(FOnSolarDonutWaveImpactPlayersParams Params)
	{
	}
};
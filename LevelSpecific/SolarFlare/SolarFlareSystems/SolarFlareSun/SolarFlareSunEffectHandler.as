struct FOnSolarFlareSunTelegraph
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float TelegraphDuration;
}

struct FOnSolarFlareSunExplosion
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float WaitDuration;

	UPROPERTY()
	ESolarFlareSunPhase CurrentPhase;
}

struct FOnSolarFlareSunPhaseChangedParams
{
	UPROPERTY()
	ESolarFlareSunPhase NewPhase;
}

struct FOnSolarFlareSunTimingsChangedParams
{
	UPROPERTY()
	float NewWaitDuration;

	UPROPERTY()
	float NewTelegraphDuration;

	UPROPERTY()
	float TotalTimeDuration;
}

UCLASS(Abstract)
class USolarFlareSunEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSunTelegraph(FOnSolarFlareSunTelegraph Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSunExplosion(FOnSolarFlareSunExplosion Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPhaseChanged(FOnSolarFlareSunPhaseChangedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSunTimingsChanged(FOnSolarFlareSunTimingsChangedParams Params) {}
}
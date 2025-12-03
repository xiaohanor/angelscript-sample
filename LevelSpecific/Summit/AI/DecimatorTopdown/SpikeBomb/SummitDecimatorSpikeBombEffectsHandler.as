struct FSummitDecimatorSpikeBombLaunchParams
{
	FSummitDecimatorSpikeBombLaunchParams(FVector ALaunchLocation, FVector ALaunchDir)
	{
		LaunchLocation = ALaunchLocation;
		LaunchDir = ALaunchDir;
	}

	UPROPERTY(BlueprintReadOnly)
	FVector LaunchLocation;
	
	UPROPERTY(BlueprintReadOnly)
	FVector LaunchDir;
}


UCLASS(Abstract)
class USummitDecimatorSpikeBombEffectsHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched(FSummitDecimatorSpikeBombLaunchParams Params) {}

	// Special case of OnLaunched	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned(FSummitDecimatorSpikeBombLaunchParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDecimatorImpact() {}

	// Timer ran out mid-air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplodeMidAir() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded() {}

	// Special case of OnLanded
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandedAfterSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMelted() {}
}
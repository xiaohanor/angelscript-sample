UCLASS(Abstract)
class USummitDecimatorSpearShowerEffectsHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnedInGround(FSummitDecimatorSpearShowerSpawnedInGroundParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExposed() {}

}

struct FSummitDecimatorSpearShowerSpawnedInGroundParams
{
	FSummitDecimatorSpearShowerSpawnedInGroundParams(FVector _SpearTipLocation)
	{
		SpearTipLocation = _SpearTipLocation;
	}

	UPROPERTY()
	FVector SpearTipLocation;	
}
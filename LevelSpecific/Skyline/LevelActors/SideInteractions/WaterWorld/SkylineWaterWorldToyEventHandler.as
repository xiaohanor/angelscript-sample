
struct FSkylineWaterToyLandInWaterData
{
	UPROPERTY()
	FVector SplashVelocity;
}

UCLASS(Abstract)
class USkylineWaterWorldToyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerBumpIntoSide(FSkylineSwimmingBumpRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBumpIntoRing(FSkylineSwimmingBumpEnvRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBumpIntoWall(FSkylineSwimmingBumpEnvRingEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandInWater(FSkylineWaterToyLandInWaterData Data) {}
};
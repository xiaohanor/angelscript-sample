struct FStormChaseFallingPillarParams
{
	UPROPERTY()
	FVector Location;

	FStormChaseFallingPillarParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
} 

UCLASS(Abstract)
class UStormChaseFallingPillarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFallingPillar(FStormChaseFallingPillarParams Params) {}
};
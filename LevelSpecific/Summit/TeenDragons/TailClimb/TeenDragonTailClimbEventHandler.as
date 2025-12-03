struct FTeenDragonTailClimbOnFootSteppedInVinesParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FVector WallNormal;
}

UCLASS(Abstract)
class UTeenDragonTailClimbEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootSteppedOnVine(FTeenDragonTailClimbOnFootSteppedInVinesParams Params) {}
};
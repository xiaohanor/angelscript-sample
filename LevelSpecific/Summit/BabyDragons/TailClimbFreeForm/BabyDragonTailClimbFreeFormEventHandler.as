struct FBabyDragonTailClimbFreeFormOnTailAttachedParams
{
	UPROPERTY()
	FVector TailAttachLocation;
}

struct FBabyDragonTailClimbFreeFormOnTailReleasedParams
{
	UPROPERTY()
	FVector TailReleaseLocation;
}

UCLASS(Abstract)
class UBabyDragonTailClimbFreeFormEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTailAttached(FBabyDragonTailClimbFreeFormOnTailAttachedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTailReleased(FBabyDragonTailClimbFreeFormOnTailReleasedParams Params) {}
};
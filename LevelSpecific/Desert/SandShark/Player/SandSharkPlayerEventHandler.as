struct FSandSharkHuntedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USandSharkPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBecameHunted(FSandSharkHuntedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedBeingHunted(FSandSharkHuntedParams Params) {}
};
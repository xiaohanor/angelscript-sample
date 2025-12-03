struct FIslandDroidZiplineManagerAttachParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UIslandDroidZiplineManagerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerAttached(FIslandDroidZiplineManagerAttachParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDetached(FIslandDroidZiplineManagerAttachParams Params) {}
}
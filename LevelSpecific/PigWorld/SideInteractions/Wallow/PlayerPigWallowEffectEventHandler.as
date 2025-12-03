UCLASS(Abstract)
class UPlayerPigWallowEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartWallowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopWallowing() {}
}

class UPlayerPigWallowVOEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartWallowing(FPlayerPigWallowEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopWallowing(FPlayerPigWallowEffectEventParams Params) {}
}

struct FPlayerPigWallowEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	bool bWallow = true;
}
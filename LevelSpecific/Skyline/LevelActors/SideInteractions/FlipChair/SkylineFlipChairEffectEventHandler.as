UCLASS(Abstract)
class USkylineFlipChairEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitGround(FSkylineFlipChairEffectEventParams Params) {}
}

struct FSkylineFlipChairEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}
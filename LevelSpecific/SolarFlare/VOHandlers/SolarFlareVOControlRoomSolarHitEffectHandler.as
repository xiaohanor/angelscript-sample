struct FSolarFlareVOControlRoomHitParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USolarFlareVOControlRoomSolarHitEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlareHit(FSolarFlareVOControlRoomHitParams Params)
	{
	}
};
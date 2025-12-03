UCLASS(Abstract)
class UBattlefieldAutoCannonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot() {}
};
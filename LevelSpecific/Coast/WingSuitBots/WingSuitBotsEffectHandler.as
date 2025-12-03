UCLASS(Abstract)
class UWingSuitBotsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootAirMine() {}
}
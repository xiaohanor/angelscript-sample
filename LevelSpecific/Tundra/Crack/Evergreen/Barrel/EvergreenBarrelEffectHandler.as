UCLASS(Abstract)
class UEvergreenBarrelEffectHandler : UHazeEffectEventHandler
{
	// When the barrel starts turning (When turn rate goes from 0 to not 0).
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTurning() {}

	// When the barrel starts turning (When turn rate goes from not 0 to 0).
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopTurning() {}

	// When the monkey is shot out of the barrel.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootMonkey() {}

	// When the monkey enters the barrel.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReceiveMonkey() {}
}
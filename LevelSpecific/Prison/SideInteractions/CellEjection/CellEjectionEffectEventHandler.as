UCLASS(Abstract)
class UCellEjectionEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayersApproach() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayersLeave() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ejected() {}
}
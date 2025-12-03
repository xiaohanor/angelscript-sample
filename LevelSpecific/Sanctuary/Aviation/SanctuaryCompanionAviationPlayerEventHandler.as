
UCLASS(Abstract)
class USanctuaryCompanionAviationPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackSuccess() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttackFail() {}
}
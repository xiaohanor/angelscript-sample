UCLASS(Abstract)
class USketchbookBossEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeDamageEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossPhaseOneRemoved(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossKilled(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttack(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPrepareAttack(){}
};
struct FSkylineInnerReceptionistEventStateChangedParams
{
	UPROPERTY()
	ESkylineInnerReceptionistBotState State;
}

struct FSkylineInnerReceptionistEventExpressionChangedParams
{
	UPROPERTY()
	ESkylineInnerReceptionistBotExpression Expression;
}

struct FSkylineInnerReceptionistEventPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class USkylineInnerReceptionistEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStateChanged(FSkylineInnerReceptionistEventStateChangedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpressionChanged(FSkylineInnerReceptionistEventExpressionChangedParams Params) {}

	// ---

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerInGreetingRange(FSkylineInnerReceptionistEventPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerLeftGreetingRange(FSkylineInnerReceptionistEventPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerInAnnoyedRange(FSkylineInnerReceptionistEventPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerLeftAnnoyedRange(FSkylineInnerReceptionistEventPlayerParams Params) {}

	// ---

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIdleWorkingTicking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToZoeGrabCup() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToZoeThrowCup() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToZoeStartTickleReceptionist() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToZoeStopTickleReceptionist() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToZoeTickleReceptionistTicking() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToMioBladeHitReceptionist() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerStartOnTopOfReceptionist(FSkylineInnerReceptionistEventPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToPlayerStopOnTopOfReceptionist(FSkylineInnerReceptionistEventPlayerParams Params) {}

};
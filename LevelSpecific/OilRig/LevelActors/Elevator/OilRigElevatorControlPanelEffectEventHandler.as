struct FOilRigElevatorControlPanelEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UOilRigElevatorControlPanelEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Raise() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Lower() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerStartedInteracting(FOilRigElevatorControlPanelEffectEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerStoppedInteracting(FOilRigElevatorControlPanelEffectEventParams Params) {}
}
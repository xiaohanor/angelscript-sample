UCLASS(Abstract)
class AOilRigElevatorControlPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PanelRool;

	UFUNCTION()
	void Raise()
	{
		BP_Raise();

		UOilRigElevatorControlPanelEffectEventHandler::Trigger_Raise(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Raise() {}

	UFUNCTION()
	void Lower()
	{
		BP_Lower();

		UOilRigElevatorControlPanelEffectEventHandler::Trigger_Lower(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Lower() {}

	UFUNCTION()
	void PlayerStartedInteracting(AHazePlayerCharacter Player)
	{
		FOilRigElevatorControlPanelEffectEventParams Params;
		Params.Player = Player;

		UOilRigElevatorControlPanelEffectEventHandler::Trigger_PlayerStartedInteracting(this, Params);
	}

	UFUNCTION()
	void PlayerStoppedInteracting(AHazePlayerCharacter Player)
	{
		FOilRigElevatorControlPanelEffectEventParams Params;
		Params.Player = Player;
		
		UOilRigElevatorControlPanelEffectEventHandler::Trigger_PlayerStoppedInteracting(this, Params);
	}
}
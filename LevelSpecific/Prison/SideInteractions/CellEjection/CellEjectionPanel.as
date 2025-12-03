class ACellEjectionPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UFUNCTION()
	void ButtonPressed()
	{
		UCellEjectionPanelEffectEventHandler::Trigger_ButtonPressed(this);
	}
}

class UCellEjectionPanelEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ButtonPressed() {}
}
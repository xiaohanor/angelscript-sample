struct FSkylineAllyElectricSignKillPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USkylineAllyElectricSignEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKillPlayer(FSkylineAllyElectricSignKillPlayerParams Params) {}
}

class ASkylineAllyElectricSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleClimbActor;

	UPROPERTY(EditInstanceOnly)
	bool bStartEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		DeathTriggerComp.OnPlayerEnter.AddUFunction(this, n"HandleKillPlayer");

		if (bStartEnabled)
			HandleActivated(nullptr);
	}

	UFUNCTION()
	private void HandleKillPlayer(AHazePlayerCharacter Player)
	{
		FSkylineAllyElectricSignKillPlayerParams Params;
		Params.Player = Player;

		USkylineAllyElectricSignEventHandler::Trigger_OnKillPlayer(this, Params);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		DeathTriggerComp.EnableTrigger(this);
		BP_Activated();

		USkylineAllyElectricSignEventHandler::Trigger_OnActivated(this);
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		DeathTriggerComp.DisableTrigger(this);
		BP_Deactivated();

		USkylineAllyElectricSignEventHandler::Trigger_OnDeactivated(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activated()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivated()
	{
	}
};
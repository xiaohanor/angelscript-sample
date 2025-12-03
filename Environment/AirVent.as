class AAirVent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UFUNCTION()
	void OpenShutters()
	{
		BP_OpenShutters();

		UAirVentEffectEventHandler::Trigger_OpenShutters(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenShutters() {}

	UFUNCTION()
	void CloseShutters()
	{
		BP_CloseShutters();

		UAirVentEffectEventHandler::Trigger_CloseShutters(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_CloseShutters() {}
}

class UAirVentEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OpenShutters() {}

	UFUNCTION(BlueprintEvent)
	void CloseShutters() {}
}
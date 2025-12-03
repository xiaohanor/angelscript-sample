class ASkylineMallChaseZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	void ActivateZone()
	{
		PrintToScreen("MallChaseZone Activated: " + Name, 3.0, FLinearColor::Green);
		InterfaceComp.TriggerActivate();
	}
};
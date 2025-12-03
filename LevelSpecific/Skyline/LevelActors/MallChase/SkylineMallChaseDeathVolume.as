class ASkylineMallChaseDeathVolume : ADeathVolume
{
	default bStartDisabled = true;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		PrintToScreen("Death Volume Activated" + Name, 3.0, FLinearColor::Green);

		EnableAfterStartDisabled();
	}
};
class URemoteHackableCoffeeMachineCapability : URemoteHackableBaseCapability
{
	ARemoteHackableCoffeeMachine CoffeeMachine;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		CoffeeMachine = Cast<ARemoteHackableCoffeeMachine>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_StartHacking(CoffeeMachine);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		CoffeeMachine.StopDispensingCoffee();

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_StopHacking(CoffeeMachine);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (IsActioning(ActionNames::PrimaryLevelAbility))
		{
			CoffeeMachine.StartDispensingCoffee();
		}
		else
		{
			CoffeeMachine.StopDispensingCoffee();
		}
	}
}
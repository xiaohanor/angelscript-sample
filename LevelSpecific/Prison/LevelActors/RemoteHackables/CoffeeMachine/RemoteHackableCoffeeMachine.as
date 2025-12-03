UCLASS(Abstract)
class ARemoteHackableCoffeeMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MachineRoot;

	UPROPERTY(DefaultComponent, Attach = MachineRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent, Attach = MachineRoot)
	USceneComponent CupRoot;

	UPROPERTY(DefaultComponent, Attach = CupRoot)
	USceneComponent CoffeeRoot;

	UPROPERTY(DefaultComponent, Attach = MachineRoot)
	UOneShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableCoffeeMachineCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.PlayerCapabilities.Add(n"RemoteHackableCoffeeMachineSpeedCapability");

	float FillAlpha = 0.0;
	float FillSpeed = 0.5;
	bool bFilled = false;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		InteractionComp.Disable(this);

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		URemoteHackableCoffeeMachinePlayerComponent CoffeeMachineComp = URemoteHackableCoffeeMachinePlayerComponent::GetOrCreate(Player);
		CoffeeMachineComp.bCoffeeDrunk = true;

		InteractionComp.Disable(this);
		CoffeeRoot.SetRelativeLocation(FVector(0.0, 0.0, -1.0));
		FillAlpha = 0.0;
		bFilled = false;

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_CoffeeDrunk(this);
	}

	void StartDispensingCoffee()
	{
		bActive = true;

		BP_StartDispensing();

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_StartFilling(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartDispensing() {}

	void StopDispensingCoffee()
	{
		bActive = false;

		BP_StopDispensing();

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_StopFilling(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopDispensing() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			if (!bFilled)
			{
				FillAlpha = Math::Clamp(FillAlpha + (FillSpeed * DeltaTime), 0.0, 1.0);

				float CoffeeHeight = Math::Lerp(-1.0, 15.0, FillAlpha);
				CoffeeRoot.SetRelativeLocation(FVector(0.0, 0.0, CoffeeHeight));
				if (FillAlpha >= 1.0)
				{
					Filled();
				}
			}
		}
	}

	void Filled()
	{
		bFilled = true;
		InteractionComp.Enable(this);

		URemoteHackableCoffeeMachineEffectEventHandler::Trigger_Filled(this);
	}
}
UCLASS(Abstract)
class APrisonPoleGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintCallable)
	void LightOnLeft()
	{
		UPrisonPoleGateEventHandler::Trigger_LightOnLeft(this);
		Print("Left");
	}

	UFUNCTION(BlueprintCallable)
	void LightOnRight()
	{
		UPrisonPoleGateEventHandler::Trigger_LightOnRight(this);
		Print("Right");
	}

	UFUNCTION(BlueprintCallable)
	void LightOffLeft()
	{
		UPrisonPoleGateEventHandler::Trigger_LightOffLeft(this);
		Print("LeftOff");
	}

	UFUNCTION(BlueprintCallable)
	void LightOffRight()
	{
		UPrisonPoleGateEventHandler::Trigger_LightOffRight(this);
		Print("RightOff");
	}

	UFUNCTION(BlueprintCallable)
	void LightGreen()
	{
		UPrisonPoleGateEventHandler::Trigger_LightGreen(this);
	}

	UFUNCTION(BlueprintCallable)
	void GateStartMove()
	{
		UPrisonPoleGateEventHandler::Trigger_GateStartMove(this);
	}

	UFUNCTION(BlueprintCallable)
	void GateReachTop()
	{
		UPrisonPoleGateEventHandler::Trigger_GateReachTop(this);
	}

	UFUNCTION(BlueprintCallable)
	void Apply3DTargeting(AHazePlayerCharacter Player)
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		TargetablesComp.TargetingMode.Apply(EPlayerTargetingMode::ThirdPerson, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintCallable)
	void Clear3DTargeting(AHazePlayerCharacter Player)
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		TargetablesComp.TargetingMode.Clear(this);
	}
};

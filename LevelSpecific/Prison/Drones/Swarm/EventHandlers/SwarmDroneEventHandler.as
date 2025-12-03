namespace SwarmDroneLevelEvents
{
	UFUNCTION(BlueprintCallable)
	void OnEnterVentilation(AHazePlayerCharacter Player)
	{
		USwarmDroneEventHandler::Trigger_OnEnterVentilation(Player);
	}

	UFUNCTION(BlueprintCallable)
	void OnExitVentilation(AHazePlayerCharacter Player)
	{
		USwarmDroneEventHandler::Trigger_OnExitVentilation(Player);
	}
}

UCLASS(Abstract)
class USwarmDroneEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	UPROPERTY()
	UPlayerSwarmDroneComponent DroneComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DroneComp = UPlayerSwarmDroneComponent::Get(Player);
		check(DroneComp != nullptr);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSwarmDroneMovement() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSwarmDroneMovement() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSwarmBotMovement() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSwarmBotMovement() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand_Drone() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand_SwarmBots() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTransformToSwarm() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTransformToBall() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterVentilation() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitVentilation() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSwarmHover() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnParachuteCatchWind() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSwarmHover() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwarmDash() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwarmLand() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHackInitiated() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHackDive(FSwarmDroneHijackDiveParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHackStart() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHackStop() {};
}
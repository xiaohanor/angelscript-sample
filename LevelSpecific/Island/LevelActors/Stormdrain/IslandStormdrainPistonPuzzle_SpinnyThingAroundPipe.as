UCLASS(Abstract)
class AIslandStormdrainPistonPuzzle_SpinnyThingAroundPipe : AKineticRotatingActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UIslandStormdrainPistonPuzzle_SpinnyThingAroundPipeEffectHandler::Trigger_OnStart(this);
	}

	UFUNCTION(BlueprintCallable)
	void Pause()
	{
		PauseMovement(this);
		UIslandStormdrainPistonPuzzle_SpinnyThingAroundPipeEffectHandler::Trigger_OnStop(this);
	}

	UFUNCTION(BlueprintCallable)
	void Unpause()
	{
		UnpauseMovement(this);
		UIslandStormdrainPistonPuzzle_SpinnyThingAroundPipeEffectHandler::Trigger_OnStart(this);
	}
}

UCLASS(Abstract)
class UIslandStormdrainPistonPuzzle_SpinnyThingAroundPipeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStart() {}
}
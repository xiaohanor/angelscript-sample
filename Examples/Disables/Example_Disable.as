
class AExampleDisabledActor : AHazeActor
{
	// Add or remove a disable on the actor.
	// Disabling an actor will turn of everything
	void ExampleDisable()
	{
		AddActorDisable(this);
		RemoveActorDisable(this);	
	}

	// Triggered when the first actor disabler is added
	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
	}

	// Triggered when the last actor disabler is removed
	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
	}
}
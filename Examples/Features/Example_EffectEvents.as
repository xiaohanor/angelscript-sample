// Effect Events Example
// See http://wiki.hazelight.se/en/Scripting/Effect-Events
// (Control+Click) on links to open

/**
 * An effect event handler class specifies code to execute when the actor
 * indicates an effect event.
 * 
 * UFUNCTION()s in the class that have an appropriate signature can be
 * triggered for an actor, activating all bound event handlers of that class.
 * 
 * DO NOT USE FOR GAMEPLAY OR LUCAS WILL DRILLBAZZ YOU.
 */
class UExampleEffectEventHandler : UHazeEffectEventHandler
{
	/**
	 * This will automatically get called on bound event handlers when triggered by gameplay code.
	 */
	UFUNCTION(BlueprintEvent)
	void StartWorking()
	{
		Print("Handled event called 'StartWorking' on "+Owner);
	}

	/**
	 * Events can have a single argument with a parameter struct.
	 * The actor must then pass the same parameter struct into PushEvent() for it to be called.
	 */
	UFUNCTION(BlueprintEvent)
	void EventWithParams(FExampleEventHandlerParams EventParams)
	{
		Print("Handled event with params: "+EventParams.EventParamFloat);
	}
}

/**
 * Custom parameter struct used inside an event.
 */
struct FExampleEventHandlerParams
{
	UPROPERTY()
	float EventParamFloat = 1.0;
	UPROPERTY()
	FHitResult EventHit;
}

class AExampleActorWithEffectEvents : AHazeActor
{
	/* Event handlers can be specified as defaults, or added in the actor blueprint to this array */
	default EffectEventHandlers.Add(UExampleEffectEventHandler);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Call an event on all event handlers without providing any parameters
		UExampleEffectEventHandler::Trigger_StartWorking(this);

		// Use a parameter struct to pass data into a specific event
		FExampleEventHandlerParams ExampleParams;
		ExampleParams.EventParamFloat = 4.0;
		UExampleEffectEventHandler::Trigger_EventWithParams(this, ExampleParams);
	}
};
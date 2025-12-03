UCLASS(Abstract)
class UMeltdownScreenWalkStompEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	/**
	 * Called when the player first presses the button for stomping.
	 * This will happen at the start of the stomp animation.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedStomping()
	{
	}

	/**
	 * Called when the stomp is triggered and starts affecting the world.
	 * Happens after the stomp animation has hit the ground.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StompHit()
	{
	}

	/**
	 * Called when the player releases the stomp button and stops affecting the world.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StoppedStomping()
	{
	}
};
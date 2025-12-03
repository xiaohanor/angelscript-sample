/**
 * Split Tooth AI events (non-player controlled half tooth)
 */
UCLASS(Abstract)
class UDentistSplitToothAIEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistSplitToothAI SplitToothAI;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
	}

	/**
	 * Idle means the AI just jumping around semi randomly while waiting for the player to approach
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIdleStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIdleStop() {}

	/**
	 * When the player gets within a certain distance, the AI will be startled
	 * This starts with turning around to face the player
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartledStartTurningAround() {}

	/**
	 * Once the startled AI has turned around, it will perform a scared jump
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartledJump() {}

	/**
	 * Scared is the state after startled where the AI is hopping away quite quickly
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScaredStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnScaredStop() {}

	/**
	 * The player has reached us and we have started being moved towards it to recombine
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecombineStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecombineStop() {}
};
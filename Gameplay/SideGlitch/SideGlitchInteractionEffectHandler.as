struct FSideGlitchInteractionPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USideGlitchInteractionEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	/**
	 * When a player starts interacting with the side story interaction
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnteredInteraction(FSideGlitchInteractionPlayerParams Params)
	{
	}

	/**
	 * When a player stops interacting with the side story interaction
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitedInteraction(FSideGlitchInteractionPlayerParams Params)
	{
	}

	/**
	 * When both players have finished the button hold and they start entering the side story
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersEnteringSideStory()
	{
	}

	/**
	 * When the players exit the side story by completing it
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitSideStoryComplete()
	{
	}

	/**
	 * When the players exit the side story by aborting it from the menu
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitSideStoryAborted()
	{
	}
};
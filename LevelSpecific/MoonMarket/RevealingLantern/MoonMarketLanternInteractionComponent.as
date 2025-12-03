class UMoonMarketLanternInteractionComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams PickupAnim;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	AMoonMarketRevealingLantern Lantern;

	bool bPickingUpLantern = false;

	void StartPickingUpLantern(AMoonMarketRevealingLantern ALantern)
	{
		Lantern = ALantern;
		bPickingUpLantern = true;
	}
};
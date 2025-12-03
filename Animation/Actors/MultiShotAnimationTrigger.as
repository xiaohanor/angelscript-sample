event void FMultiShotAnimationPlayerTriggerEvent(AHazePlayerCharacter Player, AMultiShotAnimationPlayerTrigger Trigger);

class AMultiShotAnimationPlayerTrigger : APlayerTrigger
{
	FMultiShotAnimationPlayerTriggerEvent OnPlayerEnterMultiShotTrigger;
	FMultiShotAnimationPlayerTriggerEvent OnPlayerLeaveMultiShotTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		OnPlayerEnterMultiShotTrigger.Broadcast(Player, this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		OnPlayerLeaveMultiShotTrigger.Broadcast(Player, this);
	}
}
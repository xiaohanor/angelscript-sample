// Any player within this zone will not be considered as a valid target for AI
class APlayerAISafeZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		GentlemanComp.SetInvalidTarget(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		GentlemanComp.ClearInvalidTarget(this);
	}
}
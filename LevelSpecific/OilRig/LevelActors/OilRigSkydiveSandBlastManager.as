class AOilRigSkydiveSandBlastManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UFUNCTION()
	void TriggerSandBlast(AHazePlayerCharacter Player)
	{
		BP_TriggerSandBlast(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_TriggerSandBlast(AHazePlayerCharacter Player) {}
}
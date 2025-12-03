class UGoatBubblePlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UPROPERTY()
	TSubclassOf<AGoatBubbleActor> BubbleClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
}
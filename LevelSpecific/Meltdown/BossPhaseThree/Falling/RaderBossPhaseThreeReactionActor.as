class ARaderBossPhaseThreeReactionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
class AGlitchLoopingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent DefaultSceneRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
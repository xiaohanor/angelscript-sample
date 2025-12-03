class ASummitGongPlatformSimple : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
};
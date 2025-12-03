class ASanctuaryBossInsideAcid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingSceneComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
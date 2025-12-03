class ADesertFishingLure : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USwingPointComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
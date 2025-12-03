class ACrystalGrowth : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCrystalGrowthKillComponent KillComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
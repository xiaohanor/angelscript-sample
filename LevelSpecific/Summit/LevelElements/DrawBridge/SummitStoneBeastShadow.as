class ASummitStoneBeastShadow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
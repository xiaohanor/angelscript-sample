class AMedallionMedallionInsideActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffsetComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
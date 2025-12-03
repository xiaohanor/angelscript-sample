class ASummitLinebanaStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent Fall;

	UPROPERTY(DefaultComponent, Attach = Fall)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Chain;

	UPROPERTY(EditAnywhere)
	AGiantBreakableObject Destruction;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);
	}

};
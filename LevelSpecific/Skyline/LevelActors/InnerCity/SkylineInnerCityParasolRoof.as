class ASkylineInnerCityParasolRoof : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent SceneComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
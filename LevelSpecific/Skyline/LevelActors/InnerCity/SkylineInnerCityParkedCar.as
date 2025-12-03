class ASkylineInnerCityParkedCar : AHazeActor
{
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeComp;

	UPROPERTY(DefaultComponent, Attach = ConeComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent CarMesh;
	
	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	
	}	
}
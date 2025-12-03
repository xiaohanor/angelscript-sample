class ATundra_IcePalace_SlidingPuzzleSpringyPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComp;
	default FauxPhysicsTranslateComp.SpringStrength = 72.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
	default WeightComp.PlayerForce = 1500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};
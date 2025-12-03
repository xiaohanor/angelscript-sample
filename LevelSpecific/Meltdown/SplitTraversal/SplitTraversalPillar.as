class ASplitTraversalPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.SpringStrength = 3.0;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -400.0;
	default TranslateComp.MaxZ = 0.0;
	
	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
	default WeightComp.PlayerImpulseScale = 1.0;
	
	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent Mesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
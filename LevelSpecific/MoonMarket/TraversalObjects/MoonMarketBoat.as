class AMoonMarketBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent RotateComp;
	default RotateComp.SpringStrength = 0.4;
	default RotateComp.ConeAngle = 60.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComp;
	default FauxPhysicsTranslateComp.SpringStrength = 18.0;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComp)
	UStaticMeshComponent BoatMesh;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
	default WeightComp.PlayerForce = 250.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
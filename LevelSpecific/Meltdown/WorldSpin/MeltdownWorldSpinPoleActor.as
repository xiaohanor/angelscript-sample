class AMeltdownWorldSpinPoleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsSplineFollowComponent SplineFollow;

	UPROPERTY(DefaultComponent, Attach = SplineFollow)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	APoleClimbActor Pole;

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent FauxResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
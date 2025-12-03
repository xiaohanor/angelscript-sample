class AMeltdownWorldSpinSeeSaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxRotate;

	UPROPERTY(DefaultComponent, Attach = FauxRotate)
	UFauxPhysicsWeightComponent FauxWeightComp;

	UPROPERTY(DefaultComponent, Attach = FauxWeightComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineComp;

	UPROPERTY(DefaultComponent)
    UMeltdownWorldSpinFauxPhysicsResponseComponent FauxResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
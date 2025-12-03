class ALiftSectionPowerWashTracker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ASplineActor TargetSpline;

	UHazeSplineComponent TargetSplineComp;

	bool bActive;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetSplineComp = TargetSpline.Spline;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
}
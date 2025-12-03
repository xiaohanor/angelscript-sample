class APerchTreeSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	APerchSpline PerchSpline;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase TheDeadTree;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeSplinePoint& Point = PerchSpline.Spline.SplinePoints[1];
		
		FVector SocketLocation = TheDeadTree.GetSocketLocation(n"BigUpperBranch8");

		Point.RelativeLocation = PerchSpline.Spline.WorldTransform.InverseTransformPosition(SocketLocation);

		PerchSpline.Spline.UpdateSpline();

		// PerchSpline.Spline.MarkRenderStateDirty();
	}
};
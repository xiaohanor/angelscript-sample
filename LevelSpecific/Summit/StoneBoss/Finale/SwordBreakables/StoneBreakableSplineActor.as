class AStoneBreakableSplineActor : AStoneBreakableActor
{
	UHazeSplineComponent Spline;

	FSplinePosition SplinePos;

	float Speed = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SplinePos = Spline.GetSplinePositionAtSplineDistance(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(Speed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;

		// Object pool these later
		if (!Spline.IsClosedLoop())
		{
			if (SplinePos.CurrentSplineDistance >= Spline.SplineLength - 1.0)
			{
				DestroyActor();
			}
		}
	}
};
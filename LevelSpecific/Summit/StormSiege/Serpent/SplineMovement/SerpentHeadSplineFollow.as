
asset SerpentHeadSplineFollowSheet of UHazeCapabilitySheet
{
	Components.Add(USerpentHeadSplineFollowComponent);

	Capabilities.Add(USerpentHeadSplineMovementCapability);
	Capabilities.Add(USerpentHeadMovementSpeedCapability);
	Capabilities.Add(USerpentHeadTransitionMoveCapability);
}

class USerpentHeadSplineFollowComponent : USerpentHeadMovementComponentBase
{
	ASerpentHead SerpentHead;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SerpentHead = Cast<ASerpentHead>(Owner);
	}

	//initializes along the closest spline in list
	void InitializeFullSplinePosition() override
	{
		float ClosestDistance = BIG_NUMBER;

		for (ASplineActor Spline : SerpentHead.SplineActors)
		{
			FSplinePosition ClosestPoint = Spline.Spline.GetClosestSplinePositionToWorldLocation(SerpentHead.ActorLocation);
			float DistSq = ClosestPoint.WorldLocation.DistSquared(SerpentHead.ActorLocation);
			if (DistSq < ClosestDistance)
			{
				ClosestDistance = DistSq;
				SerpentHead.CurrentSpline = Spline;
				SerpentHead.CurrentSplinePosition = ClosestPoint;
			}
		}

		SerpentHead.SetActorLocationAndRotation(SerpentHead.CurrentSplinePosition.WorldLocation, SerpentHead.CurrentSplinePosition.WorldRotation);
		SerpentHead.SerpentMovementState = ESerpentMovementState::UseSpline;
	}
}
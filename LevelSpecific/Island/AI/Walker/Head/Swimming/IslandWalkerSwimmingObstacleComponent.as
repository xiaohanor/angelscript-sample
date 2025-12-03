class UIslandWalkerSwimmingObstacleComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float Width = 0.0;

	UPROPERTY(EditAnywhere)
	float AvoidanceRadius = 500.0;

	UPROPERTY(EditAnywhere)
	bool bCanFlyOver = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Make sure we stay at a fixed position in game
		DetachFromParent(true);

		if (!ensure((Owner != nullptr) && (Owner.Level != nullptr) && (Owner.Level.LevelScriptActor != nullptr)))
			return;

		auto Set = UIslandWalkerSwimmingObstacleSetComponent::GetOrCreate(Owner.Level.LevelScriptActor);
		Set.Obstacles.AddUnique(this);
	}

	bool IsObstructing(FVector Start, FVector End) const
	{
		FVector Offset = WorldRotation.RightVector * Width * 0.5;
		FVector Start2D = FVector(Start.X, Start.Y, WorldLocation.Z);
		FVector End2D = FVector(End.X, End.Y, WorldLocation.Z);
		FVector NearestOnLine;
		FVector NearestAlongWidth;
		Math::FindNearestPointsOnLineSegments(Start2D, End2D, WorldLocation + Offset, WorldLocation - Offset, NearestOnLine, NearestAlongWidth);
		if (NearestOnLine.IsWithinDist2D(NearestAlongWidth, AvoidanceRadius))
			return true;
		return false;
	}
	
	bool FindIntersections(FVector Start, FVector End, FVector& OutFirstIntersection, FVector& OutSecondIntersection)
	{
		FVector Start2D = FVector(Start.X, Start.Y, WorldLocation.Z);
		FVector End2D = FVector(End.X, End.Y, WorldLocation.Z);
		FVector Right = RightVector;
		FVector Offset = Right * Width * 0.5;
		FVector RightHub = WorldLocation + Offset;
		FVector LeftHub = WorldLocation - Offset;
		FVector NearestOnLine;
		FVector NearestAlongObstacle;
		Math::FindNearestPointsOnLineSegments(Start2D, End2D, RightHub, LeftHub, NearestOnLine, NearestAlongObstacle);
		if (!NearestOnLine.IsWithinDist2D(NearestAlongObstacle, AvoidanceRadius))
			return false; // No intersections

		OutFirstIntersection = End2D;
		OutSecondIntersection = Start2D;

		if (Start2D.IsInsideTeardrop2D(RightHub, LeftHub, AvoidanceRadius, AvoidanceRadius))
			OutFirstIntersection = Start2D; // Start inside
		if (End2D.IsInsideTeardrop2D(RightHub, LeftHub, AvoidanceRadius, AvoidanceRadius))
			OutSecondIntersection = End2D; // End inside

		FLineSphereIntersection LeftHubIntersects = Math::GetLineSegmentSphereIntersectionPoints(Start2D, End2D, LeftHub, AvoidanceRadius);
		if (LeftHubIntersects.bHasIntersection)
		{
			if (Start.DistSquared2D(LeftHubIntersects.MinIntersection) < Start.DistSquared2D(OutFirstIntersection))
				OutFirstIntersection = LeftHubIntersects.MinIntersection;
			if (Start.DistSquared2D(LeftHubIntersects.MaxIntersection) > Start.DistSquared2D(OutSecondIntersection))
				OutSecondIntersection = LeftHubIntersects.MaxIntersection;
		}

		if (Width > 0.1)
		{
			// Non-circular obstacle, check other capsule end and capsule sides
			FLineSphereIntersection RightHubIntersects = Math::GetLineSegmentSphereIntersectionPoints(Start2D, End2D, RightHub, AvoidanceRadius);
			if (RightHubIntersects.bHasIntersection)
			{
				if (Start.DistSquared2D(RightHubIntersects.MinIntersection) < Start.DistSquared2D(OutFirstIntersection))
					OutFirstIntersection = RightHubIntersects.MinIntersection;
				if (Start.DistSquared2D(RightHubIntersects.MaxIntersection) > Start.DistSquared2D(OutSecondIntersection))
					OutSecondIntersection = RightHubIntersects.MaxIntersection;
			}

			FVector FwdOffset = ForwardVector * AvoidanceRadius;
			FVector FrontIntersection;
			if (FindFrontSideIntersection(Start2D, End2D, FrontIntersection))
			{
				if ((FwdOffset.DotProduct(Start2D - (WorldLocation + FwdOffset)) > 0.0) && 
					Start.DistSquared2D(FrontIntersection) < Start.DistSquared2D(OutFirstIntersection))
					OutFirstIntersection = FrontIntersection; // Line starts on the front side of obstacle and this is closer than previously found intersections
				if ((FwdOffset.DotProduct(End2D - (WorldLocation + FwdOffset)) > 0.0) && 
					Start.DistSquared2D(FrontIntersection) > Start.DistSquared2D(OutSecondIntersection))
					OutSecondIntersection = FrontIntersection; // Line ends on the front side of obstacle and this is further away than previously found intersections
			}
			FVector BackIntersection;
			if (FindBackSideIntersection(Start2D, End2D, BackIntersection))
			{
				if ((FwdOffset.DotProduct(Start2D - (WorldLocation - FwdOffset)) < 0.0) && 
					Start.DistSquared2D(BackIntersection) < Start.DistSquared2D(OutFirstIntersection))
					OutFirstIntersection = BackIntersection; // Line starts on the back side of obstacle and this is closer than previously found intersections
				if ((FwdOffset.DotProduct(End2D - (WorldLocation - FwdOffset)) < 0.0) && 
					Start.DistSquared2D(BackIntersection) > Start.DistSquared2D(OutSecondIntersection))
					OutSecondIntersection = BackIntersection; // Line ends on the back side of obstacle and this is further away than previously found intersections
			}
		}

		// Sanity checks
		check((OutFirstIntersection != End) && (OutSecondIntersection != Start) && (Start.DistSquared2D(OutFirstIntersection) < Start.DistSquared2D(OutSecondIntersection) + 0.1)); 
		return true;		
	}

	bool FindFrontSideIntersection(FVector Start, FVector End, FVector& OutIntersection)
	{
		FVector2D Intersection2D;
		FVector2D Start2D = FVector2D(Start.X, Start.Y);
		FVector2D End2D = FVector2D(End.X, End.Y);
		FVector RightOffset = RightVector * Width * 0.5;
		FVector FwdOffset = ForwardVector * AvoidanceRadius;
		FVector2D OwnLeft = FVector2D(WorldLocation.X - RightOffset.X + FwdOffset.X, WorldLocation.Y - RightOffset.Y + FwdOffset.Y);
		FVector2D OwnRight = FVector2D(WorldLocation.X + RightOffset.X + FwdOffset.X, WorldLocation.Y + RightOffset.Y + FwdOffset.Y);
		if (!Math::IsLineSegmentIntersectingLineSegment2D(Start2D, End2D, OwnRight, OwnLeft, Intersection2D, 0.1))
			return false;
		OutIntersection = FVector(Intersection2D.X, Intersection2D.Y, WorldLocation.Z);
		return true;
	} 

	bool FindBackSideIntersection(FVector Start, FVector End, FVector& OutIntersection)
	{
		FVector2D Intersection2D;
		FVector2D Start2D = FVector2D(Start.X, Start.Y);
		FVector2D End2D = FVector2D(End.X, End.Y);
		FVector RightOffset = RightVector * Width * 0.5;
		FVector BwdOffset = -ForwardVector * AvoidanceRadius;
		FVector2D OwnLeft = FVector2D(WorldLocation.X - RightOffset.X + BwdOffset.X, WorldLocation.Y - RightOffset.Y + BwdOffset.Y);
		FVector2D OwnRight = FVector2D(WorldLocation.X + RightOffset.X + BwdOffset.X, WorldLocation.Y + RightOffset.Y + BwdOffset.Y);
		if (!Math::IsLineSegmentIntersectingLineSegment2D(Start2D, End2D, OwnRight, OwnLeft, Intersection2D, 0.1))
			return false;
		OutIntersection = FVector(Intersection2D.X, Intersection2D.Y, WorldLocation.Z);
		return true;
	} 

	void DebugDraw(FLinearColor Color = FLinearColor::Green, float LineWidth = 10.0, float Duration = 0.0)
	{
		FVector Start = WorldLocation + RightVector * Width * 0.5 + FVector(0.0, 0.0, 200.0);
		FVector End = WorldLocation - RightVector * Width * 0.5 + FVector(0.0, 0.0, 200.0);
		ShapeDebug::DrawTeardrop(Start, End, AvoidanceRadius, AvoidanceRadius, Color, LineWidth, Duration);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector Offset = WorldRotation.RightVector * Width * 0.5;
		ShapeDebug::DrawTeardrop(WorldLocation + Offset, WorldLocation - Offset, AvoidanceRadius, AvoidanceRadius, FLinearColor::Red, 10.0);
	}
#endif
}

class UIslandWalkerSwimmingObstacleSetComponent : UActorComponent
{
	TArray<UIslandWalkerSwimmingObstacleComponent> Obstacles;
}


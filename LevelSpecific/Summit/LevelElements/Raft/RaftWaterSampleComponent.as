class URaftWaterSampleComponent : USceneComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	FVector GetWaterLocation(UHazeSplineComponent Spline)
	{
		FSplinePosition SplinePos = Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
		FVector PlaneLoc = WorldLocation.PointPlaneProject(SplinePos.WorldLocation, SplinePos.WorldUpVector);
		return PlaneLoc;
	}

	FVector GetClosestWaterPointToLine(UHazeSplineComponent Spline, FVector WorldLineStart, FVector WorldLineEnd)
	{
		FSplinePosition SplinePos = Spline.GetClosestSplinePositionToLineSegment(WorldLineStart, WorldLineEnd);
		FVector PlaneLoc = WorldLocation.PointPlaneProject(SplinePos.WorldLocation, SplinePos.WorldUpVector);
		return PlaneLoc;
	}

	float GetClosestWaterHeightAlongLine(UHazeSplineComponent Spline, FVector WorldLineStart, FVector WorldLineEnd)
	{
		float Height = GetClosestWaterPointToLine(Spline, WorldLineStart, WorldLineEnd).Z;
		return Height;
	}

	float GetHeightAtComponentLocation(UHazeSplineComponent Spline)
	{
		float Height = GetWaterLocation(Spline).Z;
		return Height;
	}

	bool HasWaterBellow(UHazeSplineComponent Spline, float Threshold)
	{
		float Height = GetWaterLocation(Spline).Z;
		float Diff = WorldLocation.Z - Height;
		bool bIsTooFarDown = Diff > Threshold;
		return !bIsTooFarDown;
	}
};
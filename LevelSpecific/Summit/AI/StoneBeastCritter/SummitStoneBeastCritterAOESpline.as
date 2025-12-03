class ASummitStoneBeastCritterAOESpline : ASplineActor
{
	UPROPERTY(EditAnywhere)
	float SpawnOffset = 200;

	UPROPERTY(EditAnywhere)
	float VisualizeRadius = 250;

	UPROPERTY(EditAnywhere)
	bool bVisualize = false;

	default Spline.EditingSettings.SplineColor = FLinearColor::LucBlue;

	FVector GetClosestSpawnLocationToDesiredLocation(FVector DesiredLocation)
	{
		FSplinePosition SplinePos = Spline.GetClosestSplinePositionToWorldLocation(DesiredLocation);
		FVector Dir;
		float Length = 0;
		(DesiredLocation - SplinePos.WorldLocation).ToDirectionAndLength(Dir, Length);
		float Dot = Dir.DotProduct(SplinePos.WorldRightVector);
		FVector NewLocation = DesiredLocation;
		if ((Dot >= 0 && Length < SpawnOffset) || Dot < 0)
			NewLocation = SplinePos.WorldLocation + SplinePos.WorldRightVector * SpawnOffset;

		NewLocation.Z = DesiredLocation.Z;
		return NewLocation;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (!bVisualize)
			return;
		
		float CurrentDistance = 0;
		while (CurrentDistance < Spline.SplineLength)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(CurrentDistance);
			FVector Location = SplinePos.WorldLocation + SplinePos.WorldRightVector * SpawnOffset;
			Debug::DrawDebugCircle(Location, VisualizeRadius, 20, FLinearColor::Green);
			Debug::DrawDebugArrow(SplinePos.WorldLocation, Location, 20, FLinearColor::Green);
			CurrentDistance += Math::Max(VisualizeRadius, 10);
		}
	}
#endif
};
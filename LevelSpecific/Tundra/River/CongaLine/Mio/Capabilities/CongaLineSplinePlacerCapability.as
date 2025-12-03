/**
 * This capability places and updates the conga line spline that the dancers use as targets
 */
class UCongaLineSplinePlacerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);

	default TickGroup = EHazeTickGroup::Gameplay;

	UCongaLinePlayerComponent CongaComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CongaComp = UCongaLinePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CongaComp.ResetSpline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// To prevent getting an insane amount of points, we only place one down every 200 units
		// To keep the spline following the player, we update the last point to always be on the player
		if(CongaComp.DistanceToLastPlacedPoint() > 200)
			CongaComp.PlacePointAtCurrentLocation();
		else
			CongaComp.UpdateLastPointToCurrentLocation();

		// Start removing points if it's too long
		while(CongaComp.Spline.Length > CongaLine::MaxSplineLength)
		{
			if(CongaComp.SplineHitWallLocations.Num() > 0)
			{
				FVector DirToWallHitPoint = (CongaComp.SplineHitWallLocations[0] - CongaComp.Spline.Points[0]).GetSafeNormal();
				FVector DirToNext = CongaComp.Spline.GetDirectionAtSplinePointIndex(0);
				if(DirToWallHitPoint.DotProduct(DirToNext) < 0)
				{
					CongaComp.RemoveWallHitPoint(0);
				}
			}

			CongaComp.Spline.RemovePoint(0);
		}

		// CongaComp.Spline.DrawDebugSpline();

		// for(int i = 0; i < CongaLine::MaxDancers; i++)
		// {
		// 	FVector Vector = CongaComp.GetTargetDanceLocation(i);
		// 	Debug::DrawDebugPoint(Vector, 50, FLinearColor::Red);
		// }
	}
};
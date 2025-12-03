class ACoastJetskiSplineActor : ASplineActor
{
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeScale = CoastJetskiSpline::WidthScale;
	default Spline.EditingSettings.SplineColor = FLinearColor::LucBlue;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UHazeSplineComponent Rail;
	float StartAlongRail = 0.0;
	float EndAlongRail = 0.0;

	void MatchToRail(UHazeSplineComponent RailSpline)
	{
		if (RailSpline == nullptr)
			return;
		Rail = RailSpline;
		StartAlongRail = RailSpline.GetClosestSplineDistanceToWorldLocation(Spline.GetWorldLocationAtSplineFraction(0.0));
		EndAlongRail = RailSpline.GetClosestSplineDistanceToWorldLocation(Spline.GetWorldLocationAtSplineFraction(1.0));
	}
}

namespace CoastJetskiSpline
{
	const float WidthScale = 100.0;
}

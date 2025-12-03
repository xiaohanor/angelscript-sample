
class AExample_RuntimeSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Movable;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "RuntimeSpline";
#endif

	// this is just here so we can visualize the spline while in editor
	UPROPERTY(DefaultComponent)
	UVisualizeRuntimeSplineComponent DummyComp;
}

class UVisualizeRuntimeSplineComponent : UActorComponent
{
	// for visualizing only
	default bTickInEditor = true;

	// you can save the spline if you only intend to update the spline 
	// properties sometimes, but still want to read from it often
	FHazeRuntimeSpline SavedSpline;

	UFUNCTION(BlueprintOverride)
	void Tick(float Dt)
	{
		// totally fine to create a new spline every frame.
		FHazeRuntimeSpline Spline;

		// we want our points to be relative to the actor, for this example. 
		const FVector O = Owner.GetActorLocation();

		TArray<FVector> DesiredSplinePoints;
		DesiredSplinePoints.Reserve(4);
		DesiredSplinePoints.Add(O + FVector(156.0, 1238.0, 1000.0));
		DesiredSplinePoints.Add(O + FVector(1500.0, 200.0, 330.0));
		DesiredSplinePoints.Add(O + FVector(350.0, -400.0, 150.0));
		DesiredSplinePoints.Add(O + FVector(450.0, 100.0, 50.0));

		// you can assign the points directly
		Spline.Points = DesiredSplinePoints;

		// you can add to the Spline.Points array by using the following function as well
		Spline.AddPoint(O + FVector(50.0, -50.0, 400.0));

		// You can also insert to the Spline.Points array by using 
		Spline.InsertPoint(O + FVector(0.0, 400.0, 50.0), Spline.Points.Num()-1);

		float OscillatingAlpha = Math::MakePulsatingValue(Time::GetGameTimeSeconds(), 0.2);  
		// OscillatingAlpha = 0.0;

		// adding a world offset can either be applied to a specific point
		Spline.OffsetPoint(FVector(OscillatingAlpha*300.0), 3);
		// or all points
		Spline.OffsetPoints(FVector(OscillatingAlpha*-150.0));

		// You can straighten the spline by changing the Tension.
		// ranges from 0 to 1. 0 == Spline, 1 == Straight lines
		Spline.Tension = OscillatingAlpha;

		// we can loop the spline by duplicating the first point in the array and adding it to the end.
		Spline.Looping = false;

		/**
		 * We can override the exit and start tangents by suppling the system with
		 * world locations, instead of direction, which the spline will try to bend towards.
		 */
		if(Game::Mio != nullptr)
			Spline.SetCustomEnterTangentPoint(Game::Mio.GetActorCenterLocation());
		if(Game::Zoe != nullptr)
			Spline.SetCustomExitTangentPoint(Game::Zoe.GetActorCenterLocation());
		/*
		* (advanced)
		* 
		* Changes how (all) spline tangents are automatically calculated for each point. Range is 0 to 1.
		*
		* (note that changing this value will cause the spline to deviate from any CustomTangentPoints you might have set)
		*
		* Useful if you want to change the entire spline shape but don't really care about
		* where the Enter and Exit tangents are pointing towards. 
		* 
		* It controls how early the spline starts curving in order to thread the points nicely.
		* 
		* 1	==	Will curve the spline as much as possible in order to produce smooth transitions
		*			between points. It will reduces sharp turns and prevent knots/loops from forming.
		*			Imagine a big thick stiff rope which very hard to bend. This settings will
		*			ensure that any _enter_ or _exit_ tangents are pointing in the direction
		*			that the user wants.
		*			
		* 0.5	==	produces ideal spline curvature. It will have the spline curve itself just enough
		*			to thread the points without causing it to overshoot (to much) or create knots.
		*			
		* 0	==  will curve as little as possible. This might create knots/loops and overshooting if
		*			points are placed close together, in such a way that it forces the spline
		*			to make sharp turns in order to thread the points nicely.
		*
		* The Difference is most notable when you have points close together and positioned in such 
		* a way that it makes it hard to thread them smoothly without overshooting and creating knots.
		*/ 
		Spline.CustomCurvature = OscillatingAlpha;

		const float PanningTime = 1.0 * Time::GetGameTimeSeconds();
		const FVector SmoothRandomDirection = FVector(
			Math::PerlinNoise1D(PanningTime * 0.01),
			Math::PerlinNoise1D(PanningTime * 0.1),
			Math::PerlinNoise1D(PanningTime)
		);

		/**
		 * The spline also supports rotations. Up directions for the spline points can be set which
		 * will then be used in combination with the spline tangents to create rotations on each spline points.
		 */
		Spline.SetUpDirection(SmoothRandomDirection, 2);

		DrawDebugSpline(Spline);
	}

	void DrawDebugSpline(FHazeRuntimeSpline& InSpline)
	{
		// start spline point
		Debug::DrawDebugPoint(InSpline.Points[0], 25.0, FLinearColor::Green);

		// end spline point
		Debug::DrawDebugPoint(InSpline.Points.Last(), 25.0, FLinearColor::Green);

		// draw all spline points that we've assigned
		for(FVector P : InSpline.Points)
			Debug::DrawDebugPoint(P, 15.0, FLinearColor::Purple, 0.0, true);

		// Find 150 uniformerly distributed locations on the spline
		TArray<FVector> Locations;
		InSpline.GetLocations(Locations, 150);
		TArray<FRotator> Rotations;
		InSpline.GetRotations(Rotations, 150);

		// Draw lines between the 150 points 
		for(int i = 1; i < Locations.Num(); ++i)
		{
			Debug::DrawDebugLine(Locations[i-1], Locations[i], FLinearColor::Black, 5.0);
			Debug::DrawDebugCoordinateSystem(Locations[i], Rotations[i], 50);
		}

		// Draw a location moving along the spline based on elasped time
		Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), 20.0, FLinearColor::White);

	}

}
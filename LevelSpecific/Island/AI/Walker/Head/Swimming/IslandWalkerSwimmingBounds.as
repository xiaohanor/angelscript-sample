class AIslandWalkerSwimmingBounds : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.SplineSettings.bClosedLoop = true;
	default Spline.EditingSettings.SplineColor = FLinearColor::LucBlue;
	default Spline.SplinePoints.SetNum(8);
	default Spline.SplinePoints[0] = FHazeSplinePoint(FVector(3200.0, 0.0, 0.0));
	default Spline.SplinePoints[1] = FHazeSplinePoint(FVector(2300.0, 1800.0, 0.0));
	default Spline.SplinePoints[2] = FHazeSplinePoint(FVector(-2300.0, 1800.0, 0.0));
	default Spline.SplinePoints[3] = FHazeSplinePoint(FVector(-2500.0, 1600.0, 0.0));
	default Spline.SplinePoints[4] = FHazeSplinePoint(FVector(-3200.0, -0.0, 0.0));
	default Spline.SplinePoints[5] = FHazeSplinePoint(FVector(-2300.0, -1800.0, 0.0));
	default Spline.SplinePoints[6] = FHazeSplinePoint(FVector(2300.0, -1800.0, 0.0));
	default Spline.SplinePoints[7] = FHazeSplinePoint(FVector(2500.0, -1600.0, 0.0));

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "WindManager";
	default Billboard.WorldScale3D = FVector(1.0); 
#endif	
}

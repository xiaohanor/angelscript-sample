class ASanctuarySnakeBurrowTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSplineComponent Spline;
	default Spline.SplinePoints.Reset();
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(0.0, 0.0, 0.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(200.0, 0.0, 100.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(600.0, 0.0, 700.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(1000.0, 0.0, 0.0)));
	default Spline.SplinePoints.Add(FHazeSplinePoint(FVector(1000.0, 0.0, -5000.0)));

	UPROPERTY(DefaultComponent)
	USanctuarySnakeSplineEffectComponent SplineEffectComponent;
	default SplineEffectComponent.Effects.Reset();
	default SplineEffectComponent.Effects.Add(FSanctuarySnakeSplineEffectData(3.0));
}
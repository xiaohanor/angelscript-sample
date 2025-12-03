class USanctuaryBoatStreamSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBoatStreamSplineVisualizerComponent;

	bool bIsHandleSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto BoatStreamSpline = Cast<ASanctuaryBoatStreamSpline>(InComponent.Owner);
	}
}

class USanctuaryBoatStreamSplineVisualizerComponent : UHazeEditorRenderedComponent
{
	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		auto BoatStreamSpline = Cast<ASanctuaryBoatStreamSpline>(Owner);
		if (BoatStreamSpline == nullptr)
			return;

		float Thickness = 5.0;
		FLinearColor Color = FLinearColor::Blue;

		FTransform Transform = BoatStreamSpline.ActorTransform;

		SetActorHitProxy();
//		DrawWireBox(BoatStreamSpline.Volume.WorldLocation, BoatStreamSpline.Volume.BoxExtent, BoatStreamSpline.Volume.ComponentQuat, Color, Thickness);
		DrawDebugSplineLine(BoatStreamSpline.Spline, -FVector::RightVector * BoatStreamSpline.BaseWidth, Color);
		DrawDebugSplineLine(BoatStreamSpline.Spline, FVector::RightVector * BoatStreamSpline.BaseWidth, Color);
		ClearHitProxy();
#endif
	}

	void DrawDebugSplineLine(UHazeSplineComponent Spline, FVector Offset = FVector::ZeroVector, FLinearColor Color = FLinearColor::Blue)
	{
		float SegmentLenght = 50.0;
		int Segments = Math::FloorToInt(Spline.SplineLength / SegmentLenght);
		SegmentLenght = Spline.SplineLength / Segments;

		for (int i = 0; i < Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldTransformAtSplineDistance(i * SegmentLenght).TransformPosition(Offset);
			LineEnd = Spline.GetWorldTransformAtSplineDistance((i + 1) * SegmentLenght).TransformPosition(Offset);
			DrawLine(LineStart, LineEnd, Color, 10.0);
		}
	}
}
UCLASS(Abstract)
class ASanctuaryBoatStreamSpline : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.SplinePoints[1].RelativeLocation = FVector::ForwardVector * 100.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent Volume;
	default Volume.bVisible = false;
	default Volume.bGenerateOverlapEvents = false;
	default Volume.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBoatStreamSplineVisualizerComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	float Force = 500.0;

	UPROPERTY(EditAnywhere)
	float BaseWidth = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find the widest part of the spline
		float MaxScale = 0.0;
		for (auto SplinePoint : Spline.SplinePoints)
		{
			float SplinePointMaxScale = Math::Max(SplinePoint.RelativeScale3D.Y, SplinePoint.RelativeScale3D.Z);
			if (SplinePointMaxScale > MaxScale)
				MaxScale = SplinePointMaxScale;
		}

		// Add margin to trigger based on widest part
		Spline.PositionBoxComponentToContainEntireSpline(Volume, MaxScale * BaseWidth);
	}
};
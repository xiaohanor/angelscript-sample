
class USpotSoundSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USpotSoundSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto SplineComponent = Cast<USpotSoundSplineComponent>(Component);
		if (SplineComponent == nullptr)
			return;
		
		if (SplineComponent.SplineComponent == nullptr)
			return;
		
		const auto& Points = SplineComponent.SplineComponent.SplinePoints;

		if (Points.Num() > 1)
		{
			DrawPoint(SplineComponent.SplineComponent.WorldTransform.TransformPosition(Points[0].RelativeLocation), FLinearColor::Green, 50);
			DrawPoint(SplineComponent.SplineComponent.WorldTransform.TransformPosition(Points.Last().RelativeLocation), FLinearColor::Red, 50);
		}
		
	}
}
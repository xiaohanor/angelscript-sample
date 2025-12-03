class UIslandDroidZiplinePatrolSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandDroidZiplinePatrolSplineVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto PatrolSpline = Cast<AIslandDroidZiplinePatrolSpline>(Component.Owner);

		const float SplineLength = PatrolSpline.Spline.GetSplineLength();
		const FVector StartPoint = PatrolSpline.Spline.GetWorldLocationAtSplineDistance(0.0);
		const FVector EndPoint = PatrolSpline.Spline.GetWorldLocationAtSplineDistance(SplineLength);

		DrawWireSphere(StartPoint, 40.0, FLinearColor::Green, 5);
		DrawWorldString("Start", StartPoint, FLinearColor::Green, 1.5);

		DrawWireSphere(EndPoint, 40.0, FLinearColor::Red, 5);
		DrawWorldString("End", EndPoint, FLinearColor::Red, 1.5);
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandDroidZiplinePatrolSplineVisualizerComponent : UActorComponent
{

}

class AIslandDroidZiplinePatrolSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UIslandDroidZiplinePatrolSplineVisualizerComponent VisualizerComponent;
}
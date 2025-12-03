class UMoonMarketMothSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMoonMarketMothSplineVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spline = Cast<AMoonMarketMothSpline>(Component.Owner);

		const float SplineLength = Spline.Spline.GetSplineLength();
		const FVector StartPoint = Spline.Spline.GetWorldLocationAtSplineDistance(0.0);
		const FVector EndPoint = Spline.Spline.GetWorldLocationAtSplineDistance(SplineLength);

		DrawWireSphere(StartPoint, 40.0, FLinearColor::Green, 5);
		DrawWorldString("Start", StartPoint, FLinearColor::Green, 1.5);

		DrawWireSphere(EndPoint, 40.0, FLinearColor::Red, 5);
		DrawWorldString("End", EndPoint, FLinearColor::Red, 1.5);

		float CurrentPoint = 0.0;
		while(CurrentPoint < SplineLength - KINDA_SMALL_NUMBER)
		{
			float NextPoint = CurrentPoint + 200.0;
			if(NextPoint > SplineLength)
				NextPoint = SplineLength;

			FTransform CurrentTransform = Spline.Spline.GetWorldTransformAtSplineDistance(CurrentPoint);
			FTransform NextTransform = Spline.Spline.GetWorldTransformAtSplineDistance(NextPoint);

			FVector LeftOrigin = CurrentTransform.Location - CurrentTransform.Rotation.RightVector * Spline.MaxSidewaysDistance;
			FVector RightOrigin = CurrentTransform.Location + CurrentTransform.Rotation.RightVector * Spline.MaxSidewaysDistance;

			FVector LeftTarget = NextTransform.Location - NextTransform.Rotation.RightVector * Spline.MaxSidewaysDistance;
			FVector RightTarget = NextTransform.Location + NextTransform.Rotation.RightVector * Spline.MaxSidewaysDistance;

			DrawLine(LeftOrigin, LeftTarget, FLinearColor::Green);
			DrawLine(RightOrigin, RightTarget, FLinearColor::Green);

			CurrentPoint = NextPoint;
		}
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UMoonMarketMothSplineVisualizerComponent : UActorComponent
{

}

class AMoonMarketMothSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UMoonMarketMothSplineVisualizerComponent VisualizerComponent;

	UPROPERTY(DefaultComponent, NotEditable)
	USceneComponent CameraFocusComponent;

	/* Player can only travel sideways this distance away from the spline at maximum  */
	UPROPERTY(EditAnywhere)
	float MaxSidewaysDistance = 800.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CameraFocusComponent.SetWorldLocation(Spline.GetWorldLocationAtSplineFraction(1));
	}
}


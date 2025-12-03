class UIslandDroidZiplineZiplineSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandDroidZiplineZiplineSplineVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ZiplineSpline = Cast<AIslandDroidZiplineZiplineSpline>(Component.Owner);

		const float SplineLength = ZiplineSpline.Spline.GetSplineLength();
		const FVector StartPoint = ZiplineSpline.Spline.GetWorldLocationAtSplineDistance(0.0);
		const FVector EndPoint = ZiplineSpline.Spline.GetWorldLocationAtSplineDistance(SplineLength);

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

			FTransform CurrentTransform = ZiplineSpline.Spline.GetWorldTransformAtSplineDistance(CurrentPoint);
			FTransform NextTransform = ZiplineSpline.Spline.GetWorldTransformAtSplineDistance(NextPoint);

			FVector LeftOrigin = CurrentTransform.Location - CurrentTransform.Rotation.RightVector * ZiplineSpline.MaxSidewaysDistance * CurrentTransform.Scale3D.Y;
			FVector RightOrigin = CurrentTransform.Location + CurrentTransform.Rotation.RightVector * ZiplineSpline.MaxSidewaysDistance * CurrentTransform.Scale3D.Y;

			FVector LeftTarget = NextTransform.Location - NextTransform.Rotation.RightVector * ZiplineSpline.MaxSidewaysDistance * NextTransform.Scale3D.Y;
			FVector RightTarget = NextTransform.Location + NextTransform.Rotation.RightVector * ZiplineSpline.MaxSidewaysDistance * NextTransform.Scale3D.Y;

			DrawLine(LeftOrigin, LeftTarget, FLinearColor::Green);
			DrawLine(RightOrigin, RightTarget, FLinearColor::Green);

			CurrentPoint = NextPoint;
		}
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandDroidZiplineZiplineSplineVisualizerComponent : UActorComponent
{

}

class AIslandDroidZiplineZiplineSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UIslandDroidZiplineZiplineSplineVisualizerComponent VisualizerComponent;

	/* Player can only travel sideways this distance away from the spline at maximum  */
	UPROPERTY(EditAnywhere)
	float MaxSidewaysDistance = 1500.0;

	/** y axis represents the speed multiplier depending on the x axis which represents the alpha of how far away you have moved sideways.
	* x: 0 is no sideways deviation, x: 1 means MaxSidewaysDistance */
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve SidewaysSpeedCurve;
	default SidewaysSpeedCurve.AddDefaultKey(0.0, 1.0);
	default SidewaysSpeedCurve.AddDefaultKey(1.0, 0.0);
}
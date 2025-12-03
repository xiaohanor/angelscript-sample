UCLASS(NotBlueprintable)
class AGravityBikeFreeQuarterPipeSplineActor : ASplineActor
{
	UPROPERTY(EditInstanceOnly)
	APropLine CopyPropLine;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "CopyPropLine != nullptr"))
	bool bAutoCopyPropLine = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "CopyPropLine != nullptr"))
	FVector CopyRelativeOffset;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeFreeQuarterPipeSplineComponent QuarterPipeSplineComp;
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(bAutoCopyPropLine)
			CopyFromPropLine();
	}

	UFUNCTION(CallInEditor)
	private void CopyFromPropLine()
	{
		if(CopyPropLine == nullptr)
			return;

		SetActorTransform(CopyPropLine.ActorTransform);
		auto CopySpline = Spline::GetGameplaySpline(CopyPropLine, this);

		if(CopySpline == nullptr)
			return;

		Spline.Modify();

		Spline.SplinePoints = CopySpline.SplinePoints;
		
		for(int i = 0; i < Spline.SplinePoints.Num(); i++)
		{
			float DistanceAlongSpline = Spline.GetSplineDistanceAtSplinePointIndex(i);
			const FTransform SplinePointTransform = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
			FVector WorldLocation = SplinePointTransform.TransformVectorNoScale(CopyRelativeOffset);
			Spline.SplinePoints[i].RelativeLocation = CopySpline.SplinePoints[i].RelativeLocation + ActorTransform.InverseTransformVectorNoScale(WorldLocation);
		}

		Spline.UpdateSpline();
	}
#endif
};

UCLASS(NotBlueprintable)
class UGravityBikeFreeQuarterPipeSplineComponent : UActorComponent
{
}

class UGravityBikeFreeQuarterPipeSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeFreeQuarterPipeSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto QuarterPipeSpline = Cast<AGravityBikeFreeQuarterPipeSplineActor>(Component.Owner);
		if(QuarterPipeSpline == nullptr)
			return;

		if(QuarterPipeSpline.Spline == nullptr)
			return;

		if(QuarterPipeSpline.Spline.SplinePoints.Num() < 2)
			return;

		float DistanceAlongSpline = 0;
		while(DistanceAlongSpline < QuarterPipeSpline.Spline.SplineLength)
		{
			FTransform SplineTransform = QuarterPipeSpline.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
			DrawArrow(SplineTransform.Location, SplineTransform.Location + FVector::UpVector * 500, FLinearColor::Blue, 20, 30);
			DrawArrow(SplineTransform.Location, SplineTransform.Location + SplineTransform.Rotation.RightVector * 500, FLinearColor::Red, 20, 30);
			DistanceAlongSpline += 2000;
		}
	}
}
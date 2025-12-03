/**
 * Used to define where the Skipping Stones can bounce on water.
 * Anything on the right of this spline is considered water.
 */
UCLASS(NotBlueprintable)
class ASkippingStonesWaterSpline : ASplineActor
{
#if EDITOR
	default Spline.EditingSettings.SplineColor = FLinearColor::LucBlue;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		for(FHazeSplinePoint& SplinePoint : Spline.SplinePoints)
		{
			SplinePoint.RelativeLocation.Z = 0;
			SplinePoint.RelativeRotation = FQuat::MakeFromZX(FVector::UpVector, SplinePoint.RelativeRotation.ForwardVector);
		}

		Spline.UpdateSpline();
	}
#endif
};
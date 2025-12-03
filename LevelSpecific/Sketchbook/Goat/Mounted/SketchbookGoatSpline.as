UCLASS(NotBlueprintable)
class ASketchbookGoatSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	bool bAutoSnapAllPoints = false;

	UPROPERTY(EditInstanceOnly)
	bool bCustomSplineUp = false;

	UPROPERTY(EditInstanceOnly)
	bool bAlignGravityWithSplineUp = true;

	UPROPERTY(EditInstanceOnly)
	bool bAllowJumping = true;

	UPROPERTY(EditInstanceOnly)
	bool bAllowRespawn = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bCustomSplineUp", EditConditionHides))
	TSoftObjectPtr<AActor> OrientSplineUpTowards = nullptr;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bCustomSplineUp && OrientSplineUpTowards == nullptr", EditConditionHides))
	FVector CustomSplineUp = FVector::UpVector;

	UPROPERTY(DefaultComponent, ShowOnActor, Category = "Audio")
	UGoatSplineMovementAudioComponent GoatSplineAudioComp;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SetActorRotation(FRotator(ActorRotation.Pitch, -90, ActorRotation.Roll));
		FVector Location = ActorLocation;
		Location.X = 0;
		SetActorLocation(Location);

		// if(bAutoSnapAllPoints)
		// {
		// 	for(auto& Point : Spline.SplinePoints)
		// 	{
		// 		Point.RelativeLocation.Y = 0;
		// 	}
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float Distance = 0;
		while(Distance < Spline.SplineLength)
		{
			FVector Location = Spline.GetWorldLocationAtSplineDistance(Distance);
			FVector SplineUp = GetSplineUpAtDistanceAlongSpline(Distance);
			Debug::DrawDebugDirectionArrow(Location, SplineUp, 100);
			Distance += 100;
		}
	}
#endif

	FVector GetSplineUpAtDistanceAlongSpline(float DistanceAlongSpline) const
	{
		if(!bCustomSplineUp)
			return Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline).UpVector;

		if(OrientSplineUpTowards != nullptr)
		{
			FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
			FVector ToTarget = OrientSplineUpTowards.Get().ActorLocation - SplineTransform.Location;
			ToTarget.X = 0;
			FVector Forward = SplineTransform.Rotation.ForwardVector;
			Forward.X = 0;
			return FQuat::MakeFromXZ(Forward, ToTarget).UpVector;
		}
		else
		{
			return CustomSplineUp.GetSafeNormal();
		}
	}
};

namespace Sketchbook::Goat
{
	FSplinePosition GetClosestSplinePosition(FVector Location)
	{
		TArray<ASketchbookGoatSpline> Splines = TListedActors<ASketchbookGoatSpline>().Array;
		FSplinePosition ClosestSplinePosition;
		float ClosestDistance = BIG_NUMBER;

		for(auto Spline : Splines)
		{
			FSplinePosition ClosestPoint = Spline.Spline.GetClosestSplinePositionToWorldLocation(Location);
			float Distance = ClosestPoint.WorldLocation.DistSquared(Location);
			if(Distance < ClosestDistance)
			{
				ClosestSplinePosition = ClosestPoint;
				ClosestDistance = Distance;
			}
		}

		return ClosestSplinePosition;
	}

	ASketchbookGoatSpline GetClosestSpline(FVector Location)
	{
		FSplinePosition ClosestSplinePosition = GetClosestSplinePosition(Location);
		if(ClosestSplinePosition.CurrentSpline == nullptr)
			return nullptr;

		return Cast<ASketchbookGoatSpline>(ClosestSplinePosition.CurrentSpline.Owner);
	}
}
class USkylineBossTankSplineFollowComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	AActor StartSpline;

	UHazeSplineComponent CurrentSpline;

	float PushDistance = 8000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FollowSpline(StartSpline);
	}

	void FollowSpline(AActor ActorWithSpline)
	{
		if (ActorWithSpline == nullptr)
			return;

		auto Spline = UHazeSplineComponent::Get(ActorWithSpline);

		if (Spline == nullptr)
			return;

		CurrentSpline = Spline;
	}

	FVector GetTargetOnSpline()
	{
		if (CurrentSpline == nullptr)
			return FVector::ZeroVector;

		auto SplinePosition = CurrentSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);

		if (Owner.ActorLocation.Distance(SplinePosition.WorldLocation) < PushDistance)
		{
			FVector ToTarget = SplinePosition.WorldLocation - Owner.ActorLocation;

			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToTarget, FLinearColor::Green, 200.0, 0.0);

			float Turn = Owner.ActorTransform.InverseTransformPositionNoScale(SplinePosition.WorldLocation).Y;

			PrintToScreen("Turn: " + Turn, 0.0, FLinearColor::Green);

			SplinePosition.Move(Turn * PushDistance);

//			float Dot = Owner.ActorForwardVector.DotProduct(ToTarget.SafeNormal);
//			SplinePosition.M
		}

		Debug::DrawDebugPoint(SplinePosition.WorldLocation, 50.0, FLinearColor::Red, 0.0);

		return SplinePosition.WorldLocation;			
	}
};
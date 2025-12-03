event void FOnBattlefieldReachedSplineEnd();

class UBattlefieldSplineFollowComponent : UActorComponent
{
	UPROPERTY()
	FOnBattlefieldReachedSplineEnd OnBattlefieldReachedSplineEnd;

	UPROPERTY(Category = "Setup", EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(Category = "Setup", EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(Category = "Setup", EditAnywhere)
	bool bFollowRotation = true;

	UPROPERTY(Category = "Setup", EditAnywhere)
	float FollowSpeed = 11000.0;

	UHazeSplineComponent SplineComp;

	FSplinePosition SplinePos;

	bool bReachedEndEventFired;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);

		if (!bStartActive)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(FollowSpeed * DeltaSeconds);
		
		Owner.ActorLocation = SplinePos.WorldLocation;

		if (bFollowRotation)
			Owner.ActorRotation = SplinePos.WorldRotation.Rotator();

		if (SplinePos.CurrentSplineDistance == SplineComp.SplineLength && !SplineComp.IsClosedLoop() && !bReachedEndEventFired)
		{
			OnBattlefieldReachedSplineEnd.Broadcast();
			bReachedEndEventFired = true;
		}
	}

	UFUNCTION()
	void ActivateSplineMovement()
	{
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void SetFinalPosition()
	{
		Owner.ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(SplineComp.SplineLength);
		Owner.ActorRotation = SplineComp.GetWorldRotationAtSplineDistance(SplineComp.SplineLength).Rotator();
	}
}
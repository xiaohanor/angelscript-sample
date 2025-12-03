event void FOnJetskiEventReachedSplineEnd();

class UJetskiEventSplineFollowComponent : UActorComponent
{
	UPROPERTY()
	FOnJetskiEventReachedSplineEnd OnJetskiEventReachedSplineEnd;

	UPROPERTY(Category = "Setup", EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(Category = "Setup", EditAnywhere)
	bool bStartActive = true;

	UPROPERTY(Category = "Setup", EditAnywhere)
	bool bFollowRotation = true;

	UPROPERTY(Category = "Setup", EditAnywhere)
	float FollowSpeed = 11000.0;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "100.0"), Category = "Debug", EditAnywhere)
	float PreviewValue = 0.0;

	UHazeSplineComponent SplineComp;

	FSplinePosition SplinePos;

	bool bReachedEndEventFired;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		SplinePos = SplineComp.GetSplinePositionAtSplineDistance(0.0);
		Owner.ActorLocation = SplinePos.WorldLocation;

		if (!bStartActive)
			SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(Spline == nullptr || Spline.Spline == nullptr)
			return;
		
		FVector PreviewLocation = Spline.Spline.GetWorldLocationAtSplineDistance(Spline.Spline.SplineLength * (PreviewValue * 0.01));
		Owner.ActorLocation = PreviewLocation;
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
			OnJetskiEventReachedSplineEnd.Broadcast();
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
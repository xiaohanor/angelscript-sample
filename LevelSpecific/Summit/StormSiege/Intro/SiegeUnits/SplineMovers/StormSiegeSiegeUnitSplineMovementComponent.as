class UStormSiegeUnitSplineMovementComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	ASplineActor Spline;
	UHazeSplineComponent SplineComp;

	float OffsetAlongSpline = 10000.0;
	
	float OffsetAcrossPlane = 5000.0;
	float OffsetAcrossPlaneChangeSpeed = 1000.0;

	float MinOffsetDistance = 50.0;

	FVector NextOffsetLoc;
	FVector CurrentOffset;

	FHazeAcceleratedVector AccelVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Spline != nullptr)
			SplineComp = Spline.Spline;
		
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentOffset = Math::VInterpConstantTo(CurrentOffset, NextOffsetLoc, DeltaSeconds, OffsetAcrossPlaneChangeSpeed);
		FVector TargetLocation = GetWorldPosition();
		AccelVector.AccelerateTo(TargetLocation, 1.5, DeltaSeconds);

		FVector FacingDir = SplineComp.GetWorldRotationAtSplineDistance(GetOffsetSplineDistance()).Vector();
		Owner.ActorRotation = (-FacingDir).Rotation();
		Owner.ActorLocation = AccelVector.Value;

		if ((CurrentOffset - NextOffsetLoc).Size() < MinOffsetDistance)
			NextOffsetLoc = GetNextOffsetLocation();
	}

	UFUNCTION()
	void ActivateSplineMovement()
	{
		SetComponentTickEnabled(true);
		NextOffsetLoc = GetNextOffsetLocation();
		AccelVector.SnapTo(GetWorldPosition());
		Owner.ActorLocation = AccelVector.Value;
	}

	UFUNCTION()
	void DeactivateSplineMovement()
	{
		SetComponentTickEnabled(false);
	}

	FVector GetWorldPosition()
	{
		//Position
		FVector SplineLocation = SplineComp.GetWorldLocationAtSplineDistance(GetOffsetSplineDistance());
		
		//Offset based on spline rotation
		FRotator SplineRotation = SplineComp.GetWorldRotationAtSplineDistance(GetOffsetSplineDistance()).Rotator();
		FVector PlaneOffset;
		PlaneOffset += SplineRotation.ForwardVector * CurrentOffset.X;
		PlaneOffset += SplineRotation.RightVector * CurrentOffset.Y;
		PlaneOffset += SplineRotation.UpVector * CurrentOffset.Z;
		
		return SplineLocation + PlaneOffset;
	}

	float GetOffsetSplineDistance()
	{
		FVector ClosestPlayerLocation = Game::GetClosestPlayer(Owner.ActorLocation).ActorLocation;
		float ClosestDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ClosestPlayerLocation);
		return ClosestDistance + OffsetAlongSpline;
	}

	FVector GetNextOffsetLocation()
	{
		return FVector(0.0, Math::RandRange(-OffsetAcrossPlane, OffsetAcrossPlane), Math::RandRange(-OffsetAcrossPlane, OffsetAcrossPlane));
	}
}
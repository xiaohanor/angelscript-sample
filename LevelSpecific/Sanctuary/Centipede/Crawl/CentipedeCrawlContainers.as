USTRUCT()
struct FCentipedeCrawlConstraint
{
	UPROPERTY(EditAnywhere, DisplayName = "Location")
	FVector RelativeLocation;

	UPROPERTY(EditAnywhere, DisplayName = "Rotation")
	FQuat RelativeRotation;

	UPROPERTY()
	FVector Extent = FVector (100, 100, 100);

	FVector ConstrainVelocity(FVector StartLocation, FVector Velocity, FTransform ConstraintWorldTransform)
	{
		// FTransform LocalTransform = GetRelativeTransform();
		FVector LocalStartLocation = ConstraintWorldTransform.InverseTransformPositionNoScale(StartLocation);
		FVector LocalVelocity = ConstraintWorldTransform.InverseTransformVectorNoScale(Velocity);

		FVector LocalEndLocation = LocalStartLocation + LocalVelocity;

		// FVector Max_X = FVector::ForwardVector * Extent.X;
		// FVector Max_Y = FVector::RightVector * Extent.Y;

		FVector ConstrainedLocalLocation = FVector::ZeroVector;

		// float XSpill = Math::Abs(LocalEndLocation.DotProduct(FVector::ForwardVector));
		// if (XSpill >= Extent.X)
			ConstrainedLocalLocation += LocalEndLocation.ConstrainToDirection(FVector::ForwardVector).GetClampedToMaxSize(Extent.X * 0.998);
		// else
		// 	ConstrainedLocalLocation += LocalEndLocation.ConstrainToDirection(FVector::ForwardVector);

		// float YSpill = Math::Abs(LocalEndLocation.DotProduct(FVector::RightVector));
		// if (YSpill >= Extent.Y)
			ConstrainedLocalLocation += LocalEndLocation.ConstrainToDirection(FVector::RightVector).GetClampedToMaxSize(Extent.Y * 0.998);
		// else
		// 	ConstrainedLocalLocation += LocalEndLocation.ConstrainToDirection(FVector::RightVector);

		FVector ConstrainedVelocity = ConstrainedLocalLocation - LocalStartLocation;
		return ConstraintWorldTransform.TransformVectorNoScale(ConstrainedVelocity);
	}

	FVector ConstrainLocation(FVector Location, FTransform ConstraintWorldTransform, float DeltaTime)
	{
		FVector _RelativeLocation = ConstraintWorldTransform.InverseTransformPositionNoScale(Location);

		FVector ConstrainedRelativeLocation = _RelativeLocation.ConstrainToDirection(FVector::ForwardVector).GetClampedToMaxSize(Extent.X * 0.998)
											+ _RelativeLocation.ConstrainToDirection(FVector::RightVector).GetClampedToMaxSize(Extent.Y * 0.998)
											+ _RelativeLocation.ConstrainToDirection(FVector::UpVector);

		return ConstraintWorldTransform.TransformPositionNoScale(ConstrainedRelativeLocation);
	}

	FTransform GetRelativeTransform() const
	{
		return FTransform(RelativeRotation, RelativeLocation);
	}

	FTransform GetWorldTransform(AActor Owner) const
	{
		FTransform NoScaleOwnerTransform = FTransform(Owner.ActorRotation, Owner.ActorLocation);
		return FTransform(RelativeRotation, RelativeLocation) * NoScaleOwnerTransform;
	}
}

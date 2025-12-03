
// Constrains Source and Target to Axis and rotates your non-constrained source around the Axis
// Will not reach the target if the axis does not allow it to do so
UFUNCTION()
mixin FVector RotateVectorTowardsAroundAxis(FVector Source, FVector Target, FVector Axis, float AngleDeg)	
{
	FVector AxisNormalized = Axis.GetSafeNormal();
	FVector ConstrainedSource = Source.ConstrainToPlane(AxisNormalized).GetSafeNormal();
	FVector ConstrainedTarget = Target.ConstrainToPlane(AxisNormalized).GetSafeNormal();

	float SourceTargetDot = ConstrainedSource.DotProduct(ConstrainedTarget);
	float AngleDifference = Math::Acos(SourceTargetDot);

	FVector RotationAxis = ConstrainedSource.CrossProduct(ConstrainedTarget);
	FQuat RotationQuat = FQuat(RotationAxis.GetSafeNormal(), Math::Min(AngleDifference, Math::DegreesToRadians(AngleDeg)));
	
	return RotationQuat * Source;
}

// Constrains Source and Target to Axis and rotates your non-constrained source around the Axis
// Will not reach the target if the axis does not allow it to do so
UFUNCTION()
mixin FVector SlerpVectorTowardsAroundAxis(FVector Source, FVector Target, FVector Axis, float Alpha)	
{
	FVector AxisNormalized = Axis.GetSafeNormal();
	FVector ConstrainedSource = Source.ConstrainToPlane(AxisNormalized).GetSafeNormal();
	FVector ConstrainedTarget = Target.ConstrainToPlane(AxisNormalized).GetSafeNormal();

	float SourceTargetDot = ConstrainedSource.DotProduct(ConstrainedTarget);
	float AngleDifference = Math::Acos(SourceTargetDot);

	FVector RotationAxis = ConstrainedSource.CrossProduct(ConstrainedTarget);
	FQuat RotationQuat = FQuat(RotationAxis.GetSafeNormal(), AngleDifference * Alpha);
	
	return RotationQuat * Source;
}

// Return true if locations are within given distance from each other
UFUNCTION(BlueprintPure, Category = "Math|Vector", meta = (KeyWords = "near close almost less more far outside"))
mixin bool IsWithinDist(FVector Location, FVector OtherLocation, float MaxDistance)
{
	return Location.DistSquared(OtherLocation) < Math::Square(MaxDistance);
}

// Return true if locations are within given distance from each other
UFUNCTION(BlueprintPure, Category = "Math|Vector", meta = (KeyWords = "near close almost less more far outside"))
mixin bool IsWithinDist2D(FVector Location, FVector OtherLocation, float MaxDistance)
{
	return Location.DistSquared2D(OtherLocation) < Math::Square(MaxDistance);
}

// Return true if locations are within given distance from each other
UFUNCTION(BlueprintPure, Category = "Math|Vector", meta = (KeyWords = "near close almost less more far outside"))
mixin bool IsWithinRange(FVector Location, FVector OtherLocation, FHazeRange WithinRange)
{
	const float DistSq = Location.DistSquared(OtherLocation);
	return Math::Abs(DistSq - Math::Clamp(DistSq, Math::Square(WithinRange.Min), Math::Square(WithinRange.Max))) < KINDA_SMALL_NUMBER;
}

// Return true if locations are within given distance from each other, ignores Z
UFUNCTION(BlueprintPure, Category = "Math|Vector", meta = (KeyWords = "near close almost less more far outside"))
mixin bool IsWithinRange2D(FVector Location, FVector OtherLocation, FHazeRange WithinRange)
{
	const float DistSq = Location.DistSquared2D(OtherLocation);
	return Math::Abs(DistSq - Math::Clamp(DistSq, Math::Square(WithinRange.Min), Math::Square(WithinRange.Max))) < KINDA_SMALL_NUMBER;
}

UFUNCTION(BlueprintPure, Category = "Math|Vector")
mixin FVector ClampInsideCone(FVector UnclampedDirection, FVector ConeCenterDirection, float MaxAngleDegrees)
{
	if (UnclampedDirection.IsZero())
		return UnclampedDirection;
	if (ConeCenterDirection.IsZero())
		return UnclampedDirection;

	FVector CenterDir = ConeCenterDirection.GetSafeNormal();
	float Length = UnclampedDirection.Size();
	float MaxRadians = Math::DegreesToRadians(MaxAngleDegrees);
	float CosAngle = Math::Cos(MaxRadians);
	if (CenterDir.DotProduct(UnclampedDirection / Length) > CosAngle)
		return UnclampedDirection; // Inside cone

	FVector RotationAxis = CenterDir.CrossProduct(UnclampedDirection);
	if (RotationAxis.IsNearlyZero())
		RotationAxis = FVector::UpVector; // Directly backwards from center
	RotationAxis.Normalize(); 
	return CenterDir.RotateAngleAxis(MaxAngleDegrees, RotationAxis) * Length; 
}


UFUNCTION(BlueprintPure, Category = "Math|Vector")
mixin FVector GetNormalizedWithFallback(FVector Vector, FVector Fallback)
{
	if (Vector.IsZero())
		return Fallback.GetSafeNormal();
	return Vector.GetSafeNormal();
}

UFUNCTION(BlueprintPure, Category = "Math|Vector")
mixin FVector GetNormalized2DWithFallback(FVector Vector, FVector Fallback)
{
	if (Vector.IsZero())
		return Fallback.GetSafeNormal2D();
	return Vector.GetSafeNormal2D();
}
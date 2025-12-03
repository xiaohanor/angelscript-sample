mixin FMovementDelta SurfaceProject(FMovementDelta Movement, FVector SurfaceNormal, FVector WorldUp)
{
 	check(SurfaceNormal.IsNormalized());
	check(WorldUp.IsNormalized());

	FVector Delta = Movement.Delta.GetDirectionTangentToSurface(SurfaceNormal, WorldUp) * Movement.Delta.Size();
	FVector Velocity = Movement.Velocity.GetDirectionTangentToSurface(SurfaceNormal, WorldUp) * Movement.Velocity.Size();
	return FMovementDelta(Delta, Velocity);
}

mixin FMovementDelta PlaneProject(FMovementDelta Movement, FVector PlaneNormal, bool bMaintainSize = false)
{
	check(PlaneNormal.IsNormalized());

	FVector Delta;
	FVector Velocity;
	if(bMaintainSize)
	{
		Delta = Movement.Delta.VectorPlaneProject(PlaneNormal).GetSafeNormal() * Movement.Delta.Size();
		Velocity = Movement.Velocity.VectorPlaneProject(PlaneNormal).GetSafeNormal() * Movement.Velocity.Size();
	}
	else
	{
		Delta = Movement.Delta.VectorPlaneProject(PlaneNormal);
		Velocity = Movement.Velocity.VectorPlaneProject(PlaneNormal);
	}

	return FMovementDelta(Delta, Velocity);
}

mixin FMovementDelta Reflect(FMovementDelta Movement, FVector PlaneNormal)
{
	check(PlaneNormal.IsNormalized());
	const FVector Delta = Movement.Delta.GetReflectionVector(PlaneNormal);
	const FVector Velocity = Movement.Velocity.GetReflectionVector(PlaneNormal);
	return FMovementDelta(Delta, Velocity);
}

/**
 * Reflect off of the plane, and multiply the delta along the normal by Restitution
 */
mixin FMovementDelta Bounce(FMovementDelta Movement, FVector PlaneNormal, float Restitution)
{
	check(PlaneNormal.IsNormalized());
	devCheck(Restitution >= 0.0, "Tried to call Bounce on FMovementDelta with a negative restitution.");
	
	FVector Delta = Movement.Delta.GetReflectionVector(PlaneNormal);
	FVector Velocity = Movement.Velocity.GetReflectionVector(PlaneNormal);

	FVector DeltaAlongNormal = Delta.ProjectOnToNormal(PlaneNormal);
	FVector VelocityAlongNormal = Velocity.ProjectOnToNormal(PlaneNormal);

	const float InverseRestitution = 1.0 - Restitution;
	DeltaAlongNormal *= InverseRestitution;
	VelocityAlongNormal *= InverseRestitution;

	Delta -= DeltaAlongNormal;
	Velocity -= VelocityAlongNormal;

	return FMovementDelta(Delta, Velocity);
}

mixin FMovementDelta ProjectOntoNormal(FMovementDelta Movement, FVector Normal, bool bMaintainSize = false)
{
	check(Normal.IsNormalized());

	FVector Delta;
	FVector Velocity;

	if(bMaintainSize)
	{
		Delta = Movement.Delta.ProjectOnToNormal(Normal).GetSafeNormal() * Movement.Delta.Size();
		Velocity = Movement.Velocity.ProjectOnToNormal(Normal).GetSafeNormal() * Movement.Velocity.Size();
	}
	else
	{
		Delta = Movement.Delta.ProjectOnToNormal(Normal);
		Velocity = Movement.Velocity.ProjectOnToNormal(Normal);
	}

	return FMovementDelta(Delta, Velocity);
}

/**
 * Only allow the delta and velocity to point the same direction as the Normal.
 */
mixin FMovementDelta LimitToNormal(FMovementDelta Movement, FVector Normal)
{
	FVector Delta = Movement.Delta;
	FVector Velocity = Movement.Velocity;

	if(Movement.Delta.DotProduct(Normal) < 0)
		Delta = Movement.Delta.VectorPlaneProject(Normal);

	if(Movement.Velocity.DotProduct(Normal) < 0)
		Velocity = Movement.Velocity.VectorPlaneProject(Normal);

	return FMovementDelta(Delta, Velocity);
}

/**
 * Get the delta projected on Normal of the delta with the minimum dot product in the Normal direction.
 * Anything orthogonal to Normal will be kept as-is.
 */
mixin FMovementDelta MinInDirection(FMovementDelta Movement, FMovementDelta Other, FVector Normal)
{
	FMovementDelta Out = Movement.GetHorizontalPart(Normal);

	if(Movement.Delta.DotProduct(Normal) < Other.Delta.DotProduct(Normal))
		Out.Delta += Movement.Delta.ProjectOnToNormal(Normal);
	else
		Out.Delta += Other.Delta.ProjectOnToNormal(Normal);

	if(Movement.Velocity.DotProduct(Normal) < Other.Velocity.DotProduct(Normal))
		Out.Velocity += Movement.Velocity.ProjectOnToNormal(Normal);
	else
		Out.Velocity += Other.Velocity.ProjectOnToNormal(Normal);

	return Out;
}

/**
 * Get the delta projected on Normal of the delta with the minimum dot product in the Normal direction.
 * Anything orthogonal to Normal will be kept as-is.
 */
mixin FMovementDelta ClosestToZeroInDirection(FMovementDelta Movement, FMovementDelta Other, FVector Normal)
{
	FMovementDelta Out = Movement.GetHorizontalPart(Normal);

	if(Math::Abs(Movement.Delta.DotProduct(Normal)) < Math::Abs(Other.Delta.DotProduct(Normal)))
		Out.Delta += Movement.Delta.ProjectOnToNormal(Normal);
	else
		Out.Delta += Other.Delta.ProjectOnToNormal(Normal);

	if(Math::Abs(Movement.Velocity.DotProduct(Normal)) < Math::Abs(Other.Velocity.DotProduct(Normal)))
		Out.Velocity += Movement.Velocity.ProjectOnToNormal(Normal);
	else
		Out.Velocity += Other.Velocity.ProjectOnToNormal(Normal);

	return Out;
}

/**
 * Applies Rotation.RotateVector() on both Delta and Velocity.
 */
mixin FMovementDelta Rotate(FMovementDelta Movement, FQuat Rotation)
{
	FVector Delta = Rotation.RotateVector(Movement.Delta);
	FVector Velocity = Rotation.RotateVector(Movement.Velocity);

	return FMovementDelta(Delta, Velocity);
}

mixin FVector GetDirectionTangentToSurface(FVector Vector, FVector SurfaceNormal, FVector WorldUp)
{
	check(SurfaceNormal.IsNormalized());
	check(WorldUp.IsNormalized());

	if(Vector.IsZero())
		return FVector::ZeroVector;

	const FVector Tangent = Vector.CrossProduct(WorldUp);
	const FVector NewVector = SurfaceNormal.CrossProduct(Tangent);

	return NewVector.GetSafeNormal();
}

mixin FVector GetImpactNormalProjectedAlongSurface(FVector ImpactNormal, FVector SurfaceNormal, FVector WorldUp)
{
	check(ImpactNormal.IsNormalized());
	check(SurfaceNormal.IsNormalized());
	check(WorldUp.IsNormalized());

	const FVector Tangent = SurfaceNormal.CrossProduct(ImpactNormal);
	const FVector ImpactNormalProjectedAlongSurface = Tangent.CrossProduct(WorldUp);

	return ImpactNormalProjectedAlongSurface.GetSafeNormal(ResultIfZero = SurfaceNormal);
}
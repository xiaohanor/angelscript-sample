class ADroneSwarmHoverZone : ADroneSwarmMoveZone
{
	/**
	 * The amount of force that will be applied in the move direction.
	 * The force magnitude will remain for the lower 2/3s of the hover zone,
	 * gradually falling down the closer the player gets to the edge.
	 */
	UPROPERTY(EditAnywhere)
	float ForceMagnitude = 800.0;

	// 1: no acceleration at the top, 0: maximum acceleration all the way
	// This value provides 0.2 acceleration at the upper 20% of the volume. Is nice.
	const float DecelerationCutoff = 1;

	FVector CalculateAccelerationAtLocation(FVector WorldLocation) const override
	{
		float AccelerationMultiplier = 1.0 - Math::Min(GetMoveFractionAtLocation(WorldLocation), DecelerationCutoff);

		float Magnitude = Math::Pow(AccelerationMultiplier * (GetZoneInfoAtLocation(WorldLocation).ZoneHeight / 3.33), 2);
		Magnitude = Math::Min(ForceMagnitude, Magnitude);
		FVector Acceleration = GetMoveDirection() * Magnitude;

		return Acceleration;
	}

	FVector CalculateDrag(FVector Velocity, FVector WorldLocation, FVector WorldUp) const override
	{
		// Add hover drag
		FVector HoverDragConstrainedVelocity = -Velocity.ConstrainToDirection(GetMoveDirection());
		float Dot = HoverDragConstrainedVelocity.DotProduct(WorldUp);
		FVector HoverDrag = HoverDragConstrainedVelocity * Math::Max(0.0, Dot);

		return HoverDrag.GetClampedToMaxSize(Drone::Gravity);
	}

	FVector GetClosestVerticalPointOnHoverZone(const FVector InPos)
	{
		const FVector BoxLocation = MovementZoneComponent.GetWorldLocation();
		const FVector BoundsExtent = MovementZoneComponent.Shape.BoxExtents;

		const FVector LineStart = FVector(BoxLocation.X, BoxLocation.Y, BoxLocation.Z - BoundsExtent.Z);
		const FVector LineEnd = FVector(BoxLocation.X, BoxLocation.Y, BoxLocation.Z + BoundsExtent.Z);

		return Math::ClosestPointOnLine(LineStart, LineEnd, InPos);
	}
}
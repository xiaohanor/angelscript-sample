class ADroneSwarmFloatZone : ADroneSwarmMoveZone
{

	UPROPERTY(EditAnywhere)
	float RapidSpeed = 1;

	FVector CalculateAccelerationAtLocation(FVector WorldLocation) const override
	{
		float AccelerationMultiplier = 1.0 - GetMoveFractionAtLocation(WorldLocation);

		float Magnitude = Math::Pow(AccelerationMultiplier * (GetZoneInfoAtLocation(WorldLocation).ZoneHeight / 3.33), 2);
		Magnitude = Math::Min(500, Magnitude);
		FVector Acceleration = GetMoveDirection() * Magnitude * RapidSpeed;

		return Acceleration;
	}

	FVector CalculateDrag(FVector Velocity, FVector WorldLocation, FVector WorldUp) const override
	{
		FVector VerticalVelocity = Velocity.ConstrainToDirection(WorldUp);
		FVector MoveZoneDrag = -VerticalVelocity * GetMoveFractionAtLocation(WorldLocation);
		MoveZoneDrag = MoveZoneDrag.GetClampedToMaxSize(Velocity.Size());

		return MoveZoneDrag;
	}
}
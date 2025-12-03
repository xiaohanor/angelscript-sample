class UMagnetDroneAttachToBoatMovementResolver : UDroneMovementResolver
{
	default RequiredDataType = UMagnetDroneAttachToBoatMovementData;

	const UMagnetDroneAttachToBoatMovementData AttachToBoatData;
	bool bHadCollision = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		AttachToBoatData = Cast<UMagnetDroneAttachToBoatMovementData>(Movement);
		bHadCollision = false;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		bHadCollision = true;
		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		auto AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(MovementComponent.Owner);

		if(bHadCollision)
			AttachToBoatComp.BoatCollisionFrame = Time::FrameNumber;

		Super::ApplyResolvedData(MovementComponent);
	}
};
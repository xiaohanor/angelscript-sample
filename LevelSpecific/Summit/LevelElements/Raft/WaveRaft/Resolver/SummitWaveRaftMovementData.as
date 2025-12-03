class USummitWaveRaftMovementData : USweepingMovementData
{
	access Protected = protected, USummitWaveRaftMovementResolver (inherited);

	default DefaultResolverType = USummitWaveRaftMovementResolver;

	access:Protected
	FVector WaterUp;

	access:Protected
	FSplinePosition SplinePos;

	access:Protected
	AWaveRaft WaveRaft;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(WaveRaft == nullptr)
			WaveRaft = Cast<AWaveRaft>(MovementComponent.Owner);
		SplinePos = WaveRaft.SplinePos;
		WaterUp = SplinePos.WorldUpVector;

		return Super::PrepareMove(MovementComponent, CustomWorldUp);
	}

	// FVector GetWaterAlignedVelocity(FVector InVelocity, FVector InWaterUp) const
	// {
	// 	FVector AlignedVelocity;

	// 	const float Speed = InVelocity.Size();
	// 	const FVector VelocityDir = InVelocity.ConstrainToPlane(InWaterUp).GetSafeNormal();
		
	// 	AlignedVelocity = VelocityDir * Speed;
	// 	return AlignedVelocity;
	// } 

	// Add in buoyancy functions here
}
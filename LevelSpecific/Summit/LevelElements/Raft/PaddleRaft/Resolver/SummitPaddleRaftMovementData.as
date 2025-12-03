class USummitPaddleRaftMovementData : USweepingMovementData
{
	default DefaultResolverType = USummitPaddleRaftMovementResolver;

	FVector WaterUp;

	FVector GetWaterAlignedVelocity(FVector InVelocity, FVector InWaterUp) const
	{
		FVector AlignedVelocity;

		const float Speed = InVelocity.Size();
		const FVector VelocityDir = InVelocity.ConstrainToPlane(InWaterUp).GetSafeNormal();
		
		AlignedVelocity = VelocityDir * Speed;
		return AlignedVelocity;
	} 

	// Add in buoyancy functions here
}
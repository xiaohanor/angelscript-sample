

class UGravityWellMovementData : USweepingMovementData
{
	default DefaultResolverType = UGravityWellMovementResolver; 

	FSplinePosition CurrentSplinePosition;
	float MaxDistance;

	
	void AddHorizontalDelta(FVector Delta)
	{
		check(IsValid());
		check(!Delta.ContainsNaN());
		AddHorizontalInternal(FMovementDelta(Delta, GetVelocityFromDeltaInternal(Delta)), true);
	}

	void AddVerticalDelta(FVector Delta)
	{
		check(IsValid());
		check(!Delta.ContainsNaN());
		AddVerticalInternal(FMovementDelta(Delta, GetVelocityFromDeltaInternal(Delta)), true);
	}
}

class UGravityWellMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UGravityWellMovementData; 

	private const UGravityWellMovementData GravityWellData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		GravityWellData = Cast<UGravityWellMovementData>(Movement);
	}
}
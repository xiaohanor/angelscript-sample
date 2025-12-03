



/**
 * 
 */
class USimpleMovementData : UBaseMovementData
{
	access Protected = protected, USimpleMovementResolver (inherited), AddMovementResolvedData;
	
	default DefaultResolverType = USimpleMovementResolver;

	access:Protected
	bool bMaintainMovementSizeOnGroundedRedirects = false;

	access:Protected
	bool bCanPerformGroundTrace = true;

	access:Protected
	float FloatingHeight = -1;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		auto Settings = USimpleMovementSettings::GetSettings(MovementComponent.HazeOwner);
		
		bMaintainMovementSizeOnGroundedRedirects = Settings.bMaintainMovementSizeOnGroundedRedirects;
		FloatingHeight = Settings.FloatingHeight.Get(ShapeSizeForMovement);

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		const auto Other = Cast<USimpleMovementData>(OtherBase);

		bMaintainMovementSizeOnGroundedRedirects = Other.bMaintainMovementSizeOnGroundedRedirects;
		bCanPerformGroundTrace = Other.bCanPerformGroundTrace;
		FloatingHeight = Other.FloatingHeight;
	}
#endif

	/**
	 * Add a velocity only along the horizontal plane determined by WorldUp.
	 */
	void AddHorizontalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
	}

	/**
	 * Add an acceleration only along the horizontal plane determined by WorldUp.
	 */
	void AddHorizontalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromAcceleration(Acceleration), GetVelocityFromAcceleration(Acceleration));
		AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
	}

	/**
	 * Add a velocity only along the vertical direction determined by WorldUp.
	 */
	void AddVerticalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
	}

	/**
	 * Add an acceleration only along the vertical direction determined by WorldUp.
	 */
	void AddVerticalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromAcceleration(Acceleration), GetVelocityFromAcceleration(Acceleration));
		AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
	}

	void BlockGroundTracingForThisFrame()
	{
		bCanPerformGroundTrace = false;
	}
}


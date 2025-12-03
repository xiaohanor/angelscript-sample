

/**
 * Movement hits contains a lot of extra information about a hit result
 * used by the movement system.
 * The hit result is usually pulled back to hinder bStartPenetrating from happening
 * It also contains the walkable information about the impact
 */
USTRUCT(Meta = (DisallowNetworkSend))
struct FMovementHitResult
{
#if !RELEASE
	FHazeTraceTag TraceTag;
#endif

	EMovementImpactType Type = EMovementImpactType::Unset;
	
	bool bIsWalkable = false;
	
	bool bIsStepUp = false;
	float StepUpHeight = -1;
	
	FMovementEdge EdgeResult;

	private FHitResult HitResultInternal;
	private FVector TraceDirectionInternal = FVector::ZeroVector;
	
	private float TimeInternal = 0;
	private float DistanceInternal = 0;
	private FVector TraceEndInternal = FVector::ZeroVector;
	private FVector LocationInternal = FVector::ZeroVector;
	private float SafetyMarginInternal = 0;
	private float AppliedFlatBottomDistance = 0;
	private float TraceLengthInternal = 0;

	FMovementHitResult(EMovementImpactType InType)
	{
		Type = InType;
	}

	/**
	 * Construct a MovementHitResult from a HitResult.
	 * @param InHit The HitResult.
	 * @param InTraceSafetyDistance The SafetyDistance we applied in the trace direction. Will be adjusted for in ApplyPullback().
	 * @param InFlatBottomRadius The radius of our capsule when we want to perform a flat bottomed capsule sweep. Will be adjusted for in ApplyPullback().
	 */
	FMovementHitResult(FHitResult InHit, float InTraceSafetyMargin, float InFlatBottomRadius = 0)
	{
		const FVector TraceDelta = (InHit.TraceEnd - InHit.TraceStart);
		HitResultInternal = InHit;
		TraceDirectionInternal = TraceDelta.GetSafeNormal();
		TimeInternal = InHit.Time;
		TraceEndInternal = InHit.TraceEnd;
		DistanceInternal = InHit.Distance;
		LocationInternal = InHit.Location;
		SafetyMarginInternal = InTraceSafetyMargin;
		AppliedFlatBottomDistance = InFlatBottomRadius;
		TraceLengthInternal = TraceDelta.Size();

		// Apply initial type.
		if(InHit.bStartPenetrating)
			Type = EMovementImpactType::Invalid;
		else if(!InHit.bBlockingHit)
			Type = EMovementImpactType::NoImpact;
	}

	void ApplyPullback(bool bChangeTime = true)
	{
		if(SafetyMargin <= 0)
			return;

		if(!IsValidBlockingHit())
			return;

		const FVector TraceDir = TraceDirection;

		if(AppliedFlatBottomDistance > 0)
		{
			const float DistanceFromCenter = HitResultInternal.ImpactPoint.Dist2D(HitResultInternal.Location, TraceDir);
			const float RadiusAlpha = DistanceFromCenter / AppliedFlatBottomDistance;

			// Alpha 0 to 1 of how much extra distance was applied at this radius alpha
			const float AddedTraceLengthAlpha = 1.0 - Math::CircularIn(0, 1, RadiusAlpha);
			const float AddedTraceLengthAtRadius = AppliedFlatBottomDistance * AddedTraceLengthAlpha;

			// Adjust the trace length, since we want to fake that we didn't trace the full distance
			TraceLengthInternal -= AddedTraceLengthAtRadius;

			// Remove distance to fake that the bottom of the shape is flat
			// This effectively makes us hover when on slopes, since the edge of the cylinder is touching the ground before the bottom of the capsule
			//HitResultInternal.Distance = Math::Max(0, HitResultInternal.Distance - (FlatBottomRadiusInternal - AddedTraceLengthAtRadius));

			// We have now pulled this distance back
			AppliedFlatBottomDistance = 0;
		}

		const FVector NewEndTrace = TraceOrigin + (TraceDir * TraceLength);
		if(HitResultDistance <= SafetyMargin)
		{
			// We hit immediately
			const FVector NewLocation = HitResultLocation - (TraceDir * SafetyMargin);
			OverrideTraceResultData(
				NewLocation,
				NewEndTrace,
				0,
				0,
				bBlockingHit);
		}
		else if(HitResultDistance > TraceLength)
		{
			// We traced further than we hit, meaning that we did not hit at all
			const FVector NewLocation = TraceOrigin + (TraceDir * TraceLength);
			OverrideTraceResultData(
				NewLocation,
				NewEndTrace,
				TraceLength,
				1,
				false);
		}
		else
		{
			// Apply pullback to the hit result
			const float NewDistance = HitResultDistance - SafetyMargin;
			const FVector NewLocation = TraceOrigin + (TraceDir * NewDistance);

			float NewTime = HitResultTime;
			if(bChangeTime)
				NewTime = Math::Clamp(NewDistance / TraceLength, 0, 1);

			OverrideTraceResultData(
				NewLocation,
				NewEndTrace,
				NewDistance,
				NewTime,
				bBlockingHit);
		}

		// Prevent applying pullback twice
		SafetyMarginInternal = -1;
	}

	void OverrideTraceResultData(FVector NewLocation, FVector NewTraceEnd, float NewDistance, float NewTime, bool bIsBlockingHit)
	{
		LocationInternal = NewLocation;
		TraceEndInternal = NewTraceEnd;
		DistanceInternal = NewDistance;
		TimeInternal = NewTime;
		HitResultInternal.bBlockingHit = bIsBlockingHit;
	}

	void OverrideLocation(FVector NewLocation)
	{
		LocationInternal = NewLocation;
	}

	void OverrideNormals(FVector NewNormal, FVector NewImpactNormal)
	{
		HitResultInternal.Normal = NewNormal;
		HitResultInternal.ImpactNormal = NewImpactNormal;
	}

	void OverrideImpact(FVector NewLocation, FVector NewImpactPoint, FVector NewNormal, FVector NewImpactNormal, float NewDistance, bool bIsBlockingHit)
	{
		LocationInternal = NewLocation;
		HitResultInternal.ImpactPoint = NewImpactPoint;
		HitResultInternal.Normal = NewNormal;
		HitResultInternal.ImpactNormal = NewImpactNormal;
		if(DistanceInternal > 0)
			TimeInternal = Math::Min(1, NewDistance / DistanceInternal);
		else
			TimeInternal = 1;
		DistanceInternal = NewDistance;
		HitResultInternal.bBlockingHit = bIsBlockingHit;
	}

	void OverrideNoImpact()
	{
		Type = EMovementImpactType::NoImpact;
		HitResultInternal.bBlockingHit = false;
	}

	float GetSafetyMargin() const property
	{
		return SafetyMarginInternal;
	}

	float GetTraceLength() const property
	{
		return TraceLengthInternal;
	}

	const FVector& GetTraceOrigin() const property
	{
		return HitResultInternal.TraceStart;
	}

	FHitResult ConvertToHitResult() const
	{
		FHitResult Out = HitResultInternal;
		Out.Location = LocationInternal;
		Out.TraceEnd = TraceEndInternal;
		Out.Time = TimeInternal;
		Out.Distance = DistanceInternal;
		return Out;
	}

	const FHitResult& GetInternalHitResult() const property
	{
		return HitResultInternal;
	}

	UPrimitiveComponent GetComponent() const property
	{
		return HitResultInternal.Component;
	}

	const FName& GetBoneName() const property
	{
		return HitResultInternal.BoneName;
	}

	const FVector& GetTraceDirection() const property
	{
		return TraceDirectionInternal;
	}

	const FVector& GetImpactNormal() const property
	{
		return HitResultInternal.ImpactNormal;
	}

	const FVector& GetNormal() const property
	{
		return HitResultInternal.Normal;
	}

	const FVector& GetLocation() const property
	{
		return LocationInternal;
	}

	/**
	 * The location not pulled back
	 */
	const FVector& GetHitResultLocation() const property
	{
		return HitResultInternal.Location;
	}

	const FVector& GetImpactPoint() const property
	{
		return HitResultInternal.ImpactPoint;
	}

	float GetDistance() const property
	{
		return DistanceInternal;
	}

	/**
	 * The distance not pulled back
	 */
	float GetHitResultDistance() const property
	{
		return HitResultInternal.Distance;
	}

	float GetTime() const property
	{
		return TimeInternal;
	}

	/**
	 * The time not pulled back
	 */
	float GetHitResultTime() const property
	{
		return HitResultInternal.Time;
	}

	AActor GetActor() const property
	{
		return HitResultInternal.Actor;
	}

	bool IsNotValid() const
	{
		return Type == EMovementImpactType::Invalid;
	}

	bool IsValidBlockingHit() const
	{
		return IsValidBlockingHitIgnoreType() && Type != EMovementImpactType::NoImpact && Type != EMovementImpactType::Invalid;
	}

	bool IsValidBlockingHitIgnoreType() const
	{
		if(!HitResultInternal.IsValidBlockingHit())
			return false;

		// BSPs have no valid actor. And since we are using actors on movement collisions,
		// we can't have that in the levels for movement
		if(HitResultInternal.GetActor() == nullptr)
			return false;
		
		return true;
	}

	bool IsAnyWalkableContact() const
	{
		return IsValidBlockingHit() && bIsWalkable;
	}

	bool IsAnyGroundContact() const
	{
		return IsValidBlockingHitIgnoreType() && Type == EMovementImpactType::Ground;
	}

	bool IsWalkableGroundContact() const
	{
		return IsAnyGroundContact() && bIsWalkable;
	}

	bool IsSlidingGroundContact() const
	{
		return IsAnyGroundContact() && !bIsWalkable;
	}

	bool IsWallImpact() const
	{
		return IsValidBlockingHitIgnoreType() && Type == EMovementImpactType::Wall;
	}

	bool IsCeilingImpact() const
	{
		return IsValidBlockingHitIgnoreType() && Type == EMovementImpactType::Ceiling;
	}

	bool IsStepupGroundContact() const
	{
		return IsAnyGroundContact() && bIsStepUp;
	}

	bool GetbBlockingHit() const property
	{
		return HitResultInternal.bBlockingHit;
	}

	bool GetbStartPenetrating() const property
	{
		return HitResultInternal.bStartPenetrating;
	}

	const EMovementEdgeType& GetEdgeType() const property
	{
		return EdgeResult.Type;
	}
	
	bool IsOnAnEdge() const
	{
		return EdgeResult.IsEdge();
	}

	bool IsOnUnstableEdge() const
	{
		return IsOnAnEdge() && EdgeResult.IsUnstable();
	}

	float GetDistanceToImpactPoint() const
	{
		return (ImpactPoint - Location).Size();	
	}

	float GetHorizontalDistanceToImpactPoint(FVector UpVector) const
	{
		return (ImpactPoint - Location).VectorPlaneProject(UpVector).Size();	
	}

	UPhysicalMaterial GetAudioPhysMaterial() const property
	{
		return InternalHitResult.PhysMaterial;
	}
}
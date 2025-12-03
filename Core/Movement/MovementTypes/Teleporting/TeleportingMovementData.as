
/** 
 * 
*/
class UTeleportingMovementData : UBaseMovementData
{
	access Protected = protected, UTeleportingMovementResolver (inherited);

	default DefaultResolverType = UTeleportingMovementResolver;

	access:Protected
	ETeleportingMovementFinalGroundType FinalGroundContactType = ETeleportingMovementFinalGroundType::None;

	access:Protected
	EMovementOverrideFinalGroundType OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::None;

	access:Protected
	FHitResult OverrideFinalGroundContact;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		FinalGroundContactType = ETeleportingMovementFinalGroundType::None;
		OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::None;
		OverrideFinalGroundContact = FHitResult();	
		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UTeleportingMovementData>(OtherBase);
		FinalGroundContactType = Other.FinalGroundContactType;
		OverrideFinalGroundContactType = Other.OverrideFinalGroundContactType;
		OverrideFinalGroundContact = Other.OverrideFinalGroundContact;
	}
#endif

	void KeepCurrentGroundImpactForThisFrame()
	{
		FinalGroundContactType = ETeleportingMovementFinalGroundType::KeepCurrent;
	}

	void TraceForGroundImpact()
	{
		FinalGroundContactType = ETeleportingMovementFinalGroundType::Trace;
	}

	/**
	 * What ever grounded type is found, if any,
	 * this request will be used as the ground impact.
	 * @ bValidate; if true, and the request is a valid blocking hit, the an extra trace will be made to actually place the actor on the ground
	 */
	void OverrideFinalGroundResult(FHitResult WantedGroundImpact, bool bValidate = true)
	{
		check(IsValid());

		FinalGroundContactType = ETeleportingMovementFinalGroundType::ManuallyOverride;
		OverrideFinalGroundContact = WantedGroundImpact;
		if(bValidate)
			OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::ActiveWithValidation;
		else
			OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::Active;
	}
}


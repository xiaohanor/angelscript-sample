class UGravityBikeSplineBikeEnemyMovementData : UFloatingMovementData
{
	access Resolver = private, UGravityBikeSplineBikeEnemyMovementResolver;

	default DefaultResolverType = UGravityBikeSplineBikeEnemyMovementResolver;

	access:Resolver
	bool bTriggerResponseComponent = false;

	access:Resolver
	bool bSplineLock = false;

	access:Resolver
	FTransform SplineTransform;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		// Gotta be cheap!
		ValidationMethod = EFloatingMovementValidateMethod::NoValidation;
		FloatingHeight = ShapeSizeForMovement;

		bTriggerResponseComponent = true;
		bSplineLock = false;

		auto SplineMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(MovementComponent.Owner);
		if(SplineMoveComp != nullptr)
		{
			SplineTransform = SplineMoveComp.GetSplineTransform();
		}

		return true;
	}

	void ApplyIgnoreResponseComponents()
	{
		bTriggerResponseComponent = false;
	}

	void ApplySplineLock()
	{
		bSplineLock = true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<UGravityBikeSplineBikeEnemyMovementData>(OtherBase);
		bTriggerResponseComponent = Other.bTriggerResponseComponent;
		SplineTransform = Other.SplineTransform;
	}
#endif
};
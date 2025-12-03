class UGravityBikeSplineFlyingEnemyMovementData : USimpleMovementData
{
	access Resolver = private, UGravityBikeSplineFlyingEnemyMovementResolver;

	default DefaultResolverType = UGravityBikeSplineFlyingEnemyMovementResolver;

	access:Resolver
	bool bTriggerResponseComponent = false;

	access:Resolver
	bool bExplodeOnImpact = false;

	access:Resolver
	FVector SplineForward;

	access:Resolver
	bool bNoCollision;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bTriggerResponseComponent = true;
		bExplodeOnImpact = false;

		const auto FlyingEnemy = Cast<AGravityBikeSplineFlyingEnemy>(MovementComponent.Owner);

		const auto CarEnemy = Cast<AGravityBikeSplineCarEnemy>(FlyingEnemy);
		if(CarEnemy != nullptr)
		{
			SplineForward = CarEnemy.SplineMoveComp.GetSplineTransform().Rotation.ForwardVector;
			bNoCollision = !CarEnemy.SphereComp.IsCollisionEnabled();
		}

		const auto AttackShipEnemy = Cast<AGravityBikeSplineAttackShip>(FlyingEnemy);
		if(AttackShipEnemy != nullptr)
		{
			SplineForward = AttackShipEnemy.SplineMoveComp.GetSplineTransform().Rotation.ForwardVector;
			bNoCollision = !AttackShipEnemy.SphereComp.IsCollisionEnabled();
		}

		return true;
	}

	void ApplyIgnoreResponseComponents()
	{
		bTriggerResponseComponent = false;
	}

	void ApplyShouldExplodeOnImpact()
	{
		bExplodeOnImpact = true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<UGravityBikeSplineFlyingEnemyMovementData>(OtherBase);
		bTriggerResponseComponent = Other.bTriggerResponseComponent;
		bExplodeOnImpact = Other.bExplodeOnImpact;
		SplineForward = Other.SplineForward;
		bNoCollision = Other.bNoCollision;
	}
#endif
};
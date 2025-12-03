class UGravityBikeSplineBikeEnemyMovementResolver : UFloatingMovementResolver
{
	default RequiredDataType = UGravityBikeSplineBikeEnemyMovementData;

	private const UGravityBikeSplineBikeEnemyMovementData MoveData;
	private TArray<FGravityBikeSplineImpactResponseComponentAndData> Impacts;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UGravityBikeSplineBikeEnemyMovementData>(Movement);

		Impacts.Reset();
	}

	void PrepareFirstIteration() override
	{
		Super::PrepareFirstIteration();

		if(MoveData.bSplineLock)
		{
			// Move self to on spline
			FVector SplineRight = FVector::UpVector.CrossProduct(MoveData.SplineTransform.Rotation.ForwardVector).GetSafeNormal();
			IterationState.CurrentLocation = IterationState.CurrentLocation.PointPlaneProject(MoveData.SplineTransform.Location, SplineRight);

			bool bBelowSpline = false;
			if(IterationState.CurrentLocation.Z < MoveData.SplineTransform.Location.Z)
			{
				// Never allow us to move below the spline!
				IterationState.CurrentLocation.Z = MoveData.SplineTransform.Location.Z;
				bBelowSpline = true;
			}
			
			// Project deltas along spline
			for(auto It : IterationState.DeltaStates)
			{
				FMovementDelta MovementDelta = It.Value.ConvertToDelta();
				if(MovementDelta.IsNearlyZero())
					continue;

				MovementDelta = MovementDelta.PlaneProject(SplineRight, false);

				if(bBelowSpline)
					MovementDelta = MovementDelta.PlaneProject(FVector::UpVector);

				IterationState.OverrideDelta(It.Key, MovementDelta);
			}
		}
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType
	) override
	{
		FGravityBikeSplineImpactResponseComponentAndData ResponseCompAndData;
		if(CollisionWithResponseComp(Hit, ResponseCompAndData))
		{
			Impacts.Add(ResponseCompAndData);

			if(ResponseCompAndData.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ResponseCompAndData.ResponseComp.Owner);
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FGravityBikeSplineImpactResponseComponentAndData&out OutResponseCompAndData) const
	{
		if(!MoveData.bTriggerResponseComponent)
			return false;

		auto ResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResponseCompAndData.ResponseComp = ResponseComp;

		const FHitResult HitResult = Hit.ConvertToHitResult();
		const FVector ImpactVelocity = IterationState.DeltaToTrace / IterationTime;
		OutResponseCompAndData.ImpactData = FGravityBikeSplineOnImpactData(ImpactVelocity, HitResult);

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		auto BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(MovementComponent.Owner);
		
		for(auto ResponseCompAndData : Impacts)
		{
			BikeEnemy.HitImpactResponseComponent(ResponseCompAndData.ResponseComp, ResponseCompAndData.ImpactData);
		}
	}
};
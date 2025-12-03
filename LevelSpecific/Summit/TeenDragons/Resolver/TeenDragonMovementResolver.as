struct FTeenDragonMovementResolverFrameImpactData
{
	TArray<FTeenDragonMovementResolverResponseComponentHitData> ResponseCompHitData;

	void Reset()
	{
		ResponseCompHitData.Reset(3);
	}
}

struct FTeenDragonMovementResolverResponseComponentHitData
{
	FTeenDragonMovementImpactParams MovementParams;
	UTeenDragonMovementResponseComponent ResponseComp;
}

class UTeenDragonMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = UTeenDragonMovementData;
	private const UTeenDragonMovementData MovementData;

	private FTeenDragonMovementResolverFrameImpactData ImpactData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MovementData = Cast<UTeenDragonMovementData>(Movement);
		ImpactData.Reset();
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		FTeenDragonMovementResolverResponseComponentHitData ResponseHitData;
		if(CollisionWithResponseComp(Hit, ResponseHitData))
		{
			ImpactData.ResponseCompHitData.Add(ResponseHitData);
			return EMovementResolverHandleMovementImpactResult::Continue;
		}
		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FTeenDragonMovementResolverResponseComponentHitData&out OutResponseCompHitData)
	{
		TArray<UTeenDragonMovementResponseComponent> ResponseComps;
		Hit.Actor.GetComponentsByClass(ResponseComps);
		const FHitResult HitResult = Hit.ConvertToHitResult();
		if(ResponseComps.Num() == 0)
			return false;

		for(auto ResponseComp : ResponseComps)
		{
			if(ResponseComp.bIsPrimitiveParentExclusive
			&& !ResponseComp.ImpactWasOnParent(HitResult.Component))
				continue;

			if(!ResponseComp.bEnabled)
				continue;
			
			if(Hit.IsAnyGroundContact()
			&& !ResponseComp.bGroundImpactValid)
				continue;

			if(Hit.IsWallImpact()
			&& !ResponseComp.bWallImpactValid)
				continue;

			if(Hit.IsCeilingImpact()
			&& !ResponseComp.bCeilingImpactValid)
				continue;

			OutResponseCompHitData.ResponseComp = ResponseComp;
			break;
		}

		if(OutResponseCompHitData.ResponseComp == nullptr)
			return false;

		FTeenDragonMovementImpactParams MovementParams;
		MovementParams.ImpactLocation = Hit.ImpactPoint;
		MovementParams.ImpactNormal = Hit.ImpactNormal;
		MovementParams.PlayerInstigator = Cast<AHazePlayerCharacter>(Owner);
		FVector VelocityAtHit = IterationState.DeltaToTrace / IterationTime;
		MovementParams.VelocityTowardsImpact = VelocityAtHit.ConstrainToDirection(-HitResult.Normal);
		MovementParams.ImpactedComponent = HitResult.Component;
		OutResponseCompHitData.MovementParams = MovementParams;

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		if(ImpactData.ResponseCompHitData.Num() > 0)
		{
			for(auto Data : ImpactData.ResponseCompHitData)
			{
				Data.ResponseComp.OnMovedInto.Broadcast(Data.MovementParams);
			}
		}
	}
}
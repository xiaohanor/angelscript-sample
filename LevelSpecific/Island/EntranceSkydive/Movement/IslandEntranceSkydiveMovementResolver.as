struct FIslandEntranceSkydiveObstacleImpact
{
	UIslandEntranceSkydiveObstacleResponseComponent ResponseComponent;
	FVector ImpactPoint;
};

class UIslandEntranceSkydiveMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UIslandEntranceSkydiveMovementData;

	private const UIslandEntranceSkydiveMovementData MoveData;

	TArray<FIslandEntranceSkydiveObstacleImpact> Impacts;
	TArray<AActor> ActorsToIgnore;
	TArray<UPrimitiveComponent> ComponentsToIgnore;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		MoveData = Cast<UIslandEntranceSkydiveMovementData>(Movement);

		Impacts.Reset();
		ActorsToIgnore.Reset();
		ComponentsToIgnore.Reset();
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit,
																	 EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		FIslandEntranceSkydiveObstacleImpact Impact;
		bool bOutHitWasIgnored;
		if(CollisionWithResponseComp(Hit, Impact, bOutHitWasIgnored))
		{
			if(!HasAlreadyImpacted(Impact.ResponseComponent))
				Impacts.Add(Impact);

			if(bOutHitWasIgnored)
			{
				if(Impact.ResponseComponent.bIgnoreCollisionWithAllComponents)
				{
					IterationTraceSettings.AddPermanentIgnoredActor(Impact.ResponseComponent.Owner);
					ActorsToIgnore.Add(Impact.ResponseComponent.Owner);
				}
				else
				{
					IterationTraceSettings.AddPermanentIgnoredPrimitive(Hit.Component);
					ComponentsToIgnore.Add(Hit.Component);
				}

				return EMovementResolverHandleMovementImpactResult::Skip;
			}
			else
			{
				return EMovementResolverHandleMovementImpactResult::Continue;
			}
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FIslandEntranceSkydiveObstacleImpact&out OutImpact, bool&out bOutHitWasIgnored) const
	{
		auto ResponseComp = UIslandEntranceSkydiveObstacleResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutImpact.ResponseComponent = ResponseComp;
		OutImpact.ImpactPoint = Hit.ImpactPoint;

		bOutHitWasIgnored = false;

		if(ResponseComp.bIgnoreCollisionWithAllComponents)
		{
			// All components are ignored
			bOutHitWasIgnored = true;
		}
		else
		{
			if(Hit.Component.HasTag(ResponseComp.IgnoreCollisionTag))
			{
				// We have tagged this component to be ignored
				bOutHitWasIgnored = true;
			}
		}
		
		return true;
	}

	bool HasAlreadyImpacted(UIslandEntranceSkydiveObstacleResponseComponent ResponseComp) const
	{
		for(int i = 0; i < Impacts.Num(); i++)
		{
			if(Impacts[i].ResponseComponent == ResponseComp)
				return true;
		}
		
		return false;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		auto SkyDiveComp = UIslandEntranceSkydiveComponent::Get(MovementComponent.Owner);
		SkyDiveComp.OnImpacts(Impacts, ActorsToIgnore, ComponentsToIgnore);
	}
};
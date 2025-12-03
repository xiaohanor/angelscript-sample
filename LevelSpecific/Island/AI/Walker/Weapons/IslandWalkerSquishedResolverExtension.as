class UIslandWalkerSquishedResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(UBaseMovementResolver);
	bool bDepenetrated = false;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UIslandWalkerSquishedResolverExtension>(OtherBase);
		bDepenetrated = Other.bDepenetrated;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		bDepenetrated = false;
	}

	bool PreResolveStartPenetrating(FMovementHitResult IterationHit, FVector&out OutResolvedLocation) override
	{
		if (bDepenetrated)
			return false;

		if(!IterationHit.Actor.IsA(AIslandWalkerHead) && !IterationHit.Actor.IsA(AAIIslandWalker))
			return false;
		
		bDepenetrated = true;
		return false;
	}

	void PostApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::PostApplyResolvedData(MovementComponent);

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(MovementComponent.Owner);

		if (bDepenetrated)
		{
			// Detected depenetration, cause stumble 
			//Debug::DrawDebugSphere(MovementComponent.Owner.ActorLocation, 50.0, 4, FLinearColor::Red);			
			//HealthComp.KillPlayer(nullptr);
		}
	}
};
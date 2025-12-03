class USkylineGeckoThrownMovementResolver : USimpleMovementResolver
{
	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit,
																	 EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		const FQuat Rotation = FQuat::MakeFromZX(Hit.Normal, IterationState.DeltaToTrace.GetSafeNormal());

		// When we hit anything while thrown, snap our location, rotation and world up to the surface
		IterationState.CurrentLocation = Hit.ImpactPoint + Hit.Normal;
		IterationState.CurrentRotation = Rotation;
		IterationState.WorldUp = Hit.Normal;

		for(auto Delta : IterationState.DeltaStates)
		{
			IterationState.OverrideDelta(Delta.Key, FMovementDelta(FVector::ZeroVector, FVector::ZeroVector));
		}

		// We don't want any more iterations on this frame, so just finish
		return EMovementResolverHandleMovementImpactResult::Finish;
	}
};
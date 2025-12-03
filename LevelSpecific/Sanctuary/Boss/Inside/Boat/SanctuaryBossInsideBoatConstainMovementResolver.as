class USanctuaryBossInsideBoatConstainMovementResolver: USteppingMovementResolver
{
	bool PrepareNextIteration() override
	{
		const bool bResult = Super::PrepareNextIteration();

		ConstrainDeltaToWithinBoat();

		return bResult;
	}

	private void ConstrainDeltaToWithinBoat()
	{
		if(!IterationState.PhysicsState.GroundContact.IsValidBlockingHit())
			return;

		if(IterationState.DeltaToTrace.IsNearlyZero())
			return;

		ASanctuaryBossInsideBoat Boat = Cast<ASanctuaryBossInsideBoat>(IterationState.PhysicsState.GroundContact.Actor);
		if(Boat == nullptr)
			return;

		// Add a small padding to the boat radius
		const float BoatRadius = Boat.BoatRadius - 30.0;

		FVector TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		FVector RelativeTargetLocation = Boat.TranslateComp.WorldTransform.InverseTransformPositionNoScale(TargetLocation);
		float RelativeHeight = RelativeTargetLocation.Z;
		RelativeTargetLocation.Z = 0;

		if (RelativeTargetLocation.Size() < BoatRadius)
			return;	// We are within the boat radius, no need to constrain

		RelativeTargetLocation = RelativeTargetLocation.GetClampedToMaxSize(BoatRadius);	// Constrain by clamping our relative horizontal location to be within the boat radius
		RelativeTargetLocation.Z = RelativeHeight;	// Make sure not to change the height

		FVector ClampedTargetLocation = Boat.TranslateComp.WorldTransform.TransformPositionNoScale(RelativeTargetLocation);
		FVector ConstrainedDelta = ClampedTargetLocation - IterationState.CurrentLocation;

		// If the delta didn't change, don't bother constraining it
		if(IterationState.DeltaToTrace.Equals(ConstrainedDelta))
			return;

		// Constrain the delta we want to move this iterations
		IterationState.DeltaToTrace = ConstrainedDelta;

		// Change the internal velocity and delta to be constrained, this lowers the players velocity, which simply setting the DeltaToTrace does not do
		IterationState.OverrideDelta(EMovementIterationDeltaStateType::Horizontal, FMovementDelta(IterationState.GetDelta(EMovementIterationDeltaStateType::Horizontal).Delta, IterationState.DeltaToTrace / IterationTime));
		
		//Debug::DrawDebugLine(Boat.ActorLocation, TargetLocation, FLinearColor::Green, 10.0, 0.0);
		//Debug::DrawDebugArrow(TargetLocation, TargetLocation + IterationState.DeltaToTrace * 20, 10);
	}
};
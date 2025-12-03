class UHoverPerchActorSweepingResolver : USweepingMovementResolver
{
	//This was the original idea of how to stop vertical movement, now we instead apply a force to try to move back the hover perch back to the original Z position.
	FMovementDelta ProjectMovementUponImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const override
	{
		FMovementDelta Delta = DeltaState;
		// Hover perches should only redirect horizontally, never vertically. 
		FVector Normal = Impact.Normal.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		if(Normal.IsNormalized())
			Delta = DeltaState.PlaneProject(Normal);
		
		return Delta;
	}

	// We should never be grounded
	bool CanPerformGroundTrace() const override
	{
		return false;
	}
}
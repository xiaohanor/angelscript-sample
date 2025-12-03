class USanctuaryBoatMovementResolver : USweepingMovementResolver
{
	private const USweepingMovementData BoatMoveData;
	bool bIsPreparing = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		BoatMoveData = Cast<USweepingMovementData>(Movement);

		bIsPreparing = true;
		Super::PrepareResolver(Movement);
		bIsPreparing = false;
	}

	bool IsLeavingGround() const override
	{
		if(Super::IsLeavingGround())
			return true;

		// FB TODO: Overriding this function is VERY ugly, since we can't chain stuff easily
		if(ShouldValidateRemoteSideGroundPosition())
			return false;

		if(bStickToGround && IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			return false;

		if(bIsPreparing)
		{
			// This function is called from PrepareResolver too, where the physics state has not been updated yet
			if(BoatMoveData.OriginalContacts.GroundContact.IsAnyGroundContact())
			{
				FMovementDelta Movement = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
				if(Movement.Delta.DotProduct(BoatMoveData.OriginalContacts.GroundContact.Normal) > KINDA_SMALL_NUMBER)
				{
					// We are trying to leave our original ground
					return true;
				}
			}
		}
		else
		{
			if(IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			{
				FMovementDelta Movement = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
				if(Movement.Delta.DotProduct(IterationState.PhysicsState.GroundContact.Normal) > KINDA_SMALL_NUMBER)
				{
					// We are trying to leave our current ground
					return true;
				}
			}
		}

		return false;

	}

	FMovementDelta ProjectDeltaUponGenericImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const override
	{
		// We only want to project our delta if it is going into the impact
		return DeltaState.LimitToNormal(Impact.Normal);
	}
};
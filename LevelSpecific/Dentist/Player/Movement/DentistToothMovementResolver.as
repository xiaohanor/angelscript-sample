class UDentistToothMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = UDentistToothMovementData;

	UDentistToothMovementData ToothMoveData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		ToothMoveData = Cast<UDentistToothMovementData>(Movement);
	}

	void ApplyGroundEdgeInformation(FMovementHitResult& HitResult, bool bForceEvenIfSet,
									bool bApplyFallOfEdgeDistance) const override
	{
		Super::ApplyGroundEdgeInformation(HitResult, bForceEvenIfSet, bApplyFallOfEdgeDistance);
		
		if(ToothMoveData.bUnstableEdgeIsUnwalkable && HitResult.IsOnUnstableEdge())
		{
			HitResult.bIsWalkable = false;
		}
	}
};
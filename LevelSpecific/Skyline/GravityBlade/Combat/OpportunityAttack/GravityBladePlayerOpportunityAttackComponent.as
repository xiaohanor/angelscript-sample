UCLASS(NotPlaceable)
class UGravityBladePlayerOpportunityAttackComponent : UActorComponent
{
	bool bIsAttacking = false;
	bool bAttackFailed = false;
	
	UPROPERTY(Transient)
	int CurrentSegment = 0;

	FOpportunityAttackSequence CurrentSequence;

	bool IsInFinalSegment() const
	{
		return (CurrentSegment >= (CurrentSequence.Segments.Num() - 1));
	}

	FOpportunityAttackSegment GetCurrentSegment() const
	{
		return CurrentSequence.Segments[CurrentSegment];
	}
};

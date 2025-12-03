event void FOnGravityBladeOpportunityAttackEvent(UGravityBladePlayerOpportunityAttackComponent PlayerOpportunityAttackComp);

class UGravityBladeOpportunityAttackTargetComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	float AttackDistanceFromGrapple = 350.0;

	UPROPERTY(EditAnywhere)
	FName AlignSocket = n"Align";

	float DurationUntilFail;

	private bool bOpportunityAttackEnabled = false;
	private int CurrentAttackSequenceIndex = 0;

	int GetAttackSequenceIndex() const property
	{
		return CurrentAttackSequenceIndex;
	}

	bool IsOpportunityAttackEnabled() const
	{
		return bOpportunityAttackEnabled;
	}

	void EnableOpportunityAttack(int SequenceIndex)
	{
		bOpportunityAttackEnabled = true;
		CurrentAttackSequenceIndex = SequenceIndex;
	}

	void DisableOpportunityAttack()
	{
		bOpportunityAttackEnabled = false;
	}

	FOpportunityAttackSequence GetCurrentSequence(ULocomotionFeatureOpportunityAttack Feature)
	{
		if (ensure(Feature.AnimData.Sequences.IsValidIndex(CurrentAttackSequenceIndex), "Tried to enable an opportunity attack which does not exist, check opportunity attack feature."))
			return Feature.AnimData.Sequences[CurrentAttackSequenceIndex];
		return FOpportunityAttackSequence();	
	}	

	UPROPERTY()
	FOnGravityBladeOpportunityAttackEvent OnOpportunityAttackBegin;
	UPROPERTY()
	FOnGravityBladeOpportunityAttackEvent OnOpportunityAttackSegmentStart;
	UPROPERTY()
	FOnGravityBladeOpportunityAttackEvent OnOpportunityAttackCompleted;
	UPROPERTY()
	FOnGravityBladeOpportunityAttackEvent OnOpportunityAttackStartFailing;
	UPROPERTY()
	FOnGravityBladeOpportunityAttackEvent OnOpportunityAttackFailed;
};
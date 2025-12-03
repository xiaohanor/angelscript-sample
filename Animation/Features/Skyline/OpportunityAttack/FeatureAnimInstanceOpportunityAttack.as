UCLASS(Abstract)
class UFeatureAnimInstanceOpportunityAttack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureOpportunityAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureOpportunityAttackAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentAttack;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentMh;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentFail;

	UPROPERTY()
	bool bOpportunityAttackSuccess = false;
	
	UPROPERTY()
	bool bOpportunityAttackFail = false;

	private UGravityBladePlayerOpportunityAttackComponent OpportunityAttackComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureOpportunityAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureOpportunityAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if ((AnimData.Sequences.Num() > 0) && (AnimData.Sequences[0].Segments.Num() > 0))
		{
			CurrentAttack = AnimData.Sequences[0].Segments[0].Attack;
			CurrentMh = AnimData.Sequences[0].Segments[0].Mh;
			CurrentFail = AnimData.Sequences[0].Segments[0].Fail;
		}

		OpportunityAttackComp = UGravityBladePlayerOpportunityAttackComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		if (OpportunityAttackComp == nullptr)
			return;

		bOpportunityAttackSuccess = OpportunityAttackComp.bIsAttacking;
		bOpportunityAttackFail = OpportunityAttackComp.bAttackFailed;

		if (ensure(OpportunityAttackComp.CurrentSequence.Segments.IsValidIndex(OpportunityAttackComp.CurrentSegment)))
		{
			CurrentAttack = OpportunityAttackComp.CurrentSequence.Segments[OpportunityAttackComp.CurrentSegment].Attack;
			CurrentMh = OpportunityAttackComp.CurrentSequence.Segments[OpportunityAttackComp.CurrentSegment].Mh;
			CurrentFail = OpportunityAttackComp.CurrentSequence.Segments[OpportunityAttackComp.CurrentSegment].Fail;
		}	
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

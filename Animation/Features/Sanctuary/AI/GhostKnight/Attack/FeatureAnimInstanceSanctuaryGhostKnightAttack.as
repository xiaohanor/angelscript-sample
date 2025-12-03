namespace SubTagSanctuaryGhostKnightAttack
{
	const FName ChargeHit = n"ChargeHit";
	const FName ChargeMiss = n"ChargeMiss";
	const FName Melee = n"Melee";
	const FName Recover = n"Recover";
}

struct FSanctuaryGhostKnightAttackSubTags
{
	UPROPERTY()
	FName ChargeHit = SubTagSanctuaryGhostKnightAttack::ChargeHit;	

	UPROPERTY()
	FName ChargeMiss = SubTagSanctuaryGhostKnightAttack::ChargeMiss;	

	UPROPERTY()
	FName Melee = SubTagSanctuaryGhostKnightAttack::Melee;	

	UPROPERTY()
	FName Recover = SubTagSanctuaryGhostKnightAttack::Recover;
}	


UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryGhostKnightAttack : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSanctuaryGhostKnightAttack Feature;

	UPROPERTY()
	FSanctuaryGhostKnightAttackSubTags SubTags;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSanctuaryGhostKnightAttackAnimData AnimData;

	UPROPERTY()
	bool bHasMissed;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureSanctuaryGhostKnightAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureSanctuaryGhostKnightAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bHasMissed = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
    {
		if (CurrentSubTag == SubTagSanctuaryGhostKnightAttack::ChargeMiss)
			bHasMissed = true;

        Super::BlueprintUpdateAnimation(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here
		return (TopLevelGraphRelevantAnimTimeRemaining < 0.1);
	}
}

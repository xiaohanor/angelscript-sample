UCLASS(Abstract)
class UFeatureAnimInstanceNunchuckAttack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureNunchuckAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureNunchuckAttackAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerIslandNunchuckUserComponent MeleeComponent;

	UPROPERTY(BlueprintReadOnly)
	int CurrentAttack;

	UPROPERTY(BlueprintReadOnly)
	int CurrentVariation;

	int PrevAttack;

	UPROPERTY(BlueprintReadOnly)
	float AnimationLength;

	UPROPERTY(BlueprintReadOnly)
	float AttackPlayRate;

	// UPROPERTY(BlueprintReadOnly)
	// EScifiMeleeTargetableDirection RelativeTargetDirection = EScifiMeleeTargetableDirection::None;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureNunchuckAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureNunchuckAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MeleeComponent = UPlayerIslandNunchuckUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		check(false);
		// PrevAttack = CurrentAttack;
		// CurrentAttack = MeleeComponent.GetActiveComboIndex();
		// CurrentVariation = MeleeComponent.GetActiveVariationIndex();
		// AnimationLength = MeleeComponent.CurrentActiveMoveTimeMax;
		// AttackPlayRate = MeleeComponent.CurrentActiveMovePlayRate;
		// RelativeTargetDirection = MeleeComponent.PrimaryTargetRelativeDirection;
		
		// // DEBUG
		// PrintToScreenScaled("Attack Index: " + CurrentAttack + " | Variation: " + CurrentVariation + "Target: " + RelativeTargetDirection, 0.0, Scale = 3.0);
	
	}

	

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true; //TopLevelGraphRelevantAnimTimeRemaining <= SMALL_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

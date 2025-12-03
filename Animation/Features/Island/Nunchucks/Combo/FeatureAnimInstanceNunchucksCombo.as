UCLASS(Abstract)
class UFeatureAnimInstanceNunchucksCombo : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureNunchucksCombo Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureNunchucksComboAnimData AnimData;

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
	
	AHazePlayerCharacter NunchuckPlayer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureNunchucksCombo NewFeature = GetFeatureAsClass(ULocomotionFeatureNunchucksCombo);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Get a reference to the player character, doing this since this AnimInstance will also run on the nunchuck actor
		if (Player != nullptr)
			NunchuckPlayer = Player;
		else {
			// Owner is nunchuck actor 
			auto IslandNunchuckMeshComp = UIslandNunchuckMeshComponent::Get(HazeOwningActor);
			if (IslandNunchuckMeshComp != nullptr)
				NunchuckPlayer = IslandNunchuckMeshComp.PlayerOwner;
		}

		MeleeComponent = UPlayerIslandNunchuckUserComponent::Get(NunchuckPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		check(false); // REFACTORING TYKO
		// if (Feature == nullptr)
		// 	return;

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

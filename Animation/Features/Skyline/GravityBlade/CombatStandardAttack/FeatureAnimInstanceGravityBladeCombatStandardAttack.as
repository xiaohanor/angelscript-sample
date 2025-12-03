


UCLASS(Abstract)
class UFeatureAnimInstanceGravityBladeCombatStandardAttack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBladeCombatStandardAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBladeCombatStandardAttackAnimData AnimData;

	UPROPERTY()
	UPlayerMovementComponent MovementComponent;

	// The gravity blade should not be using the nunchuck component, TYKO
	// UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	// UPlayerIslandNunchuckUserComponent MeleeComponent;

	UPROPERTY()
	UPlayerFloorSlowdownComponent SlowdownComponent;

	UPROPERTY(BlueprintReadOnly)
	int CurrentAttack;

	int PrevAttack;

	UPROPERTY(BlueprintReadOnly)
	float AnimationLength;

	UPROPERTY(BlueprintReadOnly)
	float AttackPlayRate;
	
	UPROPERTY()
	bool bCameFromDash;

	UPROPERTY()
	bool bCameFromSlide;

	UPROPERTY()
	bool bIsInSlowDownState;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityBladeCombatStandardAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBladeCombatStandardAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MovementComponent =  UPlayerMovementComponent::Get(Player);

		//MeleeComponent = UPlayerIslandNunchuckUserComponent::Get(Player);

		SlowdownComponent = UPlayerFloorSlowdownComponent::Get(Player);

		bCameFromDash = (GetPrevLocomotionAnimationTag() == n"Dash");

		bCameFromSlide = (GetPrevLocomotionAnimationTag() == n"Slide");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		PrevAttack = CurrentAttack;
		// The gravity blade should not be using the nunchuck component, TYKO
		// CurrentAttack = MeleeComponent.GetActiveComboIndex();
		// AnimationLength = MeleeComponent.CurrentActiveMoveTimeMax;
		// AttackPlayRate = MeleeComponent.CurrentActiveMovePlayRate;
		// if (PrevAttack != 1&&CurrentAttack==1)
		// PrintToScreen ("Update "+CurrentAttack,1.5, FLinearColor::Red);

		bIsInSlowDownState = SlowdownComponent.bInSlowDownState;
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

	UFUNCTION(BlueprintPure)
	FVector GetHorizontalVelocity() const
	{
		return MovementComponent.GetHorizontalVelocity();
	}
}

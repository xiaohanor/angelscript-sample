UCLASS(Abstract)
class UFeatureAnimInstanceSketchbookMelee : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSketchbookMelee Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSketchbookMeleeAnimData AnimData;

	UPlayerMovementComponent MoveComp;
	USketchbookMeleeAttackPlayerComponent AttackComp;
	UPlayerActionModeComponent ActionModeComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FSketchbookMeleeAttackAnimData AttackAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAttackThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAirAttack;

	bool bWantsToMove;

	int SequenceIndex;
	int AttackIndex;
	FTimerHandle ActionModeTimerHandle;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
		AttackComp = USketchbookMeleeAttackPlayerComponent::Get(Player);
		ActionModeComp = UPlayerActionModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSketchbookMelee NewFeature = GetFeatureAsClass(ULocomotionFeatureSketchbookMelee);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (Feature.bUseActionMh)
			ActionModeComp.ApplyActionMode(EPlayerActionMode::ForceActionMode, this);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		bAttackThisFrame = GetAnimTrigger(n"Attack");
		if (bAttackThisFrame)
		{
			SequenceIndex = AttackComp.AnimData.SequenceIndex;
			AttackIndex = AttackComp.AnimData.AttackIndex;

			bAirAttack = MoveComp.IsInAir();

			devCheck(AnimData.AttackSequences.IsValidIndex(SequenceIndex), f"Invalid SequenceIndex: {SequenceIndex}");

			AttackAnimData = AnimData.AttackSequences[SequenceIndex].Sequence[AttackIndex];

			ActionModeComp.ApplyActionMode(EPlayerActionMode::ForceActionMode, this);

			if(ActionModeTimerHandle.IsValid())
				ActionModeTimerHandle.ClearTimerAndInvalidateHandle();

			ActionModeTimerHandle = Timer::SetTimer(this, n"ClearActionMode", 5);
		}

		if (LocomotionAnimationTag != n"Movement")
			ClearActionMode();

		const bool bIsMovementBlocked = Player.IsCapabilityTagBlocked(CapabilityTags::MovementInput);

		bExitAttack = false;

		if(AttackComp.bAttackFinished)
		{
			if(!bAirAttack && !bIsMovementBlocked && bWantsToMove && Player.ActorVelocity.Size() > 400)
			{
				// This is a ground attack, we are no longer movement blocked, and we are trying to move
				bExitAttack = true;
			}
			else if(!bAirAttack && (LocomotionAnimationTag != "Movement" && LocomotionAnimationTag != "AirMovement"))
			{
				// This is a ground attack, but we are not in default movement locomotion
				bExitAttack = true;
			}
			else if(bAirAttack && (LocomotionAnimationTag != n"Jump" && LocomotionAnimationTag != n"AirMovement"))
			{
				// This is an air attack, but we are no longer in any air movement locomotion
				bExitAttack = true;
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void ClearActionMode()
	{
		ActionModeComp.ClearActionMode(this);

		if(ActionModeTimerHandle.IsValid())
			ActionModeTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		ClearActionMode();
	}

	UFUNCTION(BlueprintOverride)
	void OnUpdateCurrentAnimationStatus(TArray<FName>& OutCurrentAnimationStatus)
	{
		if (bAttackThisFrame || TopLevelGraphRelevantStateName == n"Attack")
			OutCurrentAnimationStatus.Add(n"SketchbookAttack");
	}
}

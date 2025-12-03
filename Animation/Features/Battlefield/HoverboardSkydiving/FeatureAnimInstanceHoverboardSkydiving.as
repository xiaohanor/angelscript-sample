UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardSkydiving : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardSkydiving Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardSkydivingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTrick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EBattlefieldHoverboardTrickType TrickType;

	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComponent = UPlayerMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardSkydiving NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardSkydiving);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.8;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BankingValues = FVector2D(MoveComponent.SyncedMovementInputForAnimationOnly.Y, MoveComponent.SyncedMovementInputForAnimationOnly.X);

		bTrick = false;
		const bool bWantsToTrick = GetAnimTrigger(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
		if (bWantsToTrick)
		{
			const int TrickTypeInt = GetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickType);
			TrickType = EBattlefieldHoverboardTrickType(TrickTypeInt);

			if (LowestLevelGraphRelevantStateName != n"Trick" || LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.4)
				bTrick = bWantsToTrick;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"AirMovement" && LowestLevelGraphRelevantStateName == n"Trick")
			return LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.4;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

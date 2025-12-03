UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardSwinging : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardSwinging Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardSwingingAnimData AnimData;

	UBattlefieldHoverboardSwingComponent SwingComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwingAnimData SwingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TransformAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SwingProgression;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SwingComp = UBattlefieldHoverboardSwingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardSwinging NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardSwinging);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		TransformAlpha = 0;

		const auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		RootOffset = HoverboardComp.GetAnimRootOffset();
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.3;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SwingAnimData = SwingComp.AnimData;

		SwingProgression = Math::GetMappedRangeValueClamped(FVector2D(-60, 30), FVector2D(0, 1), SwingAnimData.SwingRotation.Pitch);

		if (SwingAnimData.State == EPlayerSwingState::Jump || SwingAnimData.State == EPlayerSwingState::Cancel)
		{
			TransformAlpha = Math::FInterpConstantTo(TransformAlpha, 0, DeltaTime, 0.55);
		}
		else if (TransformAlpha < 1)
		{
			TransformAlpha = Math::FInterpConstantTo(TransformAlpha, 1, DeltaTime, 1.75);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
			return true;

		if (LocomotionAnimationTag != n"HoverboardAirMovement" && LocomotionAnimationTag != n"HoverboardJumping")
			return true;

		if (LowestLevelGraphRelevantStateName != n"Exit")
			return false;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

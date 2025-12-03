UCLASS(Abstract)
class UFeatureAnimInstanceBoombox : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBoombox Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBoomboxAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Spin;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EStickSpinDirection SpinState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsZoe;

	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBoombox NewFeature = GetFeatureAsClass(ULocomotionFeatureBoombox);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
		MovementComponent = UPlayerMovementComponent::Get(Player);
		bIsZoe = Player.IsZoe();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		const int SpinStateIndex = GetAnimIntParam(n"BoomBoxSpinState");
		SpinState = EStickSpinDirection(SpinStateIndex);
		bExit = LocomotionAnimationTag != Feature.Tag;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}
		if (!MovementComponent.GetSyncedMovementInputForAnimationOnly().IsNearlyZero())
		{
			return true;
		}
		return TopLevelGraphRelevantStateName == n"Exit" && IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

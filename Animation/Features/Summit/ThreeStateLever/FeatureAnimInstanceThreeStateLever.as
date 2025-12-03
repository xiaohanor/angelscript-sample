UCLASS(Abstract)
class UFeatureAnimInstanceThreeStateLever : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureThreeStateLever Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureThreeStateLeverAnimData AnimData;

	UPlayerMovementComponent MoveComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnterLeft;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureThreeStateLever NewFeature = GetFeatureAsClass(ULocomotionFeatureThreeStateLever);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bEnterLeft = !GetAnimBoolParam(n"GoesToLeft", true);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendspaceValues.X = MoveComponent.SyncedLocalSpaceMovementInputForAnimationOnly.X;
		BlendspaceValues.X = GetAnimFloatParam(n"ThreeStateLeverBlendSpaceAlpha", true);

		bPlayExit = LocomotionAnimationTag != Feature.Tag;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
			return true;

		if (!MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero())
			return true;

		return TopLevelGraphRelevantStateName == n"Exit" && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

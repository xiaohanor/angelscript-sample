UCLASS(Abstract)
class UFeatureAnimInstanceElevatorWheel : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureElevatorWheel Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureElevatorWheelAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTurningWheel = false;

	UPlayerMovementComponent MoveComponent;

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
		ULocomotionFeatureElevatorWheel NewFeature = GetFeatureAsClass(ULocomotionFeatureElevatorWheel);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bPlayExit = LocomotionAnimationTag != Feature.Tag;
		bIsTurningWheel = GetAnimBoolParam(n"Is Spinning Lift Wheel");
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

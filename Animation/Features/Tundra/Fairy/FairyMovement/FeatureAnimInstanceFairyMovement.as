UCLASS(Abstract)
class UFeatureAnimInstanceFairyMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFairyMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFairyMovementAnimData AnimData;

	UPlayerMovementComponent MovementComponent;

	UPlayerFloorMotionComponent FloorMoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	bool bTurnaroundTriggered;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFairyMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureFairyMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MovementComponent = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);
		FloorMoveComp = UPlayerFloorMotionComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MovementComponent.Velocity.Size();

		bWantsToMove = !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		const float RotationRate = (MovementComponent.GetMovementYawVelocity(false) / 500.0);
		Banking = Math::Clamp(RotationRate * (Speed / 450), -1.0, 1.0);

		bTurn180 = CheckValueChangedAndSetBool(bTurnaroundTriggered, FloorMoveComp.AnimData.bTurnaroundTriggered, EHazeCheckBooleanChangedDirection::FalseToTrue);
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
}

UCLASS(Abstract)
class UFeatureAnimInstanceWalkingStickMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWalkingStickMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWalkingStickMovementAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraWalkingStickAnimData WalkingStickAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	ATundraWalkingStick WalkingStick;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		WalkingStick = Cast<ATundraWalkingStick>(HazeOwningActor);

	MoveComp = UHazeMovementComponent::Get(WalkingStick);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWalkingStickMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureWalkingStickMovement);
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

		WalkingStickAnimData = WalkingStick.AnimData;

		Speed=MoveComp.Velocity.Size();
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

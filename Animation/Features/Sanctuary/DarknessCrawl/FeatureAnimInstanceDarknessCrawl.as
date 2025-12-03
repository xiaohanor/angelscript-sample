UCLASS(Abstract)
class UFeatureAnimInstanceDarknessCrawl : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDarknessCrawl Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDarknessCrawlAnimData AnimData;

	UPlayerMovementComponent MoveComp;

	UPROPERTY()
	bool bHasInput;

	UPROPERTY()
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDarknessCrawl NewFeature = GetFeatureAsClass(ULocomotionFeatureDarknessCrawl);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MoveComp.Velocity.Size();

		bHasInput = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Movement")
			SetAnimFloatParam(n"MovementBlendTime", 0.6);
	}
}

UCLASS(Abstract)
class UFeatureAnimInstanceSkippingStones : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSkippingStones Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSkippingStonesAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	USkippingStonesPlayerComponent SkippingStoneComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerAimingComponent AimComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimAnglePitch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AimAngleYaw;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LookAtAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Charge;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSkippingStones NewFeature = GetFeatureAsClass(ULocomotionFeatureSkippingStones);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SkippingStoneComp = USkippingStonesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bAim = SkippingStoneComp.bIsCharging;
		bThrow = GetAnimTrigger(n"Throw");

		Charge = GetAnimFloatParam(n"SkippingStoneCharge", true);

		if (AimComp.IsAiming(SkippingStoneComp))
		{
			const FAimingResult AimResult = AimComp.GetAimingTarget(SkippingStoneComp);

			const FVector RelativeAimDirection = SkippingStoneComp.SkippingStonesInteraction.InteractionComp.WorldTransform.InverseTransformVectorNoScale(AimResult.AimDirection);
			const FRotator RelativeAimRotation = FRotator::MakeFromZX(FVector::UpVector, RelativeAimDirection);
			AimAnglePitch = RelativeAimRotation.Pitch;
			AimAngleYaw = RelativeAimRotation.Yaw;
		}

		bPlayExit = LocomotionAnimationTag != Feature.Tag;

		if (bAim)
			LookAtAlpha = 1;
		else if (LowestLevelGraphRelevantStateName == n"Mh")
			LookAtAlpha = 0.5;
		else if (LowestLevelGraphRelevantStateName == n"Throw")
			LookAtAlpha = Math::FInterpTo(LookAtAlpha, 0, DeltaTime, 5);
		else
			LookAtAlpha = 0;
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

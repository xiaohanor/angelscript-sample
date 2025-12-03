UCLASS(Abstract)
class UFeatureAnimInstanceApexDive : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureApexDive Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureApexDiveAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureApexDive NewFeature = GetFeatureAsClass(ULocomotionFeatureApexDive);
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
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		const FTransform HipsTransform = OwningComponent.GetSocketTransform(n"Hips", ERelativeTransformSpace::RTS_ParentBoneSpace);
		const float Dot = HipsTransform.TransformVectorNoScale(FVector::UpVector).DotProduct(FVector::UpVector);
		const float HipsRotation = Math::Clamp(Math::RadiansToDegrees(Math::Asin(Dot)) - 10, -180, 0);
		SetAnimFloatParam(n"SwimPitchRotationFloat", HipsRotation);
	}
}

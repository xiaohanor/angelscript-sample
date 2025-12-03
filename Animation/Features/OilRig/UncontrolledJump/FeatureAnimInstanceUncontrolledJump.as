UCLASS(Abstract)
class UFeatureAnimInstanceUncontrolledJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureUncontrolledJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureUncontrolledJumpAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsAdditionalRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWindGust;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureUncontrolledJump NewFeature = GetFeatureAsClass(ULocomotionFeatureUncontrolledJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		HipsAdditionalRotation = FRotator(30, 0 ,0);
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.4;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		HipsAdditionalRotation.Pitch = Math::FInterpTo(HipsAdditionalRotation.Pitch, -60, DeltaTime, 1.2);

		bWindGust = GetAnimBoolParam(n"WindGust", true);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Skydive")
		{
			SetAnimBoolParam(n"SkipSkydiveStart", true);
			SetAnimFloatParam(n"SkydiveBlendTime", 0.7);
		}
	}
}

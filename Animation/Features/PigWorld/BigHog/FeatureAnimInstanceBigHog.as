UCLASS(Abstract)
class UFeatureAnimInstanceBigHog : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBigHog Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBigHogAnimData AnimData;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ABigHog BigHog;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SpineScaleMultiplier = FVector::OneVector;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		BigHog = Cast<ABigHog>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBigHog NewFeature = GetFeatureAsClass(ULocomotionFeatureBigHog);
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

		float Jiggle = Math::Sin(Time::GameTimeSeconds * 50) * 0.01;
		// Jiggle = 0;
		SpineScaleMultiplier = FVector::OneVector + BigHog.GetFartBoneScale();
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

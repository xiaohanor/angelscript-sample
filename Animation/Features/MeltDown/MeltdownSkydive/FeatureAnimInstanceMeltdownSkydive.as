UCLASS(Abstract)
class UFeatureAnimInstanceMeltdownSkydive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureMeltdownSkydive Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D Input;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int BarrelRollDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int HitReactionDirection;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMeltdownSkydiveAnimData AnimData;

	UMeltdownSkydiveComponent SkydiveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureMeltdownSkydive NewFeature = GetFeatureAsClass(ULocomotionFeatureMeltdownSkydive);
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

		Input = SkydiveComp.AnimData.SkydiveInput;
		BarrelRollDirection = SkydiveComp.AnimData.BarrelRollDirection;
		HitReactionDirection = SkydiveComp.AnimData.HitReactionDirection;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const

	{
		//if (PrevLocomotionAnimationTag == n"MeltdownSkydive")
		//return 0.8;
	//else
		return 0.2;
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

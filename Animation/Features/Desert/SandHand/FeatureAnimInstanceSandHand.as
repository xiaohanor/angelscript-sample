UCLASS(Abstract)
class UFeatureAnimInstanceSandHand : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSandHand Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSandHandAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	USandHandPlayerComponent SandHandPlayerComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLeft;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSandHand NewFeature = GetFeatureAsClass(ULocomotionFeatureSandHand);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SandHandPlayerComponent = USandHandPlayerComponent::Get(HazeOwningActor);
		if (SandHandPlayerComponent == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (SandHandPlayerComponent == nullptr)
			return;

		bShoot = SandHandPlayerComponent.ShotThisFrame();
		bLeft = SandHandPlayerComponent.bSandHandLeft;
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

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetShootPlayRate(FHazePlaySequenceData Data)
	{
		if (SandHand::ShootDelay > 0.0)
		{
			return Data.Sequence.PlayLength / (SandHand::ShootDelay * 3);	// * 3 because the first 1/3 of the animation is the actual punching
		}

		return 1.0;
	}
}

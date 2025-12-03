UCLASS(Abstract)
class UFeatureAnimInstanceLandingAdditive : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLandingAdditive Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLandingAdditiveAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MoveComp;
	UPlayerLandingComponent LandingComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerLandingAnimationData LandingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalVelocity;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLandingAdditive NewFeature = GetFeatureAsClass(ULocomotionFeatureLandingAdditive);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		MoveComp = UPlayerMovementComponent::Get(Player);
		LandingComp = UPlayerLandingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		LandingAnimData = LandingComp.AnimData;

		HorizontalVelocity = MoveComp.HorizontalVelocity.Size2D();
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}

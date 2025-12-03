UCLASS(Abstract)
class UFeatureAnimInstanceGravityBladeOverride : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBladeOverride Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBladeOverrideAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBlockOverride;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGravityBladeOverride NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBladeOverride);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		MoveComp =  UPlayerMovementComponent::Get(Player);
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

		Speed = MoveComp.HorizontalVelocity.Size();

		bIsMovement = LocomotionAnimationTag == n"Movement";

		if (LocomotionAnimationTag != n"Movement" || GetAnimBoolParam(n"RequestingBlockOverrideAnimation"))
			bBlockOverride = true;
		else 
			bBlockOverride = false;

		#if EDITOR
		
		#endif
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


	UFUNCTION(BlueprintOverride)
	float GetBlendTimeToNullFeature() const
	{
		return 0.0;
	}


}

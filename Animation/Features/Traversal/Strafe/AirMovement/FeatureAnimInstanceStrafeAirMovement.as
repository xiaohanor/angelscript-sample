
UCLASS(Abstract)
class UFeatureAnimInstanceStrafeAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStrafeAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStrafeAirMovementAnimData AnimData;

	// Add Custom Variables Here

	UPlayerStrafeComponent StrafeComponent;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData StrafeAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector2D FallingDirectionBS;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStrafeAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureStrafeAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);

		if (PrevLocomotionAnimationTag == n"StrafeJump" || PrevLocomotionAnimationTag == n"StrafeAirDash")
		{
			bSkipStart = true;
		}
		else
			bSkipStart = false;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.3;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		StrafeAnimData = StrafeComponent.AnimData;

		FallingDirectionBS = StrafeAnimData.BlendSpaceVector;

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

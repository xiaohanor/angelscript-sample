UCLASS(Abstract)
class UFeatureAnimInstanceStrafeAirDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStrafeAirDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStrafeAirDashAnimData AnimData;

	// Add Custom Variables Here

	
	UPlayerStrafeComponent StrafeComponent;
	UPlayerMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData StrafeAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector2D FallingDirectionBS;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SignedForwardAlignedSpeed = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SignedRightAlignedSpeed = 0;
	


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStrafeAirDash NewFeature = GetFeatureAsClass(ULocomotionFeatureStrafeAirDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		//SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.0;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		StrafeAnimData = StrafeComponent.AnimData;

		FallingDirectionBS = StrafeAnimData.BlendSpaceVector;

		SignedForwardAlignedSpeed = MoveComp.HorizontalVelocity.DotProduct(Player.ActorForwardVector) / 1300;
		SignedRightAlignedSpeed = MoveComp.HorizontalVelocity.DotProduct(Player.ActorRightVector) / 1300;

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if(LocomotionAnimationTag != n"StrafeAir" || IsLowestLevelGraphRelevantAnimFinished())
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here

		SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
	}
}

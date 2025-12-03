UCLASS(Abstract)
class UFeatureAnimInstanceBabyDragonClimbing : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBabyDragonClimbing Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBabyDragonClimbingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ETailBabyDragonAnimationState BabyDragonState = ETailBabyDragonAnimationState::Idle;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ClimbDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInAir;

	private UPlayerTailBabyDragonComponent DragonComp;

	UPlayerMovementComponent PlayerMoveComp;
	

	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBabyDragonClimbing NewFeature = GetFeatureAsClass(ULocomotionFeatureBabyDragonClimbing);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		DragonComp = UPlayerTailBabyDragonComponent::Get(HazeOwningActor);
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BabyDragonState = DragonComp.AnimationState.Get();
		ClimbDirection = FVector2D(DragonComp.AnimationClimbDirection.Yaw, DragonComp.AnimationClimbDirection.Pitch);
		bInAir = PlayerMoveComp.IsInAir();
		
		
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

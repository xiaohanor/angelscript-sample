UCLASS(Abstract)
class UFeatureAnimInstanceTailTeenDragon : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTailTeenDragon Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTailTeenDragonAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	protected ATeenDragon TeenDragon;

	UPROPERTY(BlueprintReadOnly)
	float ForwardBackwardAlpha = 0;

	UPROPERTY(BlueprintReadOnly)
	float LeftRightAlpha = 0;

	UPROPERTY(BlueprintReadOnly)
	ETeenDragonAnimationState AnimationState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPlayerTailTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTailTeenDragon NewFeature = GetFeatureAsClass(ULocomotionFeatureTailTeenDragon);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
		DragonComp = Cast<UPlayerTailTeenDragonComponent>(TeenDragon.DragonComponent);
		MoveComp = UHazeMovementComponent::Get(DragonComp.Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		AnimationState = DragonComp.AnimationState.Get();
		ForwardBackwardAlpha = DragonComp.AnimationForwardBackwardAlpha;
		LeftRightAlpha = DragonComp.AnimationLeftRightAlpha;
		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;		
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

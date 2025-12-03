UCLASS(Abstract)
class UFeatureAnimInstanceControlledBabyDragonDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureControlledBabyDragonDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureControlledBabyDragonDashAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPlayerMovementComponent MovementComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureControlledBabyDragonDash NewFeature = GetFeatureAsClass(ULocomotionFeatureControlledBabyDragonDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MovementComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = MovementComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TopLevelGraphRelevantAnimTimeRemaining <= 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

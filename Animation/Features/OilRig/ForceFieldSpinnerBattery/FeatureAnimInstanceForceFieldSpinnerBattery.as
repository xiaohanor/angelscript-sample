UCLASS(Abstract)
class UFeatureAnimInstanceForceFieldSpinnerBattery : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureForceFieldSpinnerBattery Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureForceFieldSpinnerBatteryAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeAcceleratedFloat PullFraction;

	UPlayerMovementComponent MovementComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureForceFieldSpinnerBattery NewFeature = GetFeatureAsClass(ULocomotionFeatureForceFieldSpinnerBattery);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MovementComponent = UPlayerMovementComponent::Get(Player);

		PullFraction.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bExit = LocomotionAnimationTag != Feature.Tag;
		if (!bExit)
		{
			const float PullFractionTarget = GetAnimFloatParam(n"ForceFieldSpinnerBatteryProgress", false);
			PullFraction.AccelerateTo(PullFractionTarget, 0.5, DeltaTime);
		}

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// if (LocomotionAnimationTag != n"Movement")
			// return true;

		if (Player.IsAnyCapabilityActive(n"Knockdown"))
			return true;

		const bool bWantsToMove = !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		if (bWantsToMove)
			return true;

		if (LowestLevelGraphRelevantStateName == n"Enter")
			return TopLevelGraphRelevantAnimTime < 0.35;

		if (TopLevelGraphRelevantStateName != n"Exit")
			return false;

		return IsTopLevelGraphRelevantAnimFinished();
	}
}

UCLASS(Abstract)
class UFeatureAnimInstanceTeenDragonLedgeDown : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTeenDragonLedgeDown Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTeenDragonLedgeDownAnimData AnimData;

	// Add Custom Variables Here

	UHazeMovementComponent MoveComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeAnimSlopeAlignComponent AnimSlopeAlignComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput TraceInputData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableFootIK;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnableIK;

	FTimerHandle EnableIKTimerHandle;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
		auto DragonComp = Cast<UPlayerTeenDragonComponent>(TeenDragon.DragonComponent);
		MoveComp = UHazeMovementComponent::Get(DragonComp.Owner);

		FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
		if (FootTraceComp != nullptr)
			FootTraceComp.SetMovementComp(MoveComp);

		AnimSlopeAlignComponent = UHazeAnimSlopeAlignComponent::GetOrCreate(DragonComp.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTeenDragonLedgeDown NewFeature = GetFeatureAsClass(ULocomotionFeatureTeenDragonLedgeDown);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		AnimSlopeAlignComponent.InitializeSlopeTransformData(SlopeOffset, SlopeRotation, bSnapIfNoPrevRequest = true);
		bEnableIK = false;
		bEnableFootIK = false;

		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(TraceInputData);

		EnableIKTimerHandle = Timer::SetTimer(this, n"EnableIK", 0.4);
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

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		if (bEnableIK)
		{
			bEnableFootIK = FootTraceComp != nullptr && FootTraceComp.AreRequirementsMet();
			if (bEnableFootIK)
				FootTraceComp.TraceFeet(TraceInputData);

			AnimSlopeAlignComponent.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		const bool bWantsToMoveLocal = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		if (bWantsToMoveLocal)
			return true;

		// If any tag that's not movement is requested, leave this abp.
		if (LocomotionAnimationTag != n"Movement")
			return true;

		// Finish playing the animation before leaving
		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Movement" && TopLevelGraphRelevantStateName == n"LedgeDownJog")
		{
			SetAnimBoolParam(n"SkipMovementStart", true);
			SetAnimBlendTimeToMovement(HazeOwningActor, 0.1);

			SetAnimFloatParam(n"ForceJogTime", 0.1);
		}

		EnableIKTimerHandle.ClearTimer();
	}

	UFUNCTION()
	void EnableIK()
	{
		AnimSlopeAlignComponent.InitializeSlopeTransformData(SlopeOffset, SlopeRotation, bSnapIfNoPrevRequest = true);
		bEnableIK = true;
	}
}

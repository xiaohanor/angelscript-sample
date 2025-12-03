UFUNCTION(BlueprintCallable)
void SetAnimSnowMonkeyAllowPhysAnimInCutscenes(bool bAllow)
{
	AHazeCharacter Shape = UTundraPlayerShapeshiftingComponent::Get(Game::Mio).GetShapeComponentForType(ETundraShapeshiftShape::Big).GetShapeActor();
	auto Comp = UHazePhysicalAnimationComponent::GetOrCreate(Shape);
	if (Comp != nullptr)
		Comp.bAllowInSequence = bAllow;
}

UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyMovementAnimData AnimData;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeMovementComponent MoveComp;
	UPlayerFloorMotionComponent FloorMoveComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SlopeData")
	float SlopeAlignAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAFKIdle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurnClockwise;

	UPROPERTY(Transient)
	float IdleTimer;

	float AFKIdleTriggerTime;
	FQuat CachedActorRotation;
	FTimerHandle GestureTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
		FloorMoveComp = UPlayerFloorMotionComponent::GetOrCreate(HazeOwningActor.AttachParentActor);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);

		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true);

		IdleTimer = 0;

		CachedActorRotation = HazeOwningActor.ActorQuat;

		AFKIdleTriggerTime = Feature.AFKIdleTimeRange.Rand();

		bPlayGesture = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MoveComp.Velocity.Size();

		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}

		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		bAFKIdle = IdleTimer > AFKIdleTriggerTime;

		if (bWantsToMove)
		{
			IdleTimer = 0;
			AFKIdleTriggerTime = Feature.AFKIdleTimeRange.Rand();
			SlopeAlignAlpha = 0.6;
		}
		else
		{
			SlopeAlignAlpha = 0.35;
			IdleTimer += DeltaTime;
		}

		// Set some slope data
		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);

		bTurn180 = FloorMoveComp.AnimData.bTurnaroundTriggered;
		bTurnClockwise = SnowMonkeyComp.TurnAroundAnimData.bTurnaroundIsClockwise;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION()
	void AnimNotify_EnteredMh()
	{
		// Make sure the feature has some gestures
		if (AnimData.Gestures.GetNumAnimations() == 0)
			return;

		const float GestureTime = Feature.GestureTimeRange.Rand();

		GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);
	}

	UFUNCTION()
	void PlayGesture()
	{
		bPlayGesture = true;
	}

	UFUNCTION()
	void AnimNotify_ResetPlayGesture()
	{
		bPlayGesture = false;
		GestureTimer.ClearTimer();
		bSkipStart = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		bPlayGesture = false;
		GestureTimer.ClearTimer();
	}
}

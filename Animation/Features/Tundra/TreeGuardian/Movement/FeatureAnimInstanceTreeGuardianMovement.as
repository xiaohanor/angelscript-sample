UCLASS()
class UFeatureAnimInstanceTreeGuardianMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianMovementAnimData AnimData;

	UHazeMovementComponent MoveComp;
	UPlayerFloorMotionComponent FloorMoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UHazeAnimPlayerLookAtComponent AnimLookAtComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	// Speed
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn180;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurnClockwise;

	bool bTurnaroundTriggered;

	FQuat CachedActorRotation;
	FTimerHandle GestureTimer;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		MoveComp = UHazeMovementComponent::Get(ParentPlayer);

		AnimLookAtComp = UHazeAnimPlayerLookAtComponent::GetOrCreate(HazeOwningActor);
		AnimLookAtComp.SetPlayer(ParentPlayer);
		FloorMoveComp = UPlayerFloorMotionComponent::GetOrCreate(HazeOwningActor.AttachParentActor);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreeGuardianMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CachedActorRotation = HazeOwningActor.ActorQuat;

		bSkipStart = GetAnimBoolParam(HazeAnimParamTags::SkipMovementStart, true);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(HazeAnimParamTags::MovementBlendTime, true, 0.2f);
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

		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		bTurn180 = CheckValueChangedAndSetBool(bTurnaroundTriggered, FloorMoveComp.AnimData.bTurnaroundTriggered, EHazeCheckBooleanChangedDirection::FalseToTrue);
		bTurnClockwise = TreeGuardianComp.TurnAroundAnimData.bTurnaroundIsClockwise;
	}

	UFUNCTION()
	void AnimNotify_EnteredMh()
	{
		// Make sure the feature has some gestures
		if (AnimData.Gestures.GetNumAnimations() == 0)
			return;

		const float GestureTime = Math::RandRange(Feature.GestureTimeRange.X, Feature.GestureTimeRange.Y);
		GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);
	}

	UFUNCTION()
	void AnimNotify_LeftMh()
	{
		bSkipStart = false;
		bPlayGesture = false;
		GestureTimer.ClearTimer();
	}

	UFUNCTION()
	void PlayGesture()
	{
		bPlayGesture = true;
	}
}

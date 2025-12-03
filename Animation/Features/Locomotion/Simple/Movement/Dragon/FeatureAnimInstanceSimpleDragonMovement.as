UCLASS(Abstract)
class UFeatureAnimInstanceSimpleDragonMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleDragonMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleDragonMovementAnimData AnimData;

	UHazeMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;
	UPlayerAcidTeenDragonComponent AcidDragonComp;
	UAnimFootTraceComponent FootTraceComp;
	UHazeAnimSlopeAlignComponent AnimSlopeAlignComponent;

	AHazePlayerCharacter RidingPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprinting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput TraceInputData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableFootIK;

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
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int RndGestureIndex = -1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFiringAcid;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bForceJog;

	bool bCameFromDragonDash;

	FQuat CachedActorRotation;
	FTimerHandle GestureTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTailDragon;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		const auto DragonOwner = Cast<ATeenDragon>(HazeOwningActor);
		RidingPlayer = Cast<AHazePlayerCharacter>(DragonOwner.DragonComponent.Owner);

		MoveComp = UHazeMovementComponent::Get(RidingPlayer);
		DragonComp = UPlayerTeenDragonComponent::Get(RidingPlayer);
		AcidDragonComp = Cast<UPlayerAcidTeenDragonComponent>(DragonComp);

		bIsTailDragon = DragonComp.IsTailDragon();

		FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
		if (FootTraceComp != nullptr)
			FootTraceComp.SetMovementComp(MoveComp);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleDragonMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleDragonMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		AnimSlopeAlignComponent = UHazeAnimSlopeAlignComponent::GetOrCreate(DragonComp.Owner);
		AnimSlopeAlignComponent.InitializeSlopeTransformData(SlopeOffset, SlopeRotation, bSnapIfNoPrevRequest = true);
		CachedActorRotation = HazeOwningActor.ActorQuat;

		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true) && !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(TraceInputData);

		bPlayGesture = false;

		float ForceJogTime = GetAnimFloatParam(n"ForceJogTime");
		if (ForceJogTime > 0)
		{
			bForceJog = true;
			Timer::SetTimer(this, n"StopForceJog", ForceJogTime);
		} 
	}

	UFUNCTION()
	void StopForceJog()
	{
		bForceJog = false;
	}


	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(n"MovementBlendTime", true, 0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr || MoveComp == nullptr)
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

		if (AcidDragonComp != nullptr)
		{
			bIsFiringAcid = AcidDragonComp.bIsFiringAcid;
		}

		// Banking
		Banking = CalculateAnimationBankingValue(RidingPlayer, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);
		bIsSprinting = DragonComp.bIsSprinting;

		// Foot IK
		bEnableFootIK = FootTraceComp != nullptr && FootTraceComp.AreRequirementsMet();
		if (bEnableFootIK)
			FootTraceComp.TraceFeet(TraceInputData);

		AnimSlopeAlignComponent.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);

		// Gestures
		if (!bIsTailDragon && bIsFiringAcid && LowestLevelGraphRelevantStateName == n"Mh")
		{
			GestureTimer.ClearTimer();
			const float GestureTime = Math::RandRange(Feature.GestureTimeRange.X, Feature.GestureTimeRange.Y);
			GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		GestureTimer.ClearTimer();
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
		if (!bIsTailDragon && AcidDragonComp.bIsFiringAcid)
		{
			const float GestureTime = Math::RandRange(Feature.GestureTimeRange.X, Feature.GestureTimeRange.Y);
			GestureTimer = Timer::SetTimer(this, n"PlayGesture", GestureTime);

			return;
		}

		const int PreviousIndex = RndGestureIndex;

		const UAnimSequence Animation = Feature.AnimData.Gestures.GetRandomAnimation();
		RndGestureIndex = Feature.AnimData.Gestures.GetIndexFromAnimation(Animation);

		// Make sure we're not picking the same animation twice
		if (RndGestureIndex == PreviousIndex)
			RndGestureIndex = Math::WrapIndex(RndGestureIndex + 1, 0, AnimData.Gestures.NumAnimations);

		bPlayGesture = true;
		RidingPlayer.Mesh.SetAnimIntParam(n"GestureNumber", RndGestureIndex);
		RidingPlayer.Mesh.SetAnimBoolParam(n"PlayDragonGesture", true);
	}
}

enum EDentistIKState
{
	None,
	ArmIK,
	FullBody
}

UCLASS(Abstract)
class UFeatureAnimInstanceDentistBoss : UHazeAnimInstanceBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY()
	ULocomotionFeatureDentistBoss Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDentistBossAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EDentistBossAnimationState CurrentState;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	FTransform LeftUpperHandTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	FTransform RightUpperHandTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	FTransform LeftLowerHandTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	FTransform RightLowerHandTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	bool bUseRightUpperHandTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	bool bUseRightLowerHandTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	bool bUseLeftUpperHandTransform;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "IK")
	bool bUseLeftLowerHandTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK")
	EDentistIKState IKState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D LeanBlendSpaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLookAtEnabled = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EyeSpeed = 1.0;

	// CHAIR
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRightPlayerEscapedChair = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLeftPlayerEscapedChair = false;

	// DRILL
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrillFoundPlayer = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrillFinished = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrillExit = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrillSpinArena = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DrillingPlayerWobble = 0.0;

	// TOOTH BRUSH
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bToothPasteFirst = false;

	// DENTURES
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDenturesAttachedRightHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDenturesAttachedLeftHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DenturesBitingAlpha = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDenturesDestroyedHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDenturesFellDown = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSwatLeftHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingSwatLeftAnim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSwatRightHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayingSwatRightAnim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPreviousArmDestroyedWasLeft = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDenturesDrillOverride = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CloseMouthMaskAgainAlpha = 0.0;

	// CUPS
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCupCaptureTelegraphDone = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EDentistBossToolCupSortType CurrentSortType = EDentistBossToolCupSortType::None;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CupSortAnimSpeed = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCupChosen = false;

	// HOOK HAMMER
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHookTelegraphDone = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHammerPlayer = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHammerSplitPlayer = false;

	// FINISHER
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFinisherStarted = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float FinisherProgress = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFinisherCompleted = false;

	EDentistIKState AnimIKState = EDentistIKState::None;
	ADentistBoss DentistActor;
	UDentistBossTargetComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		DentistActor = Cast<ADentistBoss>(HazeOwningActor);
		TargetComp = UDentistBossTargetComponent::Get(DentistActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (Feature != nullptr)
			AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (DentistActor == nullptr)
			return;

		CurrentState = DentistActor.CurrentAnimationState.Get();

		// IK
		if (AnimIKState != EDentistIKState::None)
			IKState = AnimIKState;
		else
			IKState = DentistActor.CurrentIKState.Get();

		LeftUpperHandTargetTransform = DentistActor.LeftUpperHandTargetingTransform;
		RightUpperHandTargetTransform = DentistActor.RightUpperHandTargetingTransform;
		LeftLowerHandTargetTransform = DentistActor.LeftLowerHandTargetingTransform;
		RightLowerHandTargetTransform = DentistActor.RightLowerHandTargetingTransform;

		LeanBlendSpaceValues = DentistActor.LeanBlendSpaceValues.Get();

		// LOOK AT
		bLookAtEnabled = DentistActor.LookAtEnabled.Get();
		LookAtTarget = TargetComp.LookTargetLocation;
		EyeSpeed = DentistActor.EyeSpeed;

		// CHAIR
		bRightPlayerEscapedChair = DentistActor.bRightPlayerEscapedChair;
		bLeftPlayerEscapedChair = DentistActor.bLeftPlayerEscapedChair;

		// DRILL
		bDrillFoundPlayer = DentistActor.bDrillFoundPlayer;
		bDrillFinished = DentistActor.bDrillFinished;
		bDrillExit = DentistActor.bDrillExit;
		bDrillSpinArena = DentistActor.bDrillSpinArena;
		DrillingPlayerWobble = DentistActor.DrillingPlayerWobble;

		// TOOTH BRUSH / PASTE
		bToothPasteFirst = (DentistActor.CurrentState == EDentistBossState::ToothBrushTwo);

		// DENTURES
		bDenturesAttachedLeftHand = DentistActor.bDenturesAttachedLeftHand;
		bDenturesAttachedRightHand = DentistActor.bDenturesAttachedRightHand;

		bDenturesFellDown = DentistActor.bDenturesFellDown;
		bDenturesDestroyedHand = DentistActor.bDenturesDestroyedHand;

		DenturesBitingAlpha = DentistActor.DenturesBitingAlpha;
		CloseMouthMaskAgainAlpha = DentistActor.CloseMouthMaskAgainAlpha;

		if(DentistActor.bSwatLeftHand)
		{
			bSwatLeftHand = true;
			DentistActor.bSwatLeftHand = false;
		}
		else
			bSwatLeftHand = false;
		if(DentistActor.bSwatRightHand)
		{
			bSwatRightHand = true;
			DentistActor.bSwatRightHand = false;
		}
		else
			bSwatRightHand = false;

		bPreviousArmDestroyedWasLeft = DentistActor.bPreviousArmDestroyedWasLeft;

		if (bSwatLeftHand)
			bIsPlayingSwatLeftAnim = true;

		if (bSwatRightHand)
			bIsPlayingSwatRightAnim = true;
		
		if(DentistActor.CurrentState == EDentistBossState::DentureSpawningTwo
		|| DentistActor.CurrentState == EDentistBossState::DenturesSpawnedTwo)
			bDenturesDrillOverride = true;
		else
			bDenturesDrillOverride = false;

		// CUPS
		bCupCaptureTelegraphDone = DentistActor.bCupCaptureTelegraphDone;
		CurrentSortType = DentistActor.CurrentSortType;
		CupSortAnimSpeed = DentistActor.CupSortAnimSpeed;
		bCupChosen = DentistActor.bCupChosen;

		// HOOK HAMMER
		bHookTelegraphDone = DentistActor.bHookTelegraphDone;
		bHammerPlayer = DentistActor.bHammerPlayer;
		bHammerSplitPlayer = DentistActor.bHammerSplitPlayer;

		// FINISHER
		bFinisherStarted = DentistActor.bFinisherDoubleInteractStarted;
		FinisherProgress = DentistActor.FinisherProgress;
		bFinisherCompleted = DentistActor.bFinisherCompleted;
	}

	UFUNCTION(BlueprintOverride, meta = (BlueprintThreadSafe))
	void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	{
		bUseRightUpperHandTransform = !RightUpperHandTargetTransform.Equals(FTransform::Identity);
		bUseRightLowerHandTransform = !RightLowerHandTargetTransform.Equals(FTransform::Identity);
		bUseLeftUpperHandTransform = !LeftUpperHandTargetTransform.Equals(FTransform::Identity);
		bUseLeftLowerHandTransform = !LeftLowerHandTargetTransform.Equals(FTransform::Identity);
	}

	UFUNCTION()
	void AnimNotify_EnableHandIK()
	{
		AnimIKState = EDentistIKState::ArmIK;
	}

	UFUNCTION()
	void AnimNotify_DisableHandIK()
	{
		AnimIKState = EDentistIKState::None;
	}

	UFUNCTION()
	void AnimNotify_SwatLeftFinished()
	{
		bIsPlayingSwatLeftAnim = false;
	}

	UFUNCTION()
	void AnimNotify_SwatRightFinished()
	{
		bIsPlayingSwatRightAnim = false;
	}
}


UCLASS(Abstract)
class UFeatureAnimInstanceJump : UHazeFeatureSubAnimInstance
{

	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureJumpAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MovementComponent;
	UPlayerLandingComponent LandingComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirMotionComponent AirMoveComp;
	UPlayerSprintComponent SprintComp;
	FPlayerLandingAnimationData LandingAnimData;
	UAnimFootTraceComponent FootTraceComp;
	UPlayerAirJumpComponent AirJumpComp;
	UPlayerLedgeMantleComponent LedgeMantleComp;
	UPlayerRollDashComponent RollDashComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIK;

	UPROPERTY()
	EJumpingAnimationType JumpType;

	float JumpTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PrevMoveSpeed;

	UPROPERTY()
	float CurrentMoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InterpolatedMoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromJog;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromSprint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingAirJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingRollDashJump;

	UPROPERTY()
	float StartPosition;

	UPROPERTY()
	float JumpPlayRate;

	float TimeLeftABP;

	bool bLedgeMantling;

	bool bStartedLedgeMantle;

	float LedgeMantleStartTime;

	// bool bIsRightFootForward;

	// Custom Functions

	UFUNCTION()
	void ChooseJumpType()
	{
		if (PrevLocomotionAnimationTag != n"Landing")
		{
			if (Player.IsRightFootForward() == true)
			{
				JumpType = EJumpingAnimationType::JumpRight;
			}
			else
			{
				JumpType = EJumpingAnimationType::JumpLeft;
			}
		}
		else
		{
			if (JumpType == EJumpingAnimationType::JumpLeft)
			{
				JumpType = EJumpingAnimationType::JumpRight;
			}
			else
			{
				JumpType = EJumpingAnimationType::JumpLeft;
			}
		}
		// const float TimeToReset = 0.2;
		// float MyPrevMoveSpeed = MovementComponent.PreviousVelocity.Size2D(MovementComponent.WorldUp);
		// if(MyPrevMoveSpeed <= 150)
		// {
		// 	JumpType = EJumpingAnimationType::JumpStill;
		// }
		// else
		// {
		// 	JumpType = EJumpingAnimationType::JumpStill;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MovementComponent = UPlayerMovementComponent::Get(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
		AirJumpComp = UPlayerAirJumpComponent::Get(Player);
		LandingComp = UPlayerLandingComponent::Get(Player);
		AirMoveComp = UPlayerAirMotionComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
		LedgeMantleComp = UPlayerLedgeMantleComponent::Get(Player);
		RollDashComp = UPlayerRollDashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureJump NewFeature = GetFeatureAsClass(ULocomotionFeatureJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bCameFromSprint = SprintComp.IsSprintToggled();

		if (bCameFromSprint)
			PrevMoveSpeed = MovementComponent.PreviousHorizontalVelocity.Size2D() + 200.0;
		else
			PrevMoveSpeed = MovementComponent.PreviousHorizontalVelocity.Size2D();
		LandingAnimData = LandingComp.AnimData;

		JumpTime = 0;

		LedgeMantleStartTime = 0;

		ClearAnimBoolParam(n"PerformedAirJump");

		// bIsRightFootForward = Player.IsRightFootForward();

		ChooseJumpType();

		// if (GetPrevLocomotionAnimationTag() != n"Landing")
		// {
		// 	JumpType = EJumpingAnimationType::NewJump;
		// }

		bPerformingRollDashJump = RollDashComp.bTriggeredRollDashJump;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.06;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Used for debugging purposes for testing anticipation.
		/*if(JumpComp.Settings.JumpDelay > 0)
			StartPosition = 0.0;
		else
			StartPosition = 0.0;*/

		// Used for debugging purposes for testing airjump/normal jump

		bPerformingAirJump = AirJumpComp.bPerformedDoubleJump;

		if (bPerformingRollDashJump)
		{
			SetAnimBoolParam(n"PerformingRollDashJump", true);
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
		}

		if (bPerformingAirJump)
		{
			SetAnimBoolParam(n"PerformingAirJump", true);
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
		}

		CurrentMoveSpeed = Player.GetActorLocalVelocity().Size2D();
		// CurrentMoveSpeed = Math::Clamp(CurrentMoveSpeed, 0.0, 1.0);

		InterpolatedMoveSpeed = Math::FInterpTo(PrevMoveSpeed, CurrentMoveSpeed, DeltaTime, 2);

		// Since the player aren't on the floor, it doesn't need to be relative
		Banking = MovementComponent.GetMovementYawVelocity(bRelativeToFloor = false) / 515;

		// The transition to LedgeMantle from a DoubleJump is blocked until a certain animation time to prevent ugly blend. This float saves the time the AnimInstance is blocked from transitioning
		// and starts the LedgeMantle animation that amount of time into the relevant animation
		if (TopLevelGraphRelevantStateName == n"DoubleJump" && LocomotionAnimationTag == n"LedgeMantle")
		{
			LedgeMantleStartTime += DeltaTime;
			SetAnimFloatParam(n"LedgeMantleStartTime", LedgeMantleStartTime);
		}
	}

	// Threaded animation update, do not copy any values from components in here!
	UFUNCTION(BlueprintOverride, meta = (BlueprintThreadSafe))
	void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	{
		JumpTime += DeltaTime;

		if (GetAnimBoolParamEval(n"DisableJumpIK", true))
			bEnableIK = false;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		// if (TopLevelGraphRelevantStateName == n"RollDashJump")
		// {
		// 	if (LocomotionAnimationTag == n"WallScramble" || LocomotionAnimationTag == n"LedgeGrab" || LocomotionAnimationTag == n"WallRun")
		// 		return TopLevelGraphRelevantAnimTimeRemaining <= 0.5;
		// 	else if (LocomotionAnimationTag == n"LedgeMantle")
		// 		return true;
		// }

		if (TopLevelGraphRelevantStateName == n"DoubleJump")
		{
			if (LocomotionAnimationTag == n"LedgeGrab" || LocomotionAnimationTag == n"WallRun")
				return TopLevelGraphRelevantAnimTime >= 0.24;
			else if(LocomotionAnimationTag == n"WallScramble")
				return true;
		}

		// Blocks transition to LedgeMantle if in DoubleJump differently depending on which type of LedgeMantle
		if (TopLevelGraphRelevantStateName == n"DoubleJump")
		{
			if (LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::ScrambleEnter || LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::ScrambleExit)
			{
				if (LocomotionAnimationTag == n"LedgeMantle")
					return true;
			}
			else if (LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::JumpClimbEnter || LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::JumpClimbExit)
			{
				if (LocomotionAnimationTag == n"LedgeMantle")
				{
					//if we are only partially through our double jump then allow them to blend, Otherwise we keep going through the majority of it
					if(Player.IsMio())
					{
						if(TopLevelGraphRelevantAnimTime <= 0.125)
							return true;
						else
							return TopLevelGraphRelevantAnimTime >= 0.3;
					}
					else
						return true;
						// return TopLevelGraphRelevantAnimTime >= 0.25;
				};
			}
			else if (LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::AirborneRollEnter || LedgeMantleComp.AnimData.State == EPlayerLedgeMantleState::AirborneRollExit)
			{
				if (LocomotionAnimationTag == n"LedgeMantle")
					return TopLevelGraphRelevantAnimTime >= 0.3;
			}
			else if (LedgeMantleComp.AnimData.State != EPlayerLedgeMantleState::AirborneRollEnter)
			{
				if (LocomotionAnimationTag == n"LedgeMantle")
					return TopLevelGraphRelevantAnimTime >= 0.27;
			}
		}

		if (LocomotionAnimationTag != n"AirMovement")
			return true;

		// Use LandingAnimData.FatalTransitionThreshold when it's fixed and updates on JUMP
		if (LandingAnimData.FatalFraction >= LandingAnimData.FatalTransitionThreshold)
			return true;

		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);

		SetAnimBoolParam(n"PerformingAirJump", false);
		SetAnimBoolParam(n"PerformingRollDashJump", false);

		if (LocomotionAnimationTag == n"AirMovement")
			SetAnimFloatParam(n"InitialAirMovementTime", JumpTime);

		TimeLeftABP = Time::GameTimeSeconds;

		if (TopLevelGraphRelevantStateName == n"DoubleJump")
			SetAnimFloatParam(n"LedgeMantleBlendTime", 0.2f);
			SetAnimBoolParam(n"PerformedAirJump", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnUpdateCurrentAnimationStatus(TArray<FName>& OutCurrentAnimationStatus)
	{
		if (AirJumpComp.bPerformedDoubleJump)
			OutCurrentAnimationStatus.Add(n"DoubleJump");
			
	}

	// UFUNCTION()
	// void AnimNotify_LeftFootJump()
	// {
	// 	JumpType = EJumpingAnimationType::JumpRight;
	// }

	// UFUNCTION()
	// void AnimNotify_RighFootJump()
	// {
	// 	JumpType = EJumpingAnimationType::JumpLeft;
	// }
}

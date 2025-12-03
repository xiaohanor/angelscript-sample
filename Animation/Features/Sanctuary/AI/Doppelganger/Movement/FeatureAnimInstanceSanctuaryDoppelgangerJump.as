
UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryDoppelgangerJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureJumpAnimData AnimData;

	UBasicAICharacterMovementComponent MovementComponent;
	UPlayerLandingComponent LandingComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirMotionComponent AirMoveComp;
	UPlayerSprintComponent SprintComp;
	FPlayerLandingAnimationData LandingAnimData;
	//UPlayerAirJumpComponent AirJumpComp;

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
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromJog;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromSprint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformingAirJump;

	UPROPERTY()
	float StartPosition;

	UPROPERTY()
	float JumpPlayRate;

	float TimeLeftABP;

	//Custom Functions

	UFUNCTION()
	void ChooseJumpType()
	{
		const float TimeToReset = 0.2;
		float MyPrevMoveSpeed = MovementComponent.PreviousVelocity.Size2D(MovementComponent.WorldUp);
		if(MyPrevMoveSpeed <= 150)
		{
			JumpType = EJumpingAnimationType::JumpStill;
		}
		else
		{
			JumpType = EJumpingAnimationType::JumpStill;
		}
				
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

		// Implement Custom Stuff Here

		MovementComponent = UBasicAICharacterMovementComponent::Get(HazeOwningActor);
		LandingComp = UPlayerLandingComponent::Get(HazeOwningActor);
		AirMoveComp = UPlayerAirMotionComponent::Get(HazeOwningActor);
		SprintComp = UPlayerSprintComponent::Get(HazeOwningActor);
		// TODO: PLayer dependency, fix substitute
		// AirJumpComp = UPlayerAirJumpComponent::Get(HazeOwningActor);
		JumpComp = UPlayerJumpComponent::Get(HazeOwningActor);
		
		PrevMoveSpeed = HazeOwningActor.ActorVelocity.Size2D() / SprintComp.Settings.MaximumSpeed;
		PrevMoveSpeed = Math::Clamp(PrevMoveSpeed, 0.0, 1.0);

		LandingAnimData = LandingComp.AnimData;

		if (PrevMoveSpeed < 1.0)
			bCameFromSprint = false;
		else 
			bCameFromSprint = true;

		JumpTime = 0;

		ChooseJumpType();

		bEnableIK = (HazeOwningActor.ActorVelocity.Size2D() <= 120);
		// if (bEnableIK)
		// 	IdleFeetPlacementData = FootTraceComp.GetIdleFeetPlacementData();
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05; 
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		JumpTime += DeltaTime;

		//Used for debugging purposes for testing anticipation.
		/*if(JumpComp.Settings.JumpDelay > 0)
			StartPosition = 0.0;
		else*/
			StartPosition = 0.1;

		//Used for debugging purposes for testing airjump/normal jump

		// if(AirJumpComp.bIsAirJumpEnabled)
		// 	JumpPlayRate = 1.3;
		// else
			JumpPlayRate = 1.0;

		bPerformingAirJump = false;// AirJumpComp.bPerformedDoubleJump;

		CurrentMoveSpeed = HazeOwningActor.ActorVelocity.Size2D();
		//CurrentMoveSpeed = Math::Clamp(CurrentMoveSpeed, 0.0, 1.0);

		// Since the player aren't on the floor, it doesn't need to be relative
		//Banking = MovementComponent.GetMovementYawVelocity(bRelativeToFloor = false) / 515;

		if (GetAnimBoolParam(n"DisableJumpIK", true) || MovementComponent.VerticalSpeed > 100)
			bEnableIK = false;
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		if (LocomotionAnimationTag != n"AirMovement")
			return true;

		// Use LandingAnimData.FatalTransitionThreshold when it's fixed and updates on JUMP
		if (LandingAnimData.FatalFraction >= LandingAnimData.FatalTransitionThreshold)
			return true;

		return TopLevelGraphRelevantAnimTimeRemaining <= 0.01;

	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag == n"AirMovement")
			SetAnimFloatParam(n"InitialAirMovementTime", JumpTime);
		
		TimeLeftABP = Time::GameTimeSeconds;
	}

}

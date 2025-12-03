class UFeatureAnimInstanceToothMovement : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureToothMovement Feature;

    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FLocomotionFeatureToothMovementAnimData AnimData;
	
	UDentistToothPlayerComponent ToothComp;
	UPlayerMovementComponent MoveComp;
	UDentistToothJumpComponent JumpComp;
	UDentistToothDashComponent DashComp;
	UDentistToothGroundPoundComponent GroundPoundComp;
	UDentistToothCannonComponent CannonComp;
	UDentistToothDoubleCannonComponent DoubleCannonComp;
	UDentistToothRagdollComponent FlailComp;
	UDentistToothSplitComponent SplitComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLandHigh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashEnd;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashIntoFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGroundpounding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGroundPoundStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGroundPoundMH;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGroundPoundEnd;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromGroudPound;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInCannon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchedByCannon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSplit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHooked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStruckByHammer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDrilled;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(Feature == nullptr)
			return;

		if(Player == nullptr)
			return;

		AnimData = Feature.AnimData;

		ToothComp = UDentistToothPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UDentistToothJumpComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);
		CannonComp = UDentistToothCannonComponent::Get(Player);
		DoubleCannonComp = UDentistToothDoubleCannonComponent::Get(Player);
		FlailComp = UDentistToothRagdollComponent::Get(Player);
		SplitComp = UDentistToothSplitComponent::Get(Player);
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if(Player == nullptr)
			return;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;

		Speed = Math::Max(
			MoveComp.Velocity.Size(),
			MoveComp.SyncedMovementInputForAnimationOnly.Size() * 300
		);

		bJump = JumpComp.IsJumping();
		bIsFalling = MoveComp.IsFalling();
		bIsGrounded = MoveComp.IsOnWalkableGround();
		bDash = DashComp.IsDashing();
		bDashEnd = DashComp.IsLanding();
		bLandHigh = JumpComp.GetJumpType() == EDentistToothJump::FrontFlip;

		bIsGroundpounding = GroundPoundComp.CurrentState != EDentistToothGroundPoundState::None;
		bGroundPoundStart = GroundPoundComp.CurrentState == EDentistToothGroundPoundState::Anticipation;
		bGroundPoundMH = GroundPoundComp.CurrentState == EDentistToothGroundPoundState::Drop;
		bGroundPoundEnd = GroundPoundComp.CurrentState == EDentistToothGroundPoundState::Recover;

		bIsInCannon = CannonComp.IsInCannon() || DoubleCannonComp.IsInCannon();
		bIsLaunchedByCannon = CannonComp.IsLaunched() || DoubleCannonComp.IsLaunched();

		bFlail = FlailComp.bIsRagdolling;

		bIsSplit = SplitComp.bIsSplit;

		bHooked = ToothComp.bHooked;
		bStruckByHammer = ToothComp.StruckByHammerFrame == Time::FrameNumber;
		bDrilled = ToothComp.bDrilled;

		if (Player.IsAnyCapabilityActive(n"DentistSideStoryExiting"))
			bFlail = true;

		if(Dentist::PrintAnimationValues.IsEnabled(Player))
		{
			PrintToScreen(f"{bWantsToMove=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{Speed=}", Color = Player.GetPlayerDebugColor());

			PrintToScreen(f"{bJump=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bIsFalling=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bIsGrounded=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bDash=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bDashEnd=}", Color = Player.GetPlayerDebugColor());

			PrintToScreen(f"{bIsGroundpounding=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bGroundPoundStart=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bGroundPoundMH=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bGroundPoundEnd=}", Color = Player.GetPlayerDebugColor());

			PrintToScreen(f"{bIsInCannon=}", Color = Player.GetPlayerDebugColor());
			PrintToScreen(f"{bIsLaunchedByCannon=}", Color = Player.GetPlayerDebugColor());
			
			
			PrintToScreen(f"{bFlail=}", Color = Player.GetPlayerDebugColor());
		}
    }


	


    UFUNCTION()
    void AnimNotify_EnteredGroundPound()
    {
        bCameFromGroudPound = true;
    }

	UFUNCTION()
    void AnimNotify_ResetEnteredGroundPound()
    {
        bCameFromGroudPound = false;
    }

	UFUNCTION()
    void AnimNotify_EnteredDashEnd()
    {
        bDashIntoFalling = true;
    }

	UFUNCTION()
    void AnimNotify_ResetEnteredDashEnd()
    {
        bDashIntoFalling = false;
    }

};
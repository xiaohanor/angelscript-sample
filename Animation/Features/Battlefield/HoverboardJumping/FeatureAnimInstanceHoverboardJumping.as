enum EHoverboardJumpingAnimStates
{
	Forward,
	Backwards
}

UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardJumping : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardJumping Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardJumpingAnimData AnimData;

	UPlayerMovementComponent MoveComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHoverboardJumpingAnimStates WantedJumpingState;

	FRotator DeltaAlignRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpingBackwardsStartPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool LandingTurnRight;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FBattlefieldHoverboardAnimationParams HoverboardParams;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpToGrindRootHeight;

	FVector LocalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RotateRoot;

	FRotator InitialSlopeRotation;
	bool bFirstTick;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComponent = UPlayerMovementComponent::Get(Player);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardJumping NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardJumping);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		RootOffset = HoverboardComp.GetAnimRootOffset();
		HoverboardParams = HoverboardComp.AnimParams;
		JumpToGrindRootHeight = 0;
		RotateRoot.Yaw = 0;

		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, InitialSlopeRotation);
		BlendspaceValues = FVector2D(InitialSlopeRotation.Roll, -InitialSlopeRotation.Pitch);

		Banking = GetAnimFloatParam(n"HoverboardBanking", true);
		LandingTurnRight = GetAnimBoolParam(n"HoverboardLandingTurnRight", true);

		AdditiveBankingAlpha = 0;
		JumpingBackwardsStartPosition = 0;

		const FRotator RootRotation = Player.Mesh.GetSocketRotation(n"Root");
		const FRotator AlignRotation = Player.Mesh.GetSocketRotation(n"LeftHand_IK");
		DeltaAlignRotation = (RootRotation - AlignRotation).GetNormalized();

		if (DeltaAlignRotation.Yaw > 70 || DeltaAlignRotation.Yaw < -70)
		{
			WantedJumpingState = EHoverboardJumpingAnimStates::Backwards;

			if (LandingTurnRight)
			{
				if (DeltaAlignRotation.Yaw > 70 && DeltaAlignRotation.Yaw < 180)
					JumpingBackwardsStartPosition = 0.13;
			}
			else
			{
				if (DeltaAlignRotation.Yaw > -180 && DeltaAlignRotation.Yaw < -70)
					JumpingBackwardsStartPosition = 0.13;
			}
		}
		else
		{
			WantedJumpingState = EHoverboardJumpingAnimStates::Forward;
		}

		bFirstTick = true;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.16;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		LocalVelocity = Player.GetActorLocalVelocity();

		BankingValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;
		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 1.5);

		if (AdditiveBankingAlpha < 1)
		{
			if (WantedJumpingState == EHoverboardJumpingAnimStates::Backwards)
				AdditiveBankingAlpha += DeltaTime / 1.5;
			else
				AdditiveBankingAlpha += DeltaTime / 0.7;
		}

		if (HoverboardParams.bIsJumpingToGrind)
		{
			JumpToGrindRootHeight = Math::FInterpConstantTo(JumpToGrindRootHeight, 1.0, DeltaTime, 2.2);

			const float ClampedVelocityY = Math::Clamp(LocalVelocity.Y, -2000, 2000);
			float RotateRootTarget = ClampedVelocityY / 2000 * 100;
			RotateRoot.Yaw = Math::FInterpTo(RotateRoot.Yaw, RotateRootTarget, DeltaTime, 3.5);
		}

		// Blend out the slope rotation, LowestLevelGraphRelevantAnimTimeRemainingFraction will be 0 the first tick
		if (bFirstTick)
		{
			bFirstTick = false;
			SlopeRotation = InitialSlopeRotation;
		}
		else
		{
			SlopeRotation = InitialSlopeRotation * LowestLevelGraphRelevantAnimTimeRemainingFraction;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
			return true;

		if (LocomotionAnimationTag != n"HoverboardAirMovement")
			return true;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardLanding")
			SetAnimFloatParam(n"HoverboardBanking", Banking);

		if (LocomotionAnimationTag == n"HoverboardAirMovement")
			SetAnimFloatParam(n"HoverboardRootRotation", RotateRoot.Yaw);
	}
}

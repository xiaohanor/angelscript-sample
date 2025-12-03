UCLASS(Abstract)
class UFeatureAnimInstanceHoverboard : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboard Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AdditiveFwdBackValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTrick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitWall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EBattlefieldHoverboardTrickType TrickType;

	bool bIsPlayingTrick;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComponent = UPlayerMovementComponent::Get(Player);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboard NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboard);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation);

		Banking = GetAnimFloatParam(n"HoverboardBanking", true);

		if (PrevLocomotionAnimationTag != n"HoverboardLanding")
		{
			ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
			ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardReflectedOffWall);
		}

		AdditiveBankingAlpha = 1;
		bIsPlayingTrick = false;

		const auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);

		RootOffset = HoverboardComp.GetAnimRootOffset();
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bTrick)
			return 0.1;

		if (bHitWall)
			return 0.1;

		if (GetPrevLocomotionAnimationTag() == n"HoverboardLanding")
			return 0.4;

		if (GetPrevLocomotionAnimationTag() == n"HoverboardGrinding")
			return 0.7;

		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MoveComponent.GetVelocity().Size();

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.6);

		AdditiveBankingValues = FVector2D(MoveComponent.SyncedMovementInputForAnimationOnly.Y, SlopeRotation.Roll);
		AdditiveFwdBackValues = FVector2D(MoveComponent.SyncedMovementInputForAnimationOnly.Y, MoveComponent.SyncedMovementInputForAnimationOnly.X);
		Banking = Math::FInterpTo(Banking, AdditiveBankingValues.X, DeltaTime, 8);

		BlendspaceValues = FVector2D(SlopeRotation.Roll, -SlopeRotation.Pitch);

		// Tricks
		bTrick = false;
		const bool bWantsToTrick = GetAnimTrigger(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
		if (bWantsToTrick)
		{
			const int TrickTypeInt = GetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickType);
			TrickType = EBattlefieldHoverboardTrickType(TrickTypeInt);
			
			if (!bIsPlayingTrick || LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.2)
				bTrick = bWantsToTrick;
			else if (bIsPlayingTrick && LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.4)
				SetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered, true); // Buffer

			bIsPlayingTrick = true;
		}

		const float Target = (!bIsPlayingTrick || LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.5) ? 1 : 0;
		AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, Target, DeltaTime, 5);

		bHitWall = GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardReflectedOffWall, true);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"HoverboardLanding")
			return false;

		if (bIsPlayingTrick && (LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardSkydiving"))
		{
			return LowestLevelGraphRelevantAnimTimeRemaining <= 0.4;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardJumping" || LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardTricks")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}

	UFUNCTION()
	void AnimNotify_LeftTrickState()
	{
		bIsPlayingTrick = false;
	}
}

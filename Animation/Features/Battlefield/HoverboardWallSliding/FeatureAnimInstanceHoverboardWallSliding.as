UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardWallSliding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardWallSliding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardWallSlidingAnimData AnimData;

	UPlayerMovementComponent MoveComponent;
	UBattlefieldHoverboardWallRunComponent WallSlideComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerWallRunAnimationData WallSlideAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRequestingAirMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		WallSlideComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardWallSliding NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardWallSliding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		AdditiveBankingAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.15;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		WallSlideAnimData = WallSlideComp.AnimData;

		BankingValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;

		if (LowestLevelGraphRelevantStateName == n"ExitLeft" || LowestLevelGraphRelevantStateName == n"ExitRight")
			AdditiveBankingAlpha += DeltaTime / 3.0;

		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 0.8);

		bRequestingAirMovement = LocomotionAnimationTag == n"HoverboardAirMovement";

		bJump = WallSlideAnimData.State == EPlayerWallRunState::Jump || LocomotionAnimationTag == n"HoverboardJumping";
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
		{
			const int TrickTypeInt = GetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickType);
			const auto TrickType = EBattlefieldHoverboardTrickType(TrickTypeInt);
			if (TrickType != EBattlefieldHoverboardTrickType::WallRun)
				return true;
		}

		if (LocomotionAnimationTag == n"HoverboardSwinging")
			return true;

		if (LocomotionAnimationTag != n"HoverboardAirMovement" && LocomotionAnimationTag != n"HoverboardJumping")
			return false;

		if (MoveComponent.HasGroundContact())
			return true;

		if (LowestLevelGraphRelevantStateName != n"ExitLeft" && LowestLevelGraphRelevantStateName != n"ExitRight")
			return false;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardLanding")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}
}

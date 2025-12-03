enum EHoverboardLandingAnimStates
{
	Light,
	Medium,
	Heavy,
	Backwards,
	Fail
}

UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardLandingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingFwdBackValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHoverboardLandingAnimStates WantedLandingState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LandingBackwardsStartPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLandingTurnRight;

	FRotator DeltaAlignRotation;

	UBattlefieldHoverboardComponent HoverboardComp;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerMovementComponent MoveComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		MoveComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bLandingTurnRight = GetAnimBoolParam(n"HoverboardLandingTurnRight", true);
		const bool bCheckBackwardsLanding = !GetAnimBoolParam(n"IgnoreLandingBackwards", true);
		Banking = GetAnimFloatParam(n"HoverboardBanking", true);

		RootOffset = HoverboardComp.GetAnimRootOffset();
		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation);

		ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
		ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardReflectedOffWall);

		// Figure out which landing anim to play
		FBattlefieldHoverboardAnimationParams HoverboardParams = HoverboardComp.AnimParams;

		FRotator RootRotation = Player.Mesh.GetSocketRotation(n"Root");
		FRotator BoardRotation = Player.Mesh.GetSocketRotation(n"LeftHand_IK");
		DeltaAlignRotation = (RootRotation - BoardRotation).GetNormalized();

		AdditiveBankingAlpha = 1;
		LandingBackwardsStartPosition = 0;
		if (bCheckBackwardsLanding && (DeltaAlignRotation.Yaw > 70 || DeltaAlignRotation.Yaw < -85) && bLandingTurnRight == false)
		{
			WantedLandingState = EHoverboardLandingAnimStates::Backwards;
			AdditiveBankingAlpha = 0;

			if (DeltaAlignRotation.Yaw > -180 && DeltaAlignRotation.Yaw < -85)
				LandingBackwardsStartPosition = 0.1;
		}
		else if (bCheckBackwardsLanding && (DeltaAlignRotation.Yaw > 85 || DeltaAlignRotation.Yaw < -70) && bLandingTurnRight == true)
		{
			WantedLandingState = EHoverboardLandingAnimStates::Backwards;
			AdditiveBankingAlpha = 0;

			if (DeltaAlignRotation.Yaw > 85 && DeltaAlignRotation.Yaw < 180)
				LandingBackwardsStartPosition = 0.1;
		}
		else if (HoverboardParams.LastLandingSpeed > -1500)
		{
			WantedLandingState = EHoverboardLandingAnimStates::Light;
		}
		else if (HoverboardParams.LastLandingSpeed < -4000)
		{
			WantedLandingState = EHoverboardLandingAnimStates::Heavy;
			AdditiveBankingAlpha = 0;
		}
		else
		{
			WantedLandingState = EHoverboardLandingAnimStates::Medium;
			AdditiveBankingAlpha = 0.3;
		}

		if (GetAnimTrigger(n"HoverboardFail"))
			WantedLandingState = EHoverboardLandingAnimStates::Fail;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.6);

		BankingValues = FVector2D(MoveComponent.SyncedMovementInputForAnimationOnly.Y, SlopeRotation.Roll);
		BankingFwdBackValues = FVector2D(MoveComponent.SyncedMovementInputForAnimationOnly.Y, MoveComponent.SyncedMovementInputForAnimationOnly.X);

		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 3);

		if (AdditiveBankingAlpha < 1)
			AdditiveBankingAlpha += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"HoverboardAirMovement")
			return LowestLevelGraphRelevantAnimTime > 0.25 || IsLowestLevelGraphRelevantAnimFinished();

		if (LocomotionAnimationTag != n"Hoverboard")
			return true;

		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardReflectedOffWall))
			return true;

		// Handle tricks
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
		{
			if (WantedLandingState == EHoverboardLandingAnimStates::Light)
				return true;
			else if (WantedLandingState == EHoverboardLandingAnimStates::Medium && LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.85)
				return true;
			else if ((WantedLandingState == EHoverboardLandingAnimStates::Heavy || WantedLandingState == EHoverboardLandingAnimStates::Backwards)
					 && LowestLevelGraphRelevantAnimTimeRemainingFraction < 0.5)
				return true;

			ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);
		}

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"Hoverboard" || LocomotionAnimationTag == n"HoverboardJumping" || LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardTricks")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}
}

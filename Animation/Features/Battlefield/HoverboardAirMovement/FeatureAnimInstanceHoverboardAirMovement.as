UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardAirMovementAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPlayerMovementComponent MoveComponent;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RotateRoot;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RootOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTrick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLowGroundTrick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UAnimSequence TrickAnim;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFreeFall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator FreeFallRotaion;

	const FRotator FREE_FALL_ROTATION_TARGET = FRotator(-60, 0, 0);

	float AirTime;

	const float LOW_GROUND_TRICK_TREASHOLD = 2000;

	FVector RootOffsetTaget = FVector::ZeroVector;

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
		ULocomotionFeatureHoverboardAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		AdditiveBankingAlpha = 0.25;

		Banking = GetAnimFloatParam(n"HoverboardBanking", true);
		RotateRoot.Yaw = GetAnimFloatParam(n"HoverboardRootRotation", true);

		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		RootOffset = HoverboardComp.GetAnimRootOffset();

		if (GetAnimBoolParam(n"BlendOffset", true))
		{
			RootOffsetTaget = RootOffset;
			RootOffset = FVector::ZeroVector;
		}
		else
			RootOffsetTaget = FVector::ZeroVector;

		if (GetAnimBoolParam(n"FreeFallBlend", true))
			FreeFallRotaion = FRotator::ZeroRotator;
		else
			FreeFallRotaion = FREE_FALL_ROTATION_TARGET;

		if (GetAnimBoolParam(n"BlendIK", true))
			IKGoalAlpha = 0;
		else
			IKGoalAlpha = 1;
			

		AirTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bTrick)
		{
			if (PrevLocomotionAnimationTag == n"HoverboardGrappling")
				return 0.3;

			return 0.1;
		}

		if (PrevLocomotionAnimationTag == n"HoverboardWallSliding" || PrevLocomotionAnimationTag == n"HoverboardGrinding")
			return 0.5;

		if (PrevLocomotionAnimationTag == n"Hoverboard" || PrevLocomotionAnimationTag == n"HoverboardLanding")
			return 0.55;

		if (PrevLocomotionAnimationTag == n"HoverboardJumping" || PrevLocomotionAnimationTag == n"HoverboardSwinging" || PrevLocomotionAnimationTag == n"HoverboardSkydiving")
			return 0.5;

		if (PrevLocomotionAnimationTag == n"HoverboardGrappling")
			return 0.6;

		if (PrevLocomotionAnimationTag == n"HoverboardTricks")
			return 0.4;

		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MoveComponent == nullptr)
			return;

		if (!RootOffsetTaget.IsZero())
		{
			RootOffset = Math::VInterpTo(RootOffset, RootOffsetTaget, DeltaTime, 2);
			if (RootOffset.Equals(RootOffsetTaget, 0.1))
			{
				RootOffset = RootOffsetTaget;
				RootOffsetTaget = FVector::ZeroVector;
			}
		}

		BlendspaceValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;
		BlendspaceValues.Y = MoveComponent.VerticalSpeed;

		BankingValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;

		bFreeFall = GetAnimBoolParam(n"FreeFall", true);

		if (MoveComponent.HasGroundContact())
		{
			FVector OutSlopeOffset;
			FRotator OutSlopeRotation;
			SlopeAlignComp.GetSlopeTransformData(OutSlopeOffset, OutSlopeRotation);
		}

		if (AdditiveBankingAlpha > 0)
			AdditiveBankingAlpha -= DeltaTime / 0.5;

		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 1.5);

		bTrick = GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered, true);
		if (bTrick)
		{
			const int TrickTypeInt = GetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickType);
			const auto TrickType = EBattlefieldHoverboardTrickType(TrickTypeInt);

			const int TrickIndex = GetAnimIntParam(BattlefieldHoverboardAnimParams::HoverboardTrickIndex);

			if (TrickType == EBattlefieldHoverboardTrickType::X)
				TrickAnim = Feature.TrickListX.AnimData[TrickIndex].Animation;
			else if (TrickType == EBattlefieldHoverboardTrickType::Y)
				TrickAnim = Feature.TrickListY.AnimData[TrickIndex].Animation;
			else if (TrickType == EBattlefieldHoverboardTrickType::B)
				TrickAnim = Feature.TrickListB.AnimData[TrickIndex].Animation;
			else // Tricks are requested after e.g. wallrun/grind
				bTrick = false;

			if (TrickAnim == nullptr)
				bTrick = false;
		}

		if (bFreeFall && !FreeFallRotaion.Equals(FREE_FALL_ROTATION_TARGET))
			FreeFallRotaion = Math::RInterpTo(FreeFallRotaion, FREE_FALL_ROTATION_TARGET, DeltaTime, 0.7);


		if (IKGoalAlpha < 1)
		{
			IKGoalAlpha = Math::FInterpTo(IKGoalAlpha, 1, DeltaTime, 2);
			if (Math::IsNearlyEqual(IKGoalAlpha, 1))
				IKGoalAlpha = 1;
		}

		AirTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LowestLevelGraphRelevantStateName == n"Trick" && (LocomotionAnimationTag == n"HoverboardSkydiving" || LocomotionAnimationTag == n"HoverboardTricks"))
			return LowestLevelGraphRelevantAnimTimeRemainingFraction <= 0.4;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardLanding")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}

	bool CheckGroundWithinDistance(float TraceLenght) const
	{
		const FVector TraceDirection = -Player.ActorUpVector + (Player.ActorForwardVector / 2);
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.IgnoreActor(Player);

		const auto Results = TraceSettings.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation + TraceDirection * TraceLenght);
		Debug::DrawDebugLine(Results.TraceStart, Results.TraceEnd);

		return Results.bBlockingHit;
	}
}

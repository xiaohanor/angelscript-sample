UCLASS(Abstract)
class UFeatureAnimInstanceHoverboardGrinding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverboardGrinding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverboardGrindingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float IKGoalAlpha = 1;

	UPlayerMovementComponent MoveComponent;
	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FBattlefieldHoverboardAnimationParams HoverboardParams;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRequestingAirMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector EnterDirectionDelta;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	FQuat CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GrindVerticalRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpWhileGrind;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpOffGrind;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComponent = UPlayerMovementComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverboardGrinding NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverboardGrinding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		RootRotation = FRotator::ZeroRotator;
		CachedActorRotation = FQuat::Identity;

		FTransform HoverboardTransform = Player.Mesh.GetSocketTransform(n"Hips");
		EnterDirectionDelta = HoverboardTransform.InverseTransformVectorNoScale(GrindComp.CurrentSplinePos.WorldForwardVector);

		Banking = GetAnimFloatParam(n"HoverboardBanking", true);

		AdditiveBankingAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.19;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		ClearAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered);

		HoverboardParams = HoverboardComp.AnimParams;

		BankingValues.X = MoveComponent.SyncedMovementInputForAnimationOnly.Y;

		if ((LowestLevelGraphRelevantStateName == "Grinding Back Exit" || LowestLevelGraphRelevantStateName == "Grinding Front Exit") && AdditiveBankingAlpha < 1)
			AdditiveBankingAlpha += DeltaTime / 0.8;

		Banking = Math::FInterpTo(Banking, BankingValues.X, DeltaTime, 0.5);

		bJumpWhileGrind = HoverboardParams.bIsJumpingWhileGrinding || LocomotionAnimationTag == n"HoverboardJumping";
		bJumpOffGrind = HoverboardParams.bIsJumpingOffGrind || LocomotionAnimationTag == n"HoverboardJumping";

		bRequestingAirMovement = LocomotionAnimationTag == n"HoverboardAirMovement";

		GrindVerticalRotation = FRotator::MakeFromXY(GrindComp.CurrentSplinePos.WorldForwardVector, Player.ActorRightVector).Pitch;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (GetAnimBoolParam(BattlefieldHoverboardAnimParams::HoverboardTrickTriggered))
			return true;

		if (LocomotionAnimationTag != n"HoverboardAirMovement" && LocomotionAnimationTag != n"HoverboardJumping")
			return true;

		if (TopLevelGraphRelevantStateName == "Grinding Back Jump" || TopLevelGraphRelevantStateName == "Grinding Front Jump")
			return false;

		if (LowestLevelGraphRelevantStateName == n"Grinding Front Enter" || LowestLevelGraphRelevantStateName == n"Grinding Front Mh" || LowestLevelGraphRelevantStateName == n"Grinding Back Enter" || LowestLevelGraphRelevantStateName == n"Grinding Back Mh")
			return false;

		if (MoveComponent.HasGroundContact())
			return true;

		return LowestLevelGraphRelevantAnimTimeRemaining < 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"HoverboardAirMovement" || LocomotionAnimationTag == n"HoverboardLanding" || LocomotionAnimationTag == n"Hoverboard")
			SetAnimFloatParam(n"HoverboardBanking", Banking);
	}
}


UCLASS(Abstract)
class UFeatureAnimInstanceAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(BlueprintHidden, NotEditable)
	ULocomotionFeatureAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAirMovementAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MoveComp;

	UPlayerJumpComponent JumpComp;

	UPlayerLandingComponent LandingComp;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FPlayerLandingAnimationData LandingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRightFootForward;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FallTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FallDistance;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FallSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocityAlpha;

	bool bFalling;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float MoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromMovement;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCameFromJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromAirJump;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCameFromPerch;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCameFromDash;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCameFromSwingAir;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCameFromDragonHover;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromAirDash;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BSValues;

	float PreviousMoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InterpolatedMoveSpeed;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
		LandingComp = UPlayerLandingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Reseting fall time counter

		FallTime = 0;

		// Checking previous Tag and setting appropriate bool
		bCameFromMovement = PrevLocomotionAnimationTag == n"Movement";

		bCameFromJump = PrevLocomotionAnimationTag == n"Jump";

		bCameFromAirJump = GetAnimBoolParam(n"PerformedAirJump", true, false);

		bCameFromPerch = PrevLocomotionAnimationTag == n"Perch";

		bCameFromDash = PrevLocomotionAnimationTag == n"Dash";

		bCameFromSwingAir = PrevLocomotionAnimationTag == n"SwingAir";

		bCameFromAirDash = PrevLocomotionAnimationTag == n"AirDash";

		bCameFromDragonHover = PrevLocomotionAnimationTag == n"BackpackDragonHover";

		PreviousMoveSpeed = MoveComp.PreviousHorizontalVelocity.Size();

		bIsRightFootForward = Player.IsRightFootForward();

		VerticalVelocityAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (bCameFromJump && !bCameFromAirJump && PrevLocomotionAnimationTag != n"Launch")
			return 0.1;
		else if (PrevLocomotionAnimationTag == n"Launch")
			return 1;
		else
			return GetAnimFloatParam(n"AirMovementBlendTime", true, 0.3);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		FallTime += DeltaTime;

		FallSpeed = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);

		MoveSpeed = Player.GetActorLocalVelocity().Size2D();

		BSValues.Y = MoveSpeed;
		BSValues.X = Math::Clamp((MoveComp.GetMovementYawVelocity(false) / 81), -1, 1);

		LandingAnimData = LandingComp.AnimData;

		InterpolatedMoveSpeed = Math::FInterpTo(PreviousMoveSpeed, MoveSpeed, DeltaTime, 2);

		if (FallSpeed < 0)
		{
			VerticalVelocityAlpha = Math::FInterpTo(VerticalVelocityAlpha, 0, DeltaTime, 1);
		}
		else
		{
			VerticalVelocityAlpha = Math::FInterpTo(VerticalVelocityAlpha, 1, DeltaTime, 1);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}

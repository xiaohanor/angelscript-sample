UCLASS(Abstract)
class UTempAnimInstanceTundraMonkeyKingSimonSays : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	FLocomotionFeatureSnowMonkeyPerchAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	FHazePlaySequenceData ThumbsUpEnter;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	FHazePlaySequenceData ThumbsUpMh;

	ATundra_SimonSaysMonkeyKing MonkeyKing;
	UTundra_SimonSaysMonkeyKingMovementComponent MovementComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnterLeft;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationRateInterpolated;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOnSpline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDoThumbsUp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		MonkeyKing = Cast<ATundra_SimonSaysMonkeyKing>(HazeOwningActor);
		MovementComponent = UTundra_SimonSaysMonkeyKingMovementComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		// bPerching = PerchComponent.Data.bPerching && !PerchComponent.Data.bSplineJump;

		// bInEnter = PerchComponent.AnimData.bInEnter || PerchComponent.AnimData.bInGroundedEnter;

		// bJumping = PerchComponent.Data.bJumpingOff || PerchComponent.Data.bSplineJump;

		// bPerching = MonkeyKing.AnimData.bPerching;
		// bJumping = MonkeyKing.AnimData.bJumpingOff;
		// bDoThumbsUp = MonkeyKing.AnimData.bDoThumbsUp;

		//bHasInput = !MovementComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		//bOnSpline = PerchComponent.Data.bInPerchSpline;

		Speed = MovementComponent.Velocity.Size();
		Velocity = MovementComponent.Velocity;
		PrintToScreenScaled("Velocity: " + Velocity, 0.f);

		float InterpSpeed = Math::Abs(RotationRate) > MovementComponent.GetMovementYawVelocity(false) / 250.0 ? 3.0 : 2.0;
		RotationRate = (MovementComponent.GetMovementYawVelocity(false) / 250.0);
		RotationRateInterpolated = Math::FInterpTo(RotationRateInterpolated, RotationRate, DeltaTime, InterpSpeed);
	}

    UFUNCTION()
    void AnimNotify_CameFromLeft()
    {
        bEnterLeft = false;
    }

	UFUNCTION()
    void AnimNotify_CameFromRight()
    {
        bEnterLeft = true;
    }
}
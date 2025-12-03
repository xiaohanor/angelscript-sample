UCLASS(Abstract)
class UFeatureAnimInstanceHoverPerch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHoverPerch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHoverPerchAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MovementBlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPerchAnimData PerchAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float InitialDistanceToPoint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLandFromPerch;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float UnstableAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrind;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	float TimeLeft = -1;

	UHoverPerchPlayerComponent HoverPerchComp;
	UPlayerPerchComponent PerchComponent;

	FRotator CachedRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		HoverPerchComp = UHoverPerchPlayerComponent::GetOrCreate(HazeOwningActor);
		PerchComponent = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHoverPerch NewFeature = GetFeatureAsClass(ULocomotionFeatureHoverPerch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (PerchComponent.Data.TargetedPerchPoint != nullptr)
		{
			const FVector PointPosition = PerchComponent.Data.TargetedPerchPoint.WorldLocation;
			InitialDistanceToPoint = (PointPosition - Player.ActorLocation).Size();
		}

		bLandFromPerch = TimeLeft > 0 && Time::GetGameTimeSince(TimeLeft) < 1;

		CachedRotation = HazeOwningActor.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.06;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HoverPerchComp == nullptr)
			return;


		PerchAnimData = PerchComponent.AnimData;

		const FRotator DeltaRotation = (HazeOwningActor.ActorRotation - CachedRotation).GetNormalized();
		CachedRotation = HazeOwningActor.ActorRotation;

		if (HoverPerchComp.PerchActor != nullptr)
		{
			const FVector LocalVelocity = HazeOwningActor.ActorRotation.UnrotateVector(HoverPerchComp.PerchActor.MoveComp.GetVelocity());

			if (DeltaTime > 0)
				MovementBlendspaceValues = FVector2D(
					Math::FInterpTo(MovementBlendspaceValues.X, DeltaRotation.Yaw / DeltaTime / 250, DeltaTime, 4),
					LocalVelocity.X / 750);

			bGrind = HoverPerchComp.PerchActor.CurrentGrind != nullptr;
			bSkipEnter = HoverPerchComp.PerchActor.bSnapAnimationToMH;

			bDash = HoverPerchComp.PerchActor.FrameOfDashActionStarted.IsSet() && HoverPerchComp.PerchActor.FrameOfDashActionStarted.Value == Time::FrameNumber;
			bBump = GetAnimTrigger(n"HoverPerchBump");
			if (bBump || bGrind)
				UnstableAlpha = 1;
			else if (UnstableAlpha != 0)
				UnstableAlpha = Math::FInterpTo(UnstableAlpha, 0, DeltaTime, 0.5);
		}
		else
		{
			bDash = false;
			bSkipEnter = false;
		}

		bJumping = PerchComponent.Data.bJumpingOff || PerchComponent.Data.bSplineJump;
		bPerching = PerchComponent.Data.bPerching && !PerchComponent.Data.bSplineJump;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement")
			return true;

		if (TopLevelGraphRelevantStateName == n"Jump")
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		TimeLeft = Time::GameTimeSeconds;
	}
}

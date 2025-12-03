UCLASS(Abstract)
class UFeatureAnimInstanceBackpackDragonHover : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBackpackDragonHover Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBackpackDragonHoverAnimData AnimData;

	UHazePhysicalAnimationComponent PhysComp;
	UPlayerAirDashComponent AirDashComp;
	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HoverTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHovering;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator Banking;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	FHazeAcceleratedFloat BankingSpring;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		bIsPlayer = Player != nullptr;
		if (bIsPlayer)
		{
			PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
			MoveComp = UPlayerMovementComponent::Get(Player);
		}
		else
			MoveComp = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBackpackDragonHover NewFeature = GetFeatureAsClass(ULocomotionFeatureBackpackDragonHover);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bIsPlayer = HazeOwningActor.AttachParentActor == nullptr;

		BankingSpring.SnapTo(0);

		if (bIsPlayer)
		{
			PhysComp.ApplyProfileAsset(this, PhysProfile);
			MoveComp = UPlayerMovementComponent::Get(Player);
		}

		HoverTimer = 0;
		AirDashComp = UPlayerAirDashComponent::Get(HazeOwningActor);
		if (AirDashComp == nullptr)
			AirDashComp = UPlayerAirDashComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		if (bIsPlayer)
			return 0.4;

		return 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		HoverTimer += DeltaTime;
		bIsDashing = AirDashComp.IsAirDashing();

		bIsHovering = LocomotionAnimationTag == Feature.Tag;

		const float YawVelocity = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 230, -1.0, 1.0);
		if (bIsPlayer)
		{
			BankingSpring.SpringTo(YawVelocity, 50, 0.2, DeltaTime);
			Banking.Roll = 6 * BankingSpring.Value;
		}
		else
		{
			Banking.Roll = Math::FInterpTo(Banking.Roll, 20 * YawVelocity, DeltaTime, 6);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"AirDash")
			return false;

		if (LocomotionAnimationTag != n"AirMovement")
			return true;

		return TopLevelGraphRelevantStateName == n"Exit" && IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (PhysComp != nullptr)
			PhysComp.ClearProfileAsset(this);
	}

	UFUNCTION()
	void AnimNotify_ResetHoverTimer()
	{
		HoverTimer = 0;
	}
}

class UAnimInstanceSketchBook : UHazeCharacterAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bRefreshPose;

	FName CachedLocomotionAnimationTag;

	UPROPERTY(BlueprintReadOnly)
	FHazeRange DefaultRefreshRate;

	UPROPERTY(BlueprintReadOnly)
	TMap<FName, FHazeRange> CustomRefreshRate;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	FRotator RootRotation2D;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bConstrainRoot2D;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	bool bIsMio;

	UPlayerFloorMotionComponent FloorMotionComp;
	USketchbookMeleeAttackPlayerComponent PlayerAttackComp;

	AHazePlayerCharacter Player;

	bool bIsAttackingNunchucks;
	float NUNCHUCK_ATTACK_POSE_INTERVAL = 0.05;
	float NunchuckAttackRefreshTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		FloorMotionComp = UPlayerFloorMotionComponent::Get(HazeOwningActor);
		Player = Cast<AHazePlayerCharacter>(HazeOwningActor);

		bIsMio = Player.IsMio();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		bRefreshPose = false;

		ForceRefreshPoseCheck();
		CalculateRootRotation();

		CachedLocomotionAnimationTag = LocomotionAnimationTag;
	}

	/**
	 * Check if we should force a pose refresh
	 */
	void ForceRefreshPoseCheck()
	{
		if (GetAnimTrigger(n"RefreshPose"))
		{
			bIsAttackingNunchucks = true;
			NunchuckAttackRefreshTimer = NUNCHUCK_ATTACK_POSE_INTERVAL;
			RefreshPose();
		}

		if (bIsAttackingNunchucks)
		{
			if (!Player.IsCapabilityTagBlocked(CapabilityTags::MovementInput))
			{
				RefreshPose();
				bIsAttackingNunchucks = false;
				return;
			}

			NunchuckAttackRefreshTimer -= DeltaSeconds;
			if (NunchuckAttackRefreshTimer <= 0)
			{
				RefreshPose();
				NunchuckAttackRefreshTimer = NUNCHUCK_ATTACK_POSE_INTERVAL;
			}

			return;
		}

		if (FloorMotionComp.AnimData.bTurnaroundTriggered)
		{
			RefreshPose();
			return;
		}

		const bool bLocomotionTagChanged = CachedLocomotionAnimationTag != LocomotionAnimationTag;
		if (bLocomotionTagChanged)
		{
			RefreshPose();
			Timer::SetTimer(this, n"RefreshPose", 0.025);
		}
	}

	/**
	 * Snap the root rotation to the 2D view
	 */
	void CalculateRootRotation()
	{
		bConstrainRoot2D = Player.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller && Player.AttachParentActor == nullptr;

		FVector ForwardVector = Player.ActorForwardVector;

		if (bConstrainRoot2D)
		{
			if (Player.ActorForwardVector.DotProduct(FVector::RightVector) > 0)
				ForwardVector = FVector::RightVector;
			else
				ForwardVector = FVector::LeftVector;
		}

		RootRotation2D = FRotator::MakeFromZX(Player.ActorUpVector, ForwardVector);
	}

	UFUNCTION()
	void RefreshPose()
	{
		bRefreshPose = true;
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	FHazeRange GetRefreshRate()
	{
		if (bIsAttackingNunchucks)
			return FHazeRange(500, 500);

		FHazeRange Range;
		if (CustomRefreshRate.Find(LocomotionAnimationTag, Range))
			return Range;

		return DefaultRefreshRate;
	}
}
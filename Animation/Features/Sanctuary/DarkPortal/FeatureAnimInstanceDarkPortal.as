UCLASS(Abstract)
class UFeatureAnimInstanceDarkPortal : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDarkPortal Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDarkPortalAnimData AnimData;

	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ADarkPortalActor DarkPortal;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFollowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAiming;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLaunchStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLookingForGrab;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasFoundGrab;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrabbing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSettled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRecalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAllowSpineAdditive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimingBlendSpace;

	UDarkPortalUserComponent UserComp;

	UBasicAIAnimationComponent CompanionAnimComp;

	UPlayerWallRunComponent WallRunComp;

	UPlayerRollDashComponent RollDashComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingMeshUpperBodyOverrideAnimation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingLocalUpperBodyOverrideAnimation;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalLookAtBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalRightArmLookAtFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalLeftArmLookAtFilter;

	UPROPERTY(EditDefaultsOnly)
	UHazeBoneFilterAsset LeftArmBoneFilter;

	UPROPERTY(EditDefaultsOnly)
	UHazeBoneFilterAsset RightArmBoneFilter;

	UPROPERTY(EditDefaultsOnly)
	UHazeBoneFilterAsset NullBoneFilter;

	int BlockFrame;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		auto NewFeature = Cast<ULocomotionFeatureDarkPortal>(
			GetFeatureAsClass(ULocomotionFeatureDarkPortal));

		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		UserComp = UDarkPortalUserComponent::Get(HazeOwningActor);
		MoveComp = UPlayerMovementComponent::Get(Player);
		CompanionAnimComp = UBasicAIAnimationComponent::Get(UserComp.Companion);
		DarkPortal = UserComp.Portal;
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(HazeOwningActor);
		RollDashComp = UPlayerRollDashComponent::GetOrCreate(HazeOwningActor);

		BlockFrame = GetAnimIntParam(n"BlockDarkPortal", true);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bFollowing = CompanionAnimComp.FeatureTag == DarkPortalCompanionAnimTags::Follow;
		bLaunchStart = CompanionAnimComp.FeatureTag == DarkPortalCompanionAnimTags::LaunchStart;

		bIsAiming = UserComp.AnimationData.bIsAiming;
		AimingBlendSpace = UserComp.AnimationData.AimSpace;

		bIsLaunching = DarkPortal.IsLaunching() && !bIsAiming;
		bIsLookingForGrab = DarkPortal.IsGrabbingActive();
		bHasFoundGrab = DarkPortal.IsGrabbingAny();
		bIsGrabbing = DarkPortal.HasActiveGrab();
		bIsSettled = DarkPortal.IsSettled();
		bIsRecalling = (DarkPortal.IsRecalling() || CompanionAnimComp.FeatureTag == DarkPortalCompanionAnimTags::PortalExit) && !bIsAiming;

		bIsRequestingMeshUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation");
		bIsRequestingLocalUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation");

		bWantsToMove = MoveComp.GetSyncedMovementInputForAnimationOnly().Size() > SMALL_NUMBER;
		MoveSpeed = (Player.ActorVelocity.Size2D() / 500 * 30) * -1;
		MoveSpeed = Math::Clamp(MoveSpeed, -40.0, 0.0);

		if (GetAnimBoolParam(n"IsInStepDash") || TopLevelGraphRelevantStateName == n"Launching")
			bAllowSpineAdditive = false;
		else
			bAllowSpineAdditive = true;

		if (BlockFrame > 0)
			--BlockFrame;

#if EDITOR
		Print("bIsLookingForGrab: " + bIsLookingForGrab, 0.f);
			/*
			Print("bAllowSpineAdditive " + bAllowSpineAdditive, 0.f);
			l
			Print("bIsGrabbing: " + bIsGrabbing, 0.f); // Emils Print
			Print("IsGrabbingActive: " + DarkPortal.IsGrabbingActive(), 0.0);
			Print("bIsSettled: " + bIsSettled, 0.f); // Emils Print
			Print("bIsLaunching: " + bIsLaunching, 0.f); // Emils Print
			Print("bIsRecalling: " + bIsRecalling, 0.f); // Emils Print
			Print("bHasFoundGrab: " + bHasFoundGrab, 0.f); // Emils Print

			Print("HasActiveGrab: " + DarkPortal.HasActiveGrab(), 0.0);
			Print("IsGrabbingAny: " + DarkPortal.IsGrabbingAny(), 0.0);
			*/

#endif
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (BlockFrame > 0)
			return true;

		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"Jump" && LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"Landing")
			return true;

		if (bWantsToMove || !MoveComp.IsOnWalkableGround())
			return (TopLevelGraphRelevantAnimTimeRemaining < 0.5);

		if (TopLevelGraphRelevantStateName == n"Release")
			return (TopLevelGraphRelevantAnimTimeRemaining < 0.1);

		return (TopLevelGraphRelevantAnimTimeRemaining < 0.1);
		// return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		if (BlockFrame > 0)
			return NullBoneFilter;

		bOutUseMeshSpaceBlend = true;
		// if (LocomotionAnimationTag == n"PoleClimb")
		// {
		// 	bOutUseMeshSpaceBlend = false;
		// 	return LeftArmBoneFilter;
		// }

		if (GetAnimBoolParam(n"RequestingBlockOverrideAnimation") || 
			(TopLevelGraphRelevantStateName == n"Release" && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1) || 
			(TopLevelGraphRelevantStateName == n"Launching" && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1) ||
			RollDashComp.bTriggeredRollDashJump || 
			LocomotionAnimationTag == n"WallScramble" || 
			LocomotionAnimationTag == n"WallRun" || 
			LocomotionAnimationTag == n"SwingAir" || 
			LocomotionAnimationTag == n"Grapple" || 
			LocomotionAnimationTag == n"PoleClimb" || 
			LocomotionAnimationTag == n"LedgeMantle")

		{
			OutBlendTime = 0.2;
			return NullBoneFilter;
		}

		if (LocomotionAnimationTag == n"LadderClimb")
		{
			bOutUseMeshSpaceBlend = true;
			OutBlendTime = 0.2;
			return RightArmBoneFilter;
		}
		// While Roll dashing, use Local Space
		if (bIsRequestingLocalUpperBodyOverrideAnimation)
		{
			bOutUseMeshSpaceBlend = false;
			OutBlendTime = 0.2;
			return BirdPortalRightArmLookAtFilter;
		}

		if (bIsLaunching)
		{
			OutBlendTime = 0.2;
			return BirdPortalBoneFilter;
		}

		// Regular aiming with Mesh Space
		if (TopLevelGraphRelevantStateName == "AimStart")
		{
			OutBlendTime = 0.3;
			return BirdPortalLookAtBoneFilter;
		}

		if (TopLevelGraphRelevantStateName == "AimMh" || TopLevelGraphRelevantStateName == "GrabMH")
		{
			OutBlendTime = 0.3;
			return BirdPortalRightArmLookAtFilter;
		}

		if (TopLevelGraphRelevantStateName == n"GrabStop" || TopLevelGraphRelevantStateName == n"Release")
		{
			OutBlendTime = 0.2;
			return BirdPortalRightArmLookAtFilter;
		}

		OutBlendTime = 0.2;
		return BirdPortalLookAtBoneFilter;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		SetAnimFloatParam(n"MovementBlendTime", 0.4);
		SetAnimBoolParam(n"RequestingBlockOverrideAnimation", false);
		SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", false);
		SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
	}
}

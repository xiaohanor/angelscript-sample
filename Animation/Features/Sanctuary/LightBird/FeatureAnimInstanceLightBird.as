UCLASS(Abstract)
class UFeatureAnimInstanceLightBird : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLightBird Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLightBirdAnimData AnimData;

	ULightBirdUserComponent UserComp;
	UHazeMovementComponent MoveComp;
	UBasicAIAnimationComponent CompanionAnimComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerRollDashComponent RollDashComp;
	UPlayerStepDashComponent StepDashComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimingBlendSpace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFollowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHovering;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLantern;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAiming;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchStart;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchStartAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunching;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchCanceled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLaunchBlocked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRecalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternRecall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIlluminating;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipIlluminatingStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitFeature = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BirdDistance;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SocketDistance;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RecallStartTime = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAllowSpineAdditive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingMeshUpperBodyOverrideAnimation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRequestingLocalUpperBodyOverrideAnimation;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalLookAtBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalLeftArmLookAtBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BirdPortalRightArmLookAtBoneFilter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UHazeBoneFilterAsset BothArms;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UHazeBoneFilterAsset LeftArmBoneFilter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UHazeBoneFilterAsset RightArmBoneFilter;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset NullBoneFilter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	int BlockFrame;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLightBird NewFeature = GetFeatureAsClass(ULocomotionFeatureLightBird);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		UserComp = ULightBirdUserComponent::Get(HazeOwningActor);
		CompanionAnimComp = UBasicAIAnimationComponent::Get(UserComp.Companion);
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(HazeOwningActor);
		RollDashComp = UPlayerRollDashComponent::GetOrCreate(HazeOwningActor);
		StepDashComp = UPlayerStepDashComponent::GetOrCreate(HazeOwningActor);

		bSkipEnter = GetAnimBoolParam(n"SkipLightBirdEnter", true);
		BlockFrame = GetAnimIntParam(n"BlockLightBird", true);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (UserComp == nullptr)
			return;

		bInMovement = (LocomotionAnimationTag == n"Movement");

		bIsRequestingMeshUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation");
		bIsRequestingLocalUpperBodyOverrideAnimation = GetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation");

		BirdDistance = UserComp.Companion.ActorCenterLocation.Distance(OwningComponent.GetSocketLocation(n"LeftAttach"));

		if (UserComp.AttachedTargetData.IsValid())
			SocketDistance = UserComp.Companion.ActorLocation.Distance(UserComp.AttachedTargetData.WorldLocation);
		else
			SocketDistance = BIG_NUMBER;

		AimingBlendSpace = UserComp.AnimationData.AimSpace;
		bIsFollowing = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::Follow;
		bIsLaunchStart = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchStart;
		bIsLaunchStartAttached = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchStartAttach;
		bIsLaunching = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::Launch;
		bIsLaunchAttached = (CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchAttached) || (CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::InvestigateAttached);
		bIsLaunchBlocked = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchBlocked;
		bIsLanternRecall = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LanternRecall;
		bIsIlluminating = UserComp.bIsIlluminating;

		bIsLanternExit = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LanternExit;
		bIsLaunchExit = CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::LaunchExit;

		bIsHovering = UserComp.State == ELightBirdState::Hover;
		bIsAiming = UserComp.State == ELightBirdState::Aiming;
		bIsAttached = UserComp.State == ELightBirdState::Attached;
		bLantern = UserComp.State == ELightBirdState::Lantern;

		bIsRecalling = false;

		bWantsToMove = MoveComp.GetSyncedMovementInputForAnimationOnly().Size() > SMALL_NUMBER;
		MoveSpeed = (Player.ActorVelocity.Size2D() / 500 * 30) * -1;
		MoveSpeed = Math::Clamp(MoveSpeed, -40.0, 0.0);

		if (GetAnimBoolParam(n"IsInStepDash") || TopLevelGraphRelevantStateName == n"Launching")
			bAllowSpineAdditive = false;
		else
			bAllowSpineAdditive = true;

		if (OverrideFeatureTag != n"LightBird")
			bExitFeature = true;
		else
			bExitFeature = false;

		if (BlockFrame > 0)
			--BlockFrame;

#if EDITOR
		
/*
        Print("bSkipIlluminatingStart: " + bSkipIlluminatingStart, 0.f);
		Print("BirdDistance: " + BirdDistance, 0.f);
		Print("UserComp.State: " + UserComp.State, 0.f);
		Print("CompanionAnimComp.FeatureTag: " + CompanionAnimComp.FeatureTag, 0.f);
		Print("MoveComp.IsOnWalkableGround(): " + MoveComp.IsOnWalkableGround(), 0.f);
		Print("UserComp.State: " + UserComp.State, 0.f); // Emils Print
		GetAnimTrigger(n"StartRollDash"

*/
#endif
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeToNullFeature() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeWhenResetting() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (BlockFrame > 0)
			return true;

		if ((bWantsToMove || !MoveComp.IsOnWalkableGround()) &&
		(TopLevelGraphRelevantStateName == n"Illuminating_Stop" ||
		TopLevelGraphRelevantStateName == n"Recall" ||
		TopLevelGraphRelevantStateName == n"LanternRecall"))
			return TopLevelGraphRelevantAnimTimeRemainingFraction < 0.5;
		else if (TopLevelGraphRelevantStateName == n"LanternStop")
			return TopLevelGraphRelevantAnimTimeRemainingFraction < 0.5;
		else if (GetOverrideFeatureTag() != n"LightBird")
			return TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1;
		return TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1;
	}


	UFUNCTION(BlueprintOverride)
	UHazeBoneFilterAsset GetOverrideBoneFilter(float32& OutBlendTime, bool& bOutUseMeshSpaceBlend) const
	{
		if (BlockFrame > 0)
		{
			return NullBoneFilter;
		}
		bOutUseMeshSpaceBlend = true;
	
		// if (LocomotionAnimationTag == n"PoleClimb")
		// {
		// 	bOutUseMeshSpaceBlend = false;
		// 	return LeftArmBoneFilter;
		// }

		if (GetAnimBoolParam(n"RequestingBlockOverrideAnimation") ||
			(CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::Launch && TopLevelGraphRelevantAnimTimeRemainingFraction < 0.1) ||
			RollDashComp.bTriggeredRollDashJump ||
			LocomotionAnimationTag == n"WallScramble" || 
			LocomotionAnimationTag == n"WallRun" ||
			LocomotionAnimationTag == n"SwingAir" ||
			LocomotionAnimationTag == n"Grapple" ||
			LocomotionAnimationTag == n"PoleClimb" ||
			LocomotionAnimationTag == n"LedgeMantle")
		{
			return NullBoneFilter;
		}

		if (LocomotionAnimationTag == n"LadderClimb")
		{
			bOutUseMeshSpaceBlend = false;
			OutBlendTime = 0.2;
			return RightArmBoneFilter;
		}
		
		// While Roll dashing, use Local Space
		if (bIsRequestingLocalUpperBodyOverrideAnimation)
		{
			bOutUseMeshSpaceBlend = false;
			OutBlendTime = 0.2;
			return BirdPortalLeftArmLookAtBoneFilter;
		}

		if (CompanionAnimComp.FeatureTag == LightBirdCompanionAnimTags::Launch &&
			bIsAttached)
		{
			OutBlendTime = 0.2;
			bOutUseMeshSpaceBlend = true;
			return BirdPortalBoneFilter;
		}

		// Regular aiming with Mesh Space
		if (TopLevelGraphRelevantStateName == "LanternEnter" || 
			TopLevelGraphRelevantStateName == "LanternRecall")
		{
			OutBlendTime = 0.3;
			return BirdPortalLookAtBoneFilter;
		}
		if (TopLevelGraphRelevantStateName == "LanternMh" || 
			TopLevelGraphRelevantStateName == "LanternStop")
		{
			OutBlendTime = 0.3;
			return BirdPortalLeftArmLookAtBoneFilter;
		}

		if (TopLevelGraphRelevantStateName == "Launching")
		{
			OutBlendTime = 0.2;
			return BirdPortalBoneFilter;
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
		bSkipIlluminatingStart = false;
		RecallStartTime = 0.0;
	}

	UFUNCTION()
	void AnimNotify_LeftAttachRecall()
	{
		RecallStartTime = 0.2;
	}

	UFUNCTION()
	void AnimNotify_LeftLanternRecall()
	{
		RecallStartTime = 0.0;
	}

	UFUNCTION()
	void AnimNotify_EnteredMh()
	{
		bSkipEnter = false;
	}
    UFUNCTION()
    void AnimNotify_InIlluminating()
    {
        bSkipIlluminatingStart = true;
    }

    UFUNCTION()
    void AnimNotify_StopIlluminating()
    {
        //bSkipIlluminatingStart = false;
    }

}

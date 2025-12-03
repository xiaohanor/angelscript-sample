namespace LightBirdCompanionAnimTags
{
	const FName IntroStart = n"IntroStart";
	const FName IntroReachPlayer = n"IntroReachPlayer";
	const FName Follow = n"Follow";
	const FName LaunchStart = n"LaunchStart";
	const FName LaunchStartAttach = n"LaunchStartAttach";
	const FName Launch = n"Launch";
	const FName LaunchBlocked = n"LaunchBlocked";
	const FName LaunchAttached = n"LaunchAttached";
	const FName LaunchExit = n"LaunchExit";
	const FName LanternRecall = n"LanternRecall";
	const FName LanternAttached = n"LanternAttached";
	const FName LanternExit = n"LanternExit";
	const FName Teleport = n"Teleport";
	const FName Investigate = n"Investigate";
	const FName InvestigateAttached = n"InvestigateAttached";
	const FName TeleportToPlayer = n"TeleportToPlayer";
	const FName Shield = n"Shield";
}

class UAnimInstanceLightBirdCompanion : UAnimInstanceAIBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroReachPlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData HoverMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData StartFly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData StopFly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData FlyMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData FlapMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData DashFlap;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData DiveMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData BankingAdditive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LaunchStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData Launch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LanternStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LanternMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData ShieldMh;

	// Custom Variables

	ULightBirdUserComponent UserComp;

	USanctuaryLightBirdCompanionComponent LightBirdComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFollowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIntroStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIntroReachPlayer;

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
	bool bIsLaunchBlocked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRecalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternRecall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternAttached;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLanternExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldExitAction;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldEnterAction;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTeleportToPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShield;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToSocket;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator MioAttachRotation;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	bool bShouldGlide = false;

	UPROPERTY()
	bool GlideBlendValue = false;

	FTimerHandle GlideTimer;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		if (HazeOwningActor != nullptr)
			LightBirdComp = USanctuaryLightBirdCompanionComponent::Get(HazeOwningActor);

		if (Game::Mio != nullptr)		
			UserComp = ULightBirdUserComponent::Get(Game::Mio);
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (LightBirdComp == nullptr)
			return;
		if (LightBirdComp.UserComp == nullptr)
			return;

		Velocity.X = SpeedRight;
		Velocity.Y = SpeedForward;
		Velocity.Z = SpeedUp;

		bIsFollowing = LightBirdComp.State == ELightBirdCompanionState::Follow;
		bIsIntroStart = IsCurrentFeatureTag(LightBirdCompanionAnimTags::IntroStart);
		bIsIntroReachPlayer = IsCurrentFeatureTag(LightBirdCompanionAnimTags::IntroReachPlayer);
		bIsLaunchStart = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LaunchStart);
		bIsLaunchStartAttached = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LaunchStartAttach);
		bIsLaunching = IsCurrentFeatureTag(LightBirdCompanionAnimTags::Launch);
		bIsLaunchAttached = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LaunchAttached);
		bIsLaunchBlocked = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LaunchBlocked);
		bIsLaunchExit = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LaunchExit);
		bShield = IsCurrentFeatureTag(LightBirdCompanionAnimTags::Shield);

		// Deprecated for now
		bIsLanternRecall = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LanternRecall);
		bIsLanternAttached = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LanternAttached);
		bIsLanternExit = IsCurrentFeatureTag(LightBirdCompanionAnimTags::LanternExit);
		bTeleportToPlayer = IsCurrentFeatureTag(LightBirdCompanionAnimTags::TeleportToPlayer);

		// LightBirdComp.PlayerGroundVelocity

		if (LightBirdComp.Player != nullptr)
		{
			DistanceToPlayer = HazeOwningActor.ActorLocation.Distance(LightBirdComp.Player.FocusLocation);
			MioAttachRotation = LightBirdComp.Player.Mesh.GetSocketRotation(n"Spine2");
			// MioAttachRotation = HazeOwningActor.ActorRotation;
			// Debug::DrawDebugCoordinateSystem(LightBirdComp.Player.Mesh.GetSocketLocation(n"LeftForeArm"), LightBirdComp.Player.Mesh.GetSocketRotation(n"LeftForeArm"), 35.0);
		}

		if (LightBirdComp.UserComp.AimTargetData.IsValid())
		{
			DistanceToSocket = HazeOwningActor.ActorLocation.Distance(LightBirdComp.UserComp.AimTargetData.WorldLocation);
			bHasTarget = true;
		}
		else
		{
			DistanceToSocket = BIG_NUMBER;
			bHasTarget = false;
		}


		bIsLanternStart = bIsLanternRecall && DistanceToPlayer < 200.0;

		// Action exit
		if (bIsLaunchStartAttached || bIsLaunching)
			bShouldEnterAction = true;
		else
			bShouldEnterAction = false;

		// Action exit
		if (LowestLevelGraphRelevantStateName == n"ActionExit")
		{
			bShouldExitAction = true;
		}
		else
			bShouldExitAction = false;

#if EDITOR
/*
		// Print("UserComp.AttachedTargetData.IsValid(): " + LightBirdComp.UserComp.AimTargetData.IsValid(), 0.f); // Emils Print
		// Print("bIsLanternStart: " + bIsLanternStart, 0.f); // Emils Print
		Print("LightBird CurrentFeatureTag: " + CurrentFeatureTag, 0.f);
		Print("UserComp.State: " + UserComp.State, 0.f); // Emils Print
		Print("LightBirdComp.State: " + LightBirdComp.State, 0.f); // Emils Print
		HazeOwningActor.bHazeEditorOnlyDebugBool = true; // Uncomment this, save, comment out again adn save to turn on debug flag during one PIE session without risking checking in spam
		if (HazeOwningActor.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugString(HazeOwningActor.ActorLocation + FVector(0,0,40), "" + CurrentFeatureTag);
		}
*/
#endif
	}

	UFUNCTION()
	void AnimNotify_EnterFlyState()
	{
		GlideBlendValue = false;
		float RndGlideTimer = Math::RandRange(3.0, 10.0);
		GlideTimer = Timer::SetTimer(this, n"ShouldGlide", RndGlideTimer);
	}

	UFUNCTION()
	void AnimNotify_LeftFlyState()
	{
		GlideTimer.ClearTimer();
	}

	UFUNCTION()
	void ShouldGlide()
	{
		GlideBlendValue = true;
		GlideTimer = Timer::SetTimer(this, n"AnimNotify_EnterFlyState", Math::RandRange(1.0, 3.0));
	}
}
class USanctuaryCompanionAviationInitAttackCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;

	ASplineFollowCameraActor InitAttackCam;

	bool bEnabledCamera = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
		{
			ArenaManager = BossManagers[0];
			InitAttackCam = Cast<ASplineFollowCameraActor>(BossManagers.Single.InitAttackCamera);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AviationComp.AviationState != EAviationState::InitAttack)
			return false;

		if (ArenaManager == nullptr)
			return false;

		if (!IsInsideCircleSplineCamera())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.AviationState != EAviationState::InitAttack)
			return true;
		return false;
	}

	bool IsInsideCircleSplineCamera() const
	{
		if (InitAttackCam == nullptr)
			return false;

		bool bInside = false;

		UHazeSplineComponent SplineComp = InitAttackCam.GetSplineToUse();
		auto SplineTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);

		FVector ToPlayer = Player.ActorLocation - SplineTransform.Location;
		bInside = SplineTransform.Rotation.RightVector.DotProduct(ToPlayer) < 1500.0;
		return bInside;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Timer::SetTimer(this, n"DelayedActivation", 1.0);
		bEnabledCamera = false;
	}

	UFUNCTION()
	void DelayedActivation()
	{
		if (IsActive())
		{
			bEnabledCamera = true;
			ArenaManager.EnableInitAttackCamera(Player, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bEnabledCamera)
			ArenaManager.EnableInitAttackCamera(Player, false);
		bEnabledCamera = false;
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	DrawCam();
	// }
	
	void DrawCam()
	{
		if (InitAttackCam != nullptr)
		{
			InitAttackCam.GetSplineToUse().DrawDebug();
		}
	}
};
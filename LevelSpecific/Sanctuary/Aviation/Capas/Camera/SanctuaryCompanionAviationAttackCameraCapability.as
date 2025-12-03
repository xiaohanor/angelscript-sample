
struct FSanctuaryCompanionAviationAttackCameraActivateParams
{
	AStaticCameraActor ChosenCamera;
}

class USanctuaryCompanionAviationAttackCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStaticCameraActor AttackCamera;

	bool bFullScreen = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		TListedActors<ASanctuaryBossArenaManager> BossManager;
		if (BossManager.Num() > 0)
			ArenaManager = BossManager.Single;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryCompanionAviationAttackCameraActivateParams& Params) const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (!IsInStateHandledByThisCapability())
			return false;

		Params.ChosenCamera = NewGetKillCamera();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		if (!IsInStateHandledByThisCapability())
			return true;
		
		return false;
	}

	bool IsInStateHandledByThisCapability() const
	{
		if (AviationComp.AviationState == EAviationState::Attacking)
			return true;

		if (AviationComp.AviationState == EAviationState::TryExitAttack)
			return true;

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryCompanionAviationAttackCameraActivateParams Params)
	{
		AttackCamera = Params.ChosenCamera;
		if (AttackCamera != nullptr)
			Player.ActivateCamera(AttackCamera, AviationComp.Settings.StranglingCameraBlendInTime, this, EHazeCameraPriority::High);
		else
			PrintToScreen("Found No Attack Camera!!", 10.0, FLinearColor::Red);
		USanctuaryCompanionAviationPlayerComponent OtherPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player.OtherPlayer);
		bool bOtherPlayerPrepFullscreenKill = OtherPlayerAviationComp.AviationState == EAviationState::Attacking || OtherPlayerAviationComp.AviationState == EAviationState::InitAttack;
		bFullScreen = false;
		if (CompanionAviation::bFullScreenKill && bOtherPlayerPrepFullscreenKill && AviationComp.KillFullscreenPlayer == nullptr)
		{
			AviationComp.KillFullscreenPlayer = Player;
			OtherPlayerAviationComp.KillFullscreenPlayer = Player;
			bFullScreen = true;
			Camera::BlendToFullScreenUsingProjectionOffset(Player, this, AviationComp.Settings.StranglingCameraBlendInTime, 1.0);
		}	
	}

	AStaticCameraActor NewGetKillCamera() const
	{
		if (ArenaManager == nullptr)
			return nullptr;
		if (ArenaManager.KillCameraOne == nullptr)
			return nullptr;
		if (ArenaManager.KillCameraTwo == nullptr)
			return nullptr;
		if (ArenaManager.KillCameraThree == nullptr)
			return nullptr;
		if (ArenaManager.KillCameraFour == nullptr)
			return nullptr;
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (DestinationData.Actor == nullptr)
			return nullptr;

		// find which one of these bois is ... In front of center? From where we came? Yes, weigh them
		FVector PlayerRelative = (Player.ActorLocation - ArenaManager.ActorLocation).GetSafeNormal();
		FVector HydraHeadRelative = DestinationData.Actor.ActorForwardVector;

		float CamOneWeight = GetTotalWeight(ArenaManager.KillCameraOne, PlayerRelative, HydraHeadRelative);
		float CamTwoWeight = GetTotalWeight(ArenaManager.KillCameraTwo, PlayerRelative, HydraHeadRelative);
		float CamThreeWeight = GetTotalWeight(ArenaManager.KillCameraThree, PlayerRelative, HydraHeadRelative);
		float CamFourWeight = GetTotalWeight(ArenaManager.KillCameraFour, PlayerRelative, HydraHeadRelative);

		float LargestWeight = Math::Max(Math::Max3(CamOneWeight, CamTwoWeight, CamThreeWeight), CamFourWeight) - KINDA_SMALL_NUMBER;
		if (CamOneWeight >= LargestWeight)
			return ArenaManager.KillCameraOne;
		else if (CamTwoWeight >= LargestWeight)
			return ArenaManager.KillCameraTwo;
		else if (CamThreeWeight >= LargestWeight)
			return ArenaManager.KillCameraThree;
		else
			return ArenaManager.KillCameraFour;
	}

	private float GetTotalWeight(AStaticCameraActor KillCamera, FVector PlayerRelative, FVector HydraRelative) const
	{
		FVector KillCamRelative = (KillCamera.Camera.WorldLocation - ArenaManager.ActorLocation).GetSafeNormal();
		return KillCamRelative.DotProduct(PlayerRelative) + KillCamRelative.DotProduct(HydraRelative);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		if (Hydras.Single.IsDefeated())
		{
			StopFullscreen();
			DefeatedCameraTransition();
		}
		else
		{
			StopFullscreen();
			Timer::SetTimer(this, n"DelayedDeactivation", AviationComp.Settings.StrangleSuccessWaitBeforeCameraMoveOn);
		}
	}

	void StopFullscreen()
	{
		if (bFullScreen)
		{
			USanctuaryCompanionAviationPlayerComponent OtherPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player.OtherPlayer);
			AviationComp.KillFullscreenPlayer = nullptr;
			OtherPlayerAviationComp.KillFullscreenPlayer = nullptr;
			Camera::BlendToSplitScreenUsingProjectionOffset(this, AviationComp.Settings.StrangleSuccessWaitBeforeCameraMoveOn * 0.7);
			bFullScreen = false;
		}
	}

	UFUNCTION()
	private void DefeatedCameraTransition()
	{
		if (AttackCamera != nullptr)
			Player.DeactivateCamera(AttackCamera, AviationComp.Settings.StranglingCameraBlendOutTime);

		if (ArenaManager != nullptr && ArenaManager.DefeatedHydraCutsceneCamera != nullptr)
			Player.ActivateCamera(ArenaManager.DefeatedHydraCutsceneCamera, AviationComp.Settings.StranglingCameraBlendOutTime, this, EHazeCameraPriority::Cutscene);
	}

	UFUNCTION()
	private void DelayedDeactivation()
	{
		if (AttackCamera != nullptr)
			Player.DeactivateCamera(AttackCamera, AviationComp.Settings.StranglingCameraBlendOutTime);

		AttackCamera = nullptr;
	}
}

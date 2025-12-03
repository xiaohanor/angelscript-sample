struct FStoneBossQTEWeakpointHitSuccessActivateParams
{
	AStoneBossQTEWeakpoint TargetWeakpoint;
	EPlayerStoneBossQTEWeakpointType WeakpointType;
}

/**
 * If this capability becomes active then both players should stab at the same time.
 * Depending on connection they might get this info at different times so we do some local syncing of the states as well.
 */
class UStoneBossQTEWeakpointSwordHitSuccessCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"StoneBossQTEWeakpoint");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointHit");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointHitSuccess");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 70;

	default DebugCategory = n"Weakpoint";

	AStoneBossQTEWeakpoint Weakpoint;
	EPlayerStoneBossQTEWeakpointType WeakpointType;
	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UDragonSwordUserComponent DragonSwordComp;

	float TimeToValidateHit;
	float TimeToFinishHit;

	bool bHasValidatedHit = false;
	bool bAppliedCameraSettings = false;

	bool bHasStartedStabbing = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStoneBossQTEWeakpointHitSuccessActivateParams& Params) const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		if (!WeakpointComp.Weakpoint.PlayersHitSyncFinished[Player])
			return false;

		if (!WeakpointComp.Weakpoint.bHasSyncedHit)
			return false;

		if (WeakpointComp.Weakpoint.HitSyncInfo != EStoneBossQTENetHitSyncInfo::Success)
			return false;

		Params.TargetWeakpoint = WeakpointComp.Weakpoint;
		Params.WeakpointType = WeakpointComp.WeakpointType;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return true;

		if (bHasStartedStabbing && Time::GetGameTimeSince(Weakpoint.TimeWhenBothPlayersWereReadyToStab) > TimeToFinishHit)
		{
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStoneBossQTEWeakpointHitSuccessActivateParams Params)
	{
		if (DragonSwordComp == nullptr)
			DragonSwordComp = UDragonSwordUserComponent::Get(Player);

		Weakpoint = Params.TargetWeakpoint;
		WeakpointType = Params.WeakpointType;
		Player.BlockCapabilities(n"StoneBossQTEWeakpointSync", this);
		Player.BlockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		Player.BlockCapabilities(n"StoneBossQTEWeakpointHitFail", this);
		Weakpoint.PlayersHitSyncFinished[Player] = false;

		TimeToValidateHit = Weakpoint.SwordHitDrawBackDuration + Weakpoint.SwordHitDuration;
		TimeToFinishHit = Weakpoint.SwordHitDrawBackDuration + Weakpoint.SwordHitDuration + Weakpoint.SwordSucceedHitDuration;

		bHasValidatedHit = false;
		Weakpoint.SetPlayerReadyToStab(Player);

		//Call release event here as this is where the swords start moving
		FStoneBeastWeakpointPlayerReleaseParams ReleaseParams;
		ReleaseParams.Player = Player;
		ReleaseParams.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
		UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointRelease(Player, ReleaseParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Weakpoint.PlayersActivelySyncing[Player] = false;
		WeakpointComp.DrawBackAlpha = 0.0;
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointSync", this);
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointHitFail", this);

		if (HasControl())
		{
			auto OtherWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player.OtherPlayer);
			WeakpointComp.CrumbClearInstigatedState(this);
			OtherWeakpointComp.CrumbClearInstigatedState(this);
		}

		if (bAppliedCameraSettings)
		{
			SceneView::FullScreenPlayer.ClearCameraSettingsByInstigator(this);
		}

		Weakpoint.ClearPlayerReadyToStab(Player);
		WeakpointComp.Weakpoint.ClearSync();

		bHasStartedStabbing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Sync up states locally
		if (!Weakpoint.AreBothPlayersReadyToStab())
			return;

		if (!bHasStartedStabbing)
		{
			bHasStartedStabbing = true;
			if (HasControl())
			{
				auto OtherWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player.OtherPlayer);
				WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Release, this, EInstigatePriority::Normal);
				OtherWeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Release, this, EInstigatePriority::Normal);
			}
		}

		if (HasControl())
		{
			if (Time::GetGameTimeSince(Weakpoint.TimeWhenBothPlayersWereReadyToStab) >= TimeToValidateHit)
			{
				if (!bHasValidatedHit)
				{
					CrumbHandleSuccessHit();
					auto OtherWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player.OtherPlayer);
					WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Success, this, EInstigatePriority::Normal);
					OtherWeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Success, this, EInstigatePriority::Normal);
					bHasValidatedHit = true;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleSuccessHit()
	{
		if ((HasControl() && Network::IsGameNetworked()) || (Player.IsMio() && !Network::IsGameNetworked()))
		{
			Weakpoint.GetHit();
		}

		FStoneBeastWeakpointPlayerStabParams Params;
		Params.Player = Player;
		Params.PlayerStabLocation = DragonSwordComp.Weapon.ActorLocation + DragonSwordComp.Weapon.ActorUpVector * 100.0;

		if (WeakpointType == EPlayerStoneBossQTEWeakpointType::Regular)
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointStabSuccess(Player, Params);
		else
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointStabSuccess(Player, Params);

		Player.PlayCameraShake(Weakpoint.SuccessfulHitCameraShake, this);
		if (WeakpointType == EPlayerStoneBossQTEWeakpointType::Final)
		{
			WeakpointComp.bHoldSuccessMH = true;
		}

		Player.PlayForceFeedback(Weakpoint.ImpactRumble, false, true, this, 1.0);
	}
};
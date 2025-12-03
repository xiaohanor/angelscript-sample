struct FStoneBossQTEWeakpointSyncActivateParams
{
	AStoneBossQTEWeakpoint TargetWeakpoint;
}

struct FStoneBossQTEWeakpointSyncDeactivateParams
{
	bool bWereBothPlayersSyncing;
	bool bIsSyncStateSet;
}

/**
 * Goal of this capability is to sync up weakpoint hitstates.
 * If both players have this capability active at the same time then we want to trigger hitsuccess, otherwise hitfail.
 */
class UStoneBossQTEWeakpointSwordSyncCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(n"StoneBossQTEWeakpoint");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointSync");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	default DebugCategory = n"Weakpoint";

	AStoneBossQTEWeakpoint Weakpoint;

	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UStoneBossQTEPlayerTestInputComponent TestInputComp;

	bool bHasSetSuccessfulHit = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
		TestInputComp = UStoneBossQTEPlayerTestInputComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStoneBossQTEWeakpointSyncActivateParams& Params) const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility) || TestInputComp.IsActioning(StoneBossQTEWeakpoint::TestPrimaryAction))
			return false;

		if (WeakpointComp.DrawBackAlpha < WeakpointComp.DrawBackAlphaThreshold)
			return false;

		Params.TargetWeakpoint = WeakpointComp.Weakpoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FStoneBossQTEWeakpointSyncDeactivateParams& Params) const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return true;

		if (WeakpointComp.Weakpoint.bHasSyncedHit)
		{
			Params.bIsSyncStateSet = true;
			return true;
		}

		if (Weakpoint.HitSyncInfo != EStoneBossQTENetHitSyncInfo::NotSet)
		{
			Params.bIsSyncStateSet = true;
			return true;
		}

		bool bHasWaitedForOtherSide = ActiveDuration > Weakpoint.SwordSucceedTimerThreshold + Network::PingRoundtripSeconds * 0.5;

		if (Weakpoint.AreBothPlayersSyncing() && bHasWaitedForOtherSide)
		{
			Params.bWereBothPlayersSyncing = true;
			return true;
		}

		auto OtherWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player.OtherPlayer);
		if (OtherWeakpointComp == nullptr)
		{
			Params.bWereBothPlayersSyncing = false;
			return true;
		}
		else
		{

			if (bHasWaitedForOtherSide)
			{
				Params.bWereBothPlayersSyncing = false;
				return true;
			}
			if (OtherWeakpointComp.DrawBackAlpha < 0.3)
			{
				Params.bWereBothPlayersSyncing = false;
				return true;
			}
			if (OtherWeakpointComp.InstigatedState.Get() == EPlayerStoneBossQTEWeakpointState::Failure || OtherWeakpointComp.InstigatedState.IsDefaultValue())
			{
				Params.bWereBothPlayersSyncing = false;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStoneBossQTEWeakpointSyncActivateParams Params)
	{
		Weakpoint = Params.TargetWeakpoint;
		Weakpoint.PlayersActivelySyncing[Player] = true;

		Weakpoint.NetworkLock.Acquire(Player, this);

		if (HasControl())
			WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Syncing, this, EInstigatePriority::Normal);

		Player.BlockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		Player.BlockCapabilities(n"StoneBossQTEWeakpointRelease", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FStoneBossQTEWeakpointSyncDeactivateParams Params)
	{
		if (HasControl())
			WeakpointComp.CrumbClearInstigatedState(this);

		Player.UnblockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointRelease", this);

		if (HasControl())
		{
			// Only player with networklock can decide whether the stab was a success or not
			if (Weakpoint.NetworkLock.IsAcquiredByInstigator(Player, this))
			{
				if (Params.bWereBothPlayersSyncing)
					Weakpoint.NetSetHitInfo(EStoneBossQTENetHitSyncInfo::Success);
				else
					Weakpoint.NetSetHitInfo(EStoneBossQTENetHitSyncInfo::Fail);
				Weakpoint.CrumbSetSyncComplete();
			}
		}
		Weakpoint.NetworkLock.Release(Player, this);

		Weakpoint.PlayersActivelySyncing[Player] = false;

		Weakpoint.PlayersHitSyncFinished[Player] = true;
	}
};
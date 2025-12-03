struct FStoneBossQTEWeakpointHitFailActivateParams
{
	AStoneBossQTEWeakpoint TargetWeakpoint;
	EPlayerStoneBossQTEWeakpointType WeakpointType;
}

class UStoneBossQTEWeakpointSwordHitFailCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 70;

	default DebugCategory = n"Weakpoint";

	default CapabilityTags.Add(n"StoneBossQTEWeakpoint");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointHit");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointHitFail");

	AStoneBossQTEWeakpoint Weakpoint;
	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UDragonSwordUserComponent DragonSwordComp;

	EPlayerStoneBossQTEWeakpointType WeakpointType;

	FHazeAcceleratedTransform AccSwordTransform;

	float TimeToValidateHit;
	float TimeToFinishHit;

	float HitFinishDuration;

	bool bHasValidatedHit = false;
	bool bAppliedCameraSettings = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStoneBossQTEWeakpointHitFailActivateParams& Params) const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		if (!WeakpointComp.Weakpoint.PlayersHitSyncFinished[Player])
			return false;

		if (!WeakpointComp.Weakpoint.bHasSyncedHit)
			return false;

		if (WeakpointComp.Weakpoint.HitSyncInfo != EStoneBossQTENetHitSyncInfo::Fail)
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

		if (ActiveDuration > TimeToFinishHit)
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStoneBossQTEWeakpointHitFailActivateParams Params)
	{
		if (DragonSwordComp == nullptr)
			DragonSwordComp = UDragonSwordUserComponent::Get(Player);

		Weakpoint = Params.TargetWeakpoint;
		WeakpointType = Params.WeakpointType;

		Player.BlockCapabilities(n"StoneBossQTEWeakpointSync", this);
		Player.BlockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		Weakpoint.PlayersHitSyncFinished[Player] = false;

		TimeToValidateHit = Weakpoint.SwordHitDrawBackDuration + Weakpoint.SwordHitDuration;
		TimeToFinishHit = Weakpoint.SwordHitDrawBackDuration + Weakpoint.SwordHitDuration + Weakpoint.SwordFailHitDuration;

		bHasValidatedHit = false;

		if (Player.IsMio())
			AccSwordTransform.SnapTo(Weakpoint.MioSwordMeshComp.WorldTransform);
		else
			AccSwordTransform.SnapTo(Weakpoint.ZoeSwordMeshComp.WorldTransform);

		if (HasControl())
			WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Release, this, EInstigatePriority::Normal);

		if (WeakpointComp.IsFurtherAheadThanOtherPlayer())
		{
			SceneView::FullScreenPlayer.ApplyCameraSettings(Weakpoint.ReleaseCameraSettings, Weakpoint.ReleaseCameraSettingsBlendInTime, this, EHazeCameraPriority::High);
			bAppliedCameraSettings = true;
		}
		else
		{
			bAppliedCameraSettings = false;
		}

		//Call release event here as this is where the swords start moving
		FStoneBeastWeakpointPlayerReleaseParams ReleaseParams;
		ReleaseParams.Player = Player;
		ReleaseParams.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
		UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointRelease(Player, ReleaseParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WeakpointComp.DrawBackAlpha = 0.0;
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointSync", this);
		Player.UnblockCapabilities(n"StoneBossQTEWeakpointDrawBack", this);
		WeakpointComp.CrumbClearInstigatedState(this);
		if (bAppliedCameraSettings)
		{
			SceneView::FullScreenPlayer.ClearCameraSettingsByInstigator(this);
		}

		WeakpointComp.Weakpoint.ClearSync();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (ActiveDuration >= TimeToValidateHit)
			{
				if (!bHasValidatedHit)
				{
					TimeToFinishHit = Weakpoint.SwordHitDrawBackDuration + Weakpoint.SwordHitDuration + Weakpoint.SwordFailHitDuration;
					CrumbHandleFailedHit();
					bHasValidatedHit = true;
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleFailedHit()
	{
		Game::Zoe.PlayCameraShake(Weakpoint.FailedHitCameraShake, this);
		FStoneBeastWeakpointPlayerStabParams Params;
		Params.Player = Player;
		Params.PlayerStabLocation = DragonSwordComp.Weapon.ActorLocation + DragonSwordComp.Weapon.ActorUpVector * 100;

		if (WeakpointType == EPlayerStoneBossQTEWeakpointType::Regular)
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointStabFail(Player, Params);
		else
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointStabFail(Player, Params);

		HitFinishDuration = Weakpoint.SwordFailHitDuration;

		WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Failure, this, EInstigatePriority::Normal);
		Weakpoint.FailedHit(Player);
		Player.PlayForceFeedback(Weakpoint.ImpactRumble, false, true, this, 0.5);
	}
};
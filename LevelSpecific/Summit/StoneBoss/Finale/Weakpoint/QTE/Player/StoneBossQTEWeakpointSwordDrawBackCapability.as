struct FStoneBossQTEWeakpointDrawBackActivateParams
{
	AStoneBossQTEWeakpoint TargetWeakpoint;
}

class UStoneBossQTEWeakpointSwordDrawBackCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"StoneBossQTEWeakpoint");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointDrawBack");

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = n"Weakpoint";

	AStoneBossQTEWeakpoint Weakpoint;
	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UStoneBossQTEPlayerTestInputComponent TestInputComp;
	UDragonSwordUserComponent DragonSwordComp;

	FHazeAcceleratedTransform AccSwordTransform;
	FVector Offset;

	bool bAppliedCameraSettings = false;
	bool bIsDrawTutorialActive = false;
	bool bIsReleaseTutorialActive = false;
	bool bHasAppliedReadyState = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
		TestInputComp = UStoneBossQTEPlayerTestInputComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FStoneBossQTEWeakpointDrawBackActivateParams& Params) const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		if (WeakpointComp.Weakpoint.bHasSyncedHit)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !TestInputComp.IsActioning(StoneBossQTEWeakpoint::TestPrimaryAction))
			return false;

		if (WeakpointComp.Weakpoint != nullptr && WeakpointComp.Weakpoint.HasBeenDestroyed())
			return false;

		Params.TargetWeakpoint = WeakpointComp.Weakpoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return true;
		
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !TestInputComp.IsActioning(StoneBossQTEWeakpoint::TestPrimaryAction))
			return true;

		if (WeakpointComp.Weakpoint != nullptr && WeakpointComp.Weakpoint.HasBeenDestroyed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStoneBossQTEWeakpointDrawBackActivateParams Params)
	{
		if (DragonSwordComp == nullptr)
			DragonSwordComp = UDragonSwordUserComponent::Get(Player);

		Weakpoint = Params.TargetWeakpoint;
		if (HasControl())
		{
			WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Charge, this, EInstigatePriority::Normal);
		}

		if (WeakpointComp.IsFurtherAheadThanOtherPlayer())
		{
			SceneView::FullScreenPlayer.ApplyCameraSettings(Weakpoint.DrawBackCameraSettings, Weakpoint.DrawBackCameraSettingsBlendInTime, this);
			bAppliedCameraSettings = true;
		}
		else
		{
			bAppliedCameraSettings = false;
		}

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = NSLOCTEXT("StoneBossQTE", "HoldRT", "Hold");
		if (Player.IsMio())
			TutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;

		if (Player.IsMio())
			Offset = FVector(0, -40, 0);
		else
			Offset = FVector(0, 40, 0);

		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, WeakpointComp.DrawSwordInstigator, AttachOffset = FVector(0, 0, 176.0) + Offset);
		bIsDrawTutorialActive = true;
		bIsReleaseTutorialActive = false;
		bHasAppliedReadyState = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bAppliedCameraSettings)
			SceneView::FullScreenPlayer.ClearCameraSettingsByInstigator(this);

		if (bIsReleaseTutorialActive)
			Player.RemoveTutorialPromptByInstigator(WeakpointComp.ReleaseInstigator);

		if (bIsDrawTutorialActive)
			Player.RemoveTutorialPromptByInstigator(WeakpointComp.DrawSwordInstigator);

		if (HasControl())
			WeakpointComp.CrumbClearInstigatedState(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FStoneBeastWeakpointPlayerChargeParams ChargeParams;
		ChargeParams.Player = Player;
		ChargeParams.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
		UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnWeakpointCharge(Player, ChargeParams);

		float Percent = ActiveDuration / Weakpoint.SwordHitDrawBackDuration;
		WeakpointComp.DrawBackAlpha = Math::Clamp(Percent, 0, 1);

		if (WeakpointComp.DrawBackAlpha >= WeakpointComp.DrawBackAlphaThreshold && WeakpointComp.State >= EPlayerStoneBossQTEWeakpointState::Charge)
		{
			if (bIsDrawTutorialActive)
			{
				Player.RemoveTutorialPromptByInstigator(WeakpointComp.DrawSwordInstigator);
				bIsDrawTutorialActive = false;
			}

			if (HasControl() && !bHasAppliedReadyState)
			{
				WeakpointComp.CrumbApplyInstigatedState(EPlayerStoneBossQTEWeakpointState::Ready, this, EInstigatePriority::Normal);
				bHasAppliedReadyState = true;
			}

			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
			TutorialPrompt.Text = NSLOCTEXT("StoneBossQTE", "ReleaseRT", "Release");
			if (Player.IsMio())
				TutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
			TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;

			if (!bIsReleaseTutorialActive)
			{
				Player.ShowTutorialPromptWorldSpace(TutorialPrompt, WeakpointComp.ReleaseInstigator, AttachOffset = FVector(0,0,176) + Offset);
				bIsReleaseTutorialActive = true;
			}
		}
	}
};
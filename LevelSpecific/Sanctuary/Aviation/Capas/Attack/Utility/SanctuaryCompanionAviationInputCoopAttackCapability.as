class USanctuaryCompanionAviationInputCoopAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default DebugCategory = AviationCapabilityTags::Aviation;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	USanctuaryCompanionAviationPlayerComponent OtherPlayerAviationComp;
	
	bool bHasKillPressed = false;
	bool bButtonMashing = false;
	bool bStickSpinning = false;
	FHazeAcceleratedFloat AccSpinning;
	UButtonMashComponent ButtonMash;
	FHazeAcceleratedFloat AccButtonMashHaptic;
	FHazeAcceleratedFloat AccKill;
	float LastButtonMashProgress = 0.0;
	ASanctuaryBossArenaHydraHead AttackedHead = nullptr;
	bool bAttackSuccess = false;
	float MashDecayedCeiling = 1.0;
	bool bFightingHydra = false;

	bool bDebugKill = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Owner);
		AccKill.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return false;

		if (AviationComp.AviationState != EAviationState::Attacking)
			return false;

		if (!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackedHead == nullptr)
			return true;

		if (AviationComp.AviationState != EAviationState::Attacking)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bButtonMashing = false;
		bStickSpinning = false;
		bHasKillPressed = false;
		bAttackSuccess = false;
		if (OtherPlayerAviationComp == nullptr)
			OtherPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player.OtherPlayer);
		AttackedHead = GetAttackedHydraHead();
		MashDecayedCeiling = 1.0;
		if (!ensure(AttackedHead != nullptr, "Not attacking a head - Please contact Ylva"))
			PrintToScreen("Not attacking a head - Please contact Ylva", 100.0, FLinearColor::Red);
		AviationComp.SyncedKillValue.SetValue(AccKill.Value);
		AviationComp.SyncedKillValue.OverrideSyncRate(EHazeCrumbSyncRate::High);
		bFightingHydra = false;
	}

	bool OtherPlayerIsOnTheWay() const
	{
		return OtherPlayerAviationComp.AviationState == EAviationState::Attacking;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bButtonMashing)
		{
			bButtonMashing = false;
			Player.StopButtonMash(this);
		}
		if (bStickSpinning)
		{
			bStickSpinning = false;
			Player.StopStickSpin(this);
		}
		AccKill.SnapTo(1.0);
		AviationComp.SyncedKillValue.SetValue(1.0);
		AviationComp.SyncedKillValue.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		if (bFightingHydra)
		{
			bFightingHydra = false;
			AttackedHead.ActorsToFightBack.Remove(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bDebugKill = AviationDevToggles::Phase1::Phase1PrintKillValues.IsEnabled();
		if (bDebugKill)
			PrintToScreen("" + Player.GetName() + ", " + AviationComp.AviationState);

		if (AviationComp.AviationState == EAviationState::AttackingSuccessCircling || AviationComp.AviationState != EAviationState::Attacking)
			AccKill.AccelerateTo(1.0, AviationComp.Settings.StranglingReceedDuration, DeltaTime);
		else if (!bAttackSuccess)
		{
			if (!bButtonMashing)
				PlayerStartButtonMash();
			UpdateButtonMashProgress(DeltaTime);

			//bool bAllowFail = !(OtherPlayerAviationComp.AviationState == EAviationState::Attacking && OtherPlayerAviationComp.AviationState == EAviationState::Attacking);
			bool bAllowFail = true;
			bool bIsFailing = AccKill.Value > 1.0 - KINDA_SMALL_NUMBER && ActiveDuration > AviationComp.Settings.StranglingMinAllowedDuration;
			if (bAllowFail && bIsFailing)
				CrumbSetTryExitState();
		}

		ApplyMashHaptic(DeltaTime);
		AviationComp.SyncedKillValue.SetValue(AccKill.Value);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetTryExitState()
	{
		AviationComp.SetAviationState(EAviationState::TryExitAttack);
	}

	private void UpdateButtonMashProgress(float DeltaTime)
	{
		bool bAllowKill = OtherPlayerIsOnTheWay() || !CompanionAviation::bCoopKill;
		if (bAllowKill)
		{
			if (bDebugKill)
				PrintToScreen("Allow kill!");
			MashDecayedCeiling = 1.0;
		}
		else if (ActiveDuration > AviationComp.Settings.StranglingMinAllowedDuration)
		{
			if (!bFightingHydra)
			{
				bFightingHydra = true;
				AttackedHead.ActorsToFightBack.Add(Owner);
			}
			if (bDebugKill)
					PrintToScreen("Decaying!");
			float DecayRateSeconds = Math::Lerp(AviationComp.Settings.MinDecayRateSeconds, AviationComp.Settings.MaxDecayRateSeconds, Player.GetButtonMashProgress(this));
			float DecayRate = 1.0 / DecayRateSeconds;
			// PrintToScreen("Duration: " + ActiveDuration + "/" + DecayRateSeconds);
			// PrintToScreen("DecayRate: " + DecayRate);
			MashDecayedCeiling -= DeltaTime * DecayRate;
			MashDecayedCeiling = Math::Clamp(MashDecayedCeiling, 0.0, 1.0);
		}
		// PrintToScreen("Ceil: " + MashDecayedCeiling);

		float KillProgress = Player.GetButtonMashProgress(this);
		KillProgress = Math::Clamp(KillProgress, 0.0, 1.0);

		float RemappedCeil = Math::EaseOut(0.0, 1.0, MashDecayedCeiling, 2.0);
		float NewMin = Math::Clamp(1.0 - RemappedCeil, 0.0, 1.0);
		float AccDuration = AviationDevToggles::Phase1::Phase1SlowerAttack.IsEnabled() ? 3.0 : 0.1;
		AccKill.AccelerateTo(Math::Lerp(1.0, NewMin, KillProgress), AccDuration, DeltaTime);
	}

	private void PlayerStartButtonMash()
	{
		bButtonMashing = true;
		ButtonMash = UButtonMashComponent::Get(Player);
		FButtonMashSettings Settings;
		Settings.ButtonAction = AviationComp.Settings.ButtonMashButton;
		Settings.Difficulty = AviationComp.Settings.ButtonMashDifficulty;
		Settings.Mode = EButtonMashMode::ButtonMash;
		Settings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;

		if (AviationComp.Settings.bCoopButtonmashWidget && AviationComp.AviationTwoPlayerButtonMashWidgetClass != nullptr)
			Settings.bShowButtonMashWidget = false;
		else
		{
			// Offset Left/Right towards our camera
			float LeftRightSign = Player.IsMio() ? -1.0 : 1.0;
			Settings.WidgetPositionOffset = Player.GetCameraDesiredRotation().RightVector * 1000.0 * LeftRightSign;
			AttackedHead.ButtonMashAttachComponent.AttachToComponent(AttackedHead.SkeletalMesh, n"Spine43");
			Settings.WidgetAttachComponent = AttackedHead.ButtonMashAttachComponent;
		}
		Player.StartButtonMash(Settings, this);
		Player.SetButtonMashAllowCompletion(this, false);
		Player.SetButtonMashGainMultiplier(this, AviationComp.Settings.ButtonMashIncrement);
		// Player.SnapButtonMashProgress(this, 0.9);
	}

	private ASanctuaryBossArenaHydraHead GetAttackedHydraHead()
	{
		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		return Cast<ASanctuaryBossArenaHydraHead>(DestinationData.Actor);
	}

	private void ApplyMashHaptic(float DeltaTime)
	{
		bool bMashing = IsActioning(AviationComp.Settings.ButtonMashButton);
		float Alpha = 1.0 - AccKill.Value;
		float FeedbackAmount = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
		if (bMashing)
			AccButtonMashHaptic.SnapTo(FeedbackAmount);
		AccButtonMashHaptic.AccelerateTo(0.0, 0.1, DeltaTime);
		Player.SetFrameForceFeedback(Alpha, Alpha, Alpha, Alpha, FeedbackAmount);
	}
}
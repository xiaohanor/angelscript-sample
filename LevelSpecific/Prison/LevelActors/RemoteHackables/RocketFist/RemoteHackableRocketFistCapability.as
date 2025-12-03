class URemoteHackableRocketFistCapability : URemoteHackableBaseCapability
{
	ARemoteHackableRocketFist Fist;

	float CurrentEnterTime = 0.0;
	float EnterDuration = 1.55;
	bool bFullyEntered = false;

	bool bCharging = false;

	bool bLaunched = false;

	FHazeAcceleratedFloat AccChargeSpeed;
	float TargetChargeSpeed = 0.0;
	float ChargeSpeed = 0.5;
	float ChargeDecaySpeed = 0.7;
	float CurrentPunchCharge = 0.0;
	bool bFullyCharged = false;

	float ReleaseTutorialPromptDelay = 2.0;
	float CurrentPunchReadyTime = 0.0;
	bool bReleaseTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Fist = Cast<ARemoteHackableRocketFist>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Player.ApplyCameraSettings(Fist.IdleCamSettings, 2.0, Fist, EHazeCameraPriority::High);
		Player.ApplyCameraSettings(Fist.ChargeCamSettings, 1.4, this, EHazeCameraPriority::VeryHigh);

		Player.ApplyManualFractionToCameraSettings(0.0, this);

		APrisonBoss Boss = TListedActors<APrisonBoss>().Single;

		FHazePointOfInterestFocusTargetInfo PoIFocus;
		PoIFocus.SetFocusToActor(Boss);

		FApplyPointOfInterestSettings PoISettings;
		Player.ApplyPointOfInterest(this, PoIFocus, PoISettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.RemoveTutorialPromptByInstigator(this);

		Player.ClearCameraSettingsByInstigator(Fist);
		Player.ClearCameraSettingsByInstigator(this);

		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Fist.bFullySpawned)
			return;

		if (!bFullyEntered)
		{
			CurrentEnterTime += DeltaTime;
			if (CurrentEnterTime >= EnterDuration)
				FullyEntered();

			return;
		}

		Super::TickActive(DeltaTime);

		if (bLaunched)
			return;

		if (HasControl())
		{
			if (IsActioning(ActionNames::PrimaryLevelAbility))
			{
				TargetChargeSpeed = ChargeSpeed;

				if (CurrentPunchCharge >= 1.0 && !bFullyCharged)
				{
					bFullyCharged = true;
					Player.RemoveTutorialPromptByInstigator(this);
				}

				if(!bCharging)
					CrumbStartCharging();

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.4;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.4;
				Player.SetFrameForceFeedback(FF);

				bCharging = true;
			}
			else if (CurrentPunchCharge >= 1.0)
			{
				CrumbLaunchFist();
				bCharging = false;
			}
			else
			{
				TargetChargeSpeed = -ChargeDecaySpeed;

				if(bCharging)
					CrumbCancelCharge();
				
				bCharging = false;
			}

			AccChargeSpeed.AccelerateTo(TargetChargeSpeed, 0.4, DeltaTime);
			CurrentPunchCharge += AccChargeSpeed.Value * DeltaTime;
			CurrentPunchCharge = Math::Clamp(CurrentPunchCharge, 0.0, 1.0);

			if (bFullyCharged)
			{
				CurrentPunchReadyTime += DeltaTime;
				if (!bReleaseTutorialActive && CurrentPunchReadyTime >= ReleaseTutorialPromptDelay)
					ShowReleaseTutorial();
			}

			Player.ApplyManualFractionToCameraSettings(Fist.SyncedFloatComp.Value, this);

			Fist.SyncedFloatComp.SetValue(CurrentPunchCharge);
		}
	}

	void FullyEntered()
	{
		if (bFullyEntered)
			return;

		bFullyEntered = true;
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Player.ShowTutorialPromptWorldSpace(Prompt, this, Fist.RemoteHackingResponseComp, FVector(0.0, 0.0, 200.0), 0.0);
	}

	void ShowReleaseTutorial()
	{
		if (bReleaseTutorialActive)
			return;

		bReleaseTutorialActive = true;

		FTutorialPrompt ReleasePrompt;
		ReleasePrompt.Action = ActionNames::PrimaryLevelAbility;
		ReleasePrompt.Text = Fist.ReleaseTutorialText;
		Player.ShowTutorialPromptWorldSpace(ReleasePrompt, this, TListedActors<APrisonBoss>().Single.Mesh, FVector::ZeroVector, 100.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchFist()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		bLaunched = true;
		Fist.Launch();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartCharging()
	{
		URemoteHackableRocketFistEffectEventHandler::Trigger_HandHackStartCharge(Fist);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelCharge()
	{
		URemoteHackableRocketFistEffectEventHandler::Trigger_HandHackStopCharge(Fist);
	}
}
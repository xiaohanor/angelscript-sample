class UArenaBossHackedCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::HandRemoved;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 0.0;

	AHazePlayerCharacter Player;

	bool bHacked = false;

	float CurrentEnterHackTime = 0.0;
	float EnterHackDuration = 1.9;

	FHazeAcceleratedFloat AccChargeSpeed;
	float TargetChargeSpeed = 0.0;
	float ChargeSpeed = 0.9;
	float ChargeDecaySpeed = 1.2;
	float CurrentPunchCharge = 0.0;

	bool bPunchingFace = false;
	float CurrentPunchFaceTime = 0.0;
	float PunchFaceDuration = 1.6;

	int CurrentPunchAmount = 0;
	int MaxPunchAmount = 3;

	bool bPunchReady = false;

	bool bEntered = false;
	bool bCharging = false;

	float ReleaseTutorialPromptDelay = 2.0;
	float CurrentPunchReadyTime = 0.0;
	bool bReleaseTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Player = Game::GetMio();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bHacked = false;
		CurrentEnterHackTime = 0.0;
		CurrentPunchCharge = 0.0;
		bPunchingFace = false;
		CurrentPunchFaceTime = 0.0;
		CurrentPunchAmount = 0;
		bPunchReady = false;
		bEntered = false;
		bCharging = false;
		AccChargeSpeed.SnapTo(0.0);
		TargetChargeSpeed = 0.0;

		Boss.HackSyncedComp.SetValue(0.0);

		Boss.AnimationData.bHacked = false;
		Boss.AnimationData.bHackedPunch = false;
		Boss.AnimationData.bFinalPunch = false;
		Boss.AnimationData.HackedPunchCharge = 0.0;

		Boss.HackableComp.OnHackingStarted.AddUFunction(this, n"Hacked");

		if (Boss.bRightHandRemoved)
		{
			Boss.HackableComp.AttachToComponent(Boss.LeftHackableRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
			Boss.HackableComp.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));
		}
		
		Boss.HackableComp.SetHackingAllowed(true);

		Boss.BP_ActivateHackableEffect(Boss.bRightHandRemoved);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = Boss.HackTutorialText;
		// Player.ShowTutorialPrompt(TutorialPrompt, this);
		USceneComponent TutorialAttachComp = Boss.bRightHandRemoved ? Boss.LeftHandCollision : Boss.RightHandCollision;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, TutorialAttachComp, FVector(-400.0, 0.0, 0.0), 0.0);

		Boss.EnableHandCollision();

		UArenaBossEffectEventHandler::Trigger_HandHackStateEntered(Boss, GetEffectEventHandData());
	}

	UFUNCTION()
	private void Hacked()
	{
		bHacked = true;
		Boss.AnimationData.bHacked = true;

		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);

		FHazePointOfInterestFocusTargetInfo PoIFocus;
		PoIFocus.SetFocusToComponent(Boss.HackedPunchPoiComp);

		FApplyPointOfInterestSettings PoISettings;
		Player.ApplyPointOfInterest(this, PoIFocus, PoISettings);

		Player.RemoveTutorialPromptByInstigator(this);

		Boss.HackableComp.OnHackingStarted.Unbind(this, n"Hacked");

		Boss.DisableHandCollision();

		float CamOffset = Boss.bRightHandRemoved ? 600.0 : -600.0;
		UCameraSettings::GetSettings(Player).CameraOffsetOwnerSpace.Apply(FVector(0.0, CamOffset, 120.0), this, 2.0, EHazeCameraPriority::VeryHigh);

		UArenaBossEffectEventHandler::Trigger_HandHacked(Boss, GetEffectEventHandData());

		Boss.BP_HandHacked(Boss.bRightHandRemoved);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.ClearViewSizeOverride(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);

		if (Boss.bRightHandRemoved)
		{
			Boss.ActivateState(EArenaBossState::ThrusterBlast);
			Boss.SetLeftHandHidden();
		}
		else
		{
			Boss.ActivateState(EArenaBossState::ArmSmash);
			Boss.SetRightHandHidden();
		}

		Boss.AnimationData.bHacked = false;
		Boss.AnimationData.bHackedPunch = false;
		Boss.AnimationData.HackedPunchCharge = 0.0;
		Boss.AnimationData.bFinalPunch = false;

		UCameraSettings::GetSettings(Player).CameraOffsetOwnerSpace.Clear(this);

		UArenaBossEffectEventHandler::Trigger_HandHackStateEnded(Boss, GetEffectEventHandData());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (IsChargingUpOrWindingDown())
			return;

		if (!bHacked)
			return;

		if (!bEntered)
		{
			CurrentEnterHackTime += DeltaTime;
			if (CurrentEnterHackTime >= EnterHackDuration)
			{
				bEntered = true;
				ShowChargeTutorial();
			}

			return;
		}

		if (bPunchingFace)
		{
			CurrentPunchFaceTime += DeltaTime;
			if (CurrentPunchFaceTime >= PunchFaceDuration)
			{
				bPunchingFace = false;
				Boss.AnimationData.bHackedPunch = false;
				Boss.AnimationData.HackedPunchCharge = 0.0;
				CurrentPunchCharge = 0.0;
				CurrentPunchFaceTime = 0.0;
			}

			return;
		}

		if (bPunchReady)
		{
			CurrentPunchReadyTime += DeltaTime;
			if (!bReleaseTutorialActive && CurrentPunchReadyTime >= ReleaseTutorialPromptDelay)
				ShowReleaseTutorial();
		}

		if (Game::Mio.HasControl())
		{
			if (CurrentPunchCharge >= 1.0)
				PunchReady();

			if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			{
				if (CurrentPunchCharge >= 1.0)
					CrumbPunchFace();
				else
					CrumbCancelCharge();

				bCharging = false;
			}

			else if (IsActioning(ActionNames::PrimaryLevelAbility))
			{
				TargetChargeSpeed = ChargeSpeed;

				if (!bCharging)
					CrumbStartCharging();

				bCharging = true;

				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.4;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.4;
				Player.SetFrameForceFeedback(FF);
			}
			else
			{
				TargetChargeSpeed = -ChargeDecaySpeed;
			}

			AccChargeSpeed.AccelerateTo(TargetChargeSpeed, 0.8, DeltaTime);
			CurrentPunchCharge += AccChargeSpeed.Value * DeltaTime;

			if (!bPunchingFace)
			{
				CurrentPunchCharge = Math::Clamp(CurrentPunchCharge, 0.0, 1.0);
				Boss.HackSyncedComp.SetValue(CurrentPunchCharge);
			}
		}

		Boss.AnimationData.HackedPunchCharge = Boss.HackSyncedComp.Value;
	}

	void ShowChargeTutorial()
	{
		if (Boss.bRightHandRemoved)
			return;

		FTutorialPrompt ChargePrompt;
		ChargePrompt.Action = ActionNames::PrimaryLevelAbility;
		ChargePrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		ChargePrompt.Text = Boss.HackPunchChargeTutorialText;
		USceneComponent TutorialAttachComp = Boss.bRightHandRemoved ? Boss.LeftHackableRoot : Boss.RightHackableRoot;
		Player.ShowTutorialPromptWorldSpace(ChargePrompt, this, TutorialAttachComp, FVector(-400.0, 0.0, 300.0), 0.0);
	}

	void PunchReady()
	{
		if (bPunchReady)
			return;

		bPunchReady = true;

		Player.RemoveTutorialPromptByInstigator(this);

		CrumbFullyCharged();
	}

	void ShowReleaseTutorial()
	{
		if (Boss.bRightHandRemoved)
			return;

		if (bReleaseTutorialActive)
			return;

		if (CurrentPunchAmount != 0)
			return;

		bReleaseTutorialActive = true;

		FTutorialPrompt ReleasePrompt;
		ReleasePrompt.Action = ActionNames::PrimaryLevelAbility;
		ReleasePrompt.Text = Boss.HackPunchReleaseTutorialText;
		Player.ShowTutorialPromptWorldSpace(ReleasePrompt, this, Boss.HeadActor.HeadRoot, FVector::ZeroVector, 100.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartCharging()
	{
		UArenaBossEffectEventHandler::Trigger_HandHackStartCharge(Boss, GetEffectEventHandData());
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelCharge()
	{
		UArenaBossEffectEventHandler::Trigger_HandHackStopCharge(Boss, GetEffectEventHandData());
	}

	UFUNCTION(CrumbFunction)
	void CrumbFullyCharged()
	{
		UArenaBossEffectEventHandler::Trigger_HandHackCharged(Boss, GetEffectEventHandData());
	}

	UFUNCTION(CrumbFunction)
	void CrumbPunchFace()
	{
		bPunchingFace = true;
		bPunchReady = false;

		AccChargeSpeed.SnapTo(0.0);

		Boss.HackSyncedComp.SetValue(0.0);
		Boss.HackSyncedComp.SnapRemote();

		Boss.BP_HackPunchStarted(Boss.bRightHandRemoved);

		CurrentPunchAmount++;
		const bool bIsFinalPunch = CurrentPunchAmount >= MaxPunchAmount;

		if (bIsFinalPunch)
		{
			Timer::SetTimer(this, n"FinalPunch", 0.81);
			Boss.AnimationData.bFinalPunch = true;
		}
		else
		{
			Timer::SetTimer(this, n"PunchImpact", 0.15);
			Boss.AnimationData.bHackedPunch = true;
		}

		Player.RemoveTutorialPromptByInstigator(this);

		auto Data = GetEffectEventHandData();
		Data.bIsFinalPunch = bIsFinalPunch; 

		UArenaBossEffectEventHandler::Trigger_HandHackPunch(Boss, Data);
	}

	UFUNCTION()
	void PunchImpact()
	{
		Boss.TakeDamage(1.0);
		Boss.BP_HackPunchImpact(Boss.bRightHandRemoved);
	}

	UFUNCTION()
	void FinalPunch()
	{
		Player.ClearPointOfInterestByInstigator(this);
		StartWindingDown();

		if (!Boss.bRightHandRemoved)
		{
			Boss.HideRightHand();
			Boss.OnFinalRightPunch.Broadcast();
		}
		else
		{
			Boss.HideLeftHand();
			Boss.OnFinalLeftPunch.Broadcast();
		}

		Boss.HackableComp.SetHackingAllowed(false);

		UCameraSettings::GetSettings(Player).CameraOffsetOwnerSpace.Clear(this);

		Boss.TakeDamage(1.0);

		UArenaBossEffectEventHandler::Trigger_HandHackFinalPunch(Boss, GetEffectEventHandData());
		
		Boss.BP_HandUnhacked(Boss.bRightHandRemoved);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
	}
}
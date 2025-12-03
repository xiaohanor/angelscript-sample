class UArenaBossHeadHackCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::HeadHack;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 0.0;

	AHazePlayerCharacter Player;

	bool bHacked = false;

	float CurrentEnterHackTime = 0.0;
	float EnterHackDuration = 2.35;

	bool bEntered = false;

	bool bHeadPoppedOff = false;
	float HeadLandDuration = 5.0;
	float CurrentHeadLandTime = 0.0;
	bool bHeadHitTheGround = false;
	bool bHeadFullyLanded = false;

	FVector StartLoc;

	URemoteHackingPlayerComponent PlayerHackingComp;
	private bool bHasIniatedHack = false;
	private bool bHasIniatedMagnetBurst = false;

	UMagneticFieldPlayerComponent MagneticPlayerComp;

	UDecalComponent ShadowDecalComp;
	AHazeActor TelegraphActor;

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
		PlayerHackingComp = URemoteHackingPlayerComponent::Get(Player);
		MagneticPlayerComp = UMagneticFieldPlayerComponent::Get(Player.OtherPlayer);	

		bHacked = false;
		CurrentEnterHackTime = 0.0;
		bEntered = false;

		Boss.AnimationData.bHacked = false;
		Boss.AnimationData.bHackedPunch = false;
		Boss.AnimationData.HackedPunchCharge = 0.0;

		Boss.HackableComp.OnLaunchStarted.AddUFunction(this, n"HackLaunchStarted");
		Boss.HackableComp.OnHackingStarted.AddUFunction(this, n"Hacked");

		Boss.HackableComp.WidgetVisualOffset = FVector::ZeroVector;
		Boss.HackableComp.AttachToComponent(Boss.HeadHackableRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		
		Boss.HackableComp.SetHackingAllowed(true);
		Boss.HackableComp.bActivateCameraOnLaunch = true;
		Boss.HackableComp.CameraBlendInTime = 2.0;

		Boss.BP_ActivateHackableHeadEffect();
		Boss.BP_RevealHeadHackablePanel();

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = Boss.HackTutorialText;
		// Player.ShowTutorialPrompt(TutorialPrompt, this);
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, Boss.HeadActor.HeadRoot, FVector(0.0, 0.0, 600.0), 0.0);

		Boss.HeadActor.SetActorEnableCollision(true);

		StartLoc = Boss.ActorLocation;

		UArenaBossEffectEventHandler::Trigger_HeadHackStateEntered(Boss);
	}

	UFUNCTION()
	private void HackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::AcceleratedNormal);

		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION()
	private void Hacked()
	{
		bHacked = true;
		Boss.AnimationData.bHacked = true;

		Timer::SetTimer(this, n"ShowFakeHead", 0.1);

		UArenaBossEffectEventHandler::Trigger_HeadHacked(Boss);
	}

	UFUNCTION()
	private void ShowFakeHead()
	{
		Boss.Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		Boss.HeadActor.SetActorHiddenInGame(false);
		Boss.HeadActor.AttachToComponent(Boss.Mesh, n"Align", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		Boss.HeadActor.Hacked();
		Boss.BP_ActivateCables();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Player.ClearViewSizeOverride(this);
		Game::Zoe.ClearViewSizeOverride(this);
		Player.RemoveTutorialPromptByInstigator(this);

		if (Boss.bRightHandRemoved)
		{
			Boss.ActivateState(EArenaBossState::Idle);
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

		for (AHazePlayerCharacter _Player : Game::GetPlayers())
			_Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(!bHasIniatedHack
		 && PlayerHackingComp.CurrentHackingResponseComp == Boss.HackableComp
		 && IsActioning(ActionNames::PrimaryLevelAbility))
		{
			bHasIniatedHack = true;
			UArenaBossEffectEventHandler::Trigger_HeadHackedStarted(Boss);
			
		}

		if(bHeadPoppedOff && !bHasIniatedMagnetBurst && MagneticPlayerComp.GetChargeState() == EMagneticFieldChargeState::Charging)
		{
			if(Boss.HeadActor.GetDistanceTo(Player.OtherPlayer) < MagneticField::InnerRadius)
			{
				bHasIniatedMagnetBurst = true;
				UArenaBossEffectEventHandler::Trigger_HeadHackMagnetBurstStarted(Boss);
			}
		}

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

				FButtonMashSettings MashSettings;
				MashSettings.ButtonAction = ActionNames::Interaction;
				MashSettings.Difficulty = EButtonMashDifficulty::Medium;
				MashSettings.Duration = 3.0;
				MashSettings.bAllowPlayerCancel = false;
				MashSettings.WidgetAttachComponent = Boss.HeadActor.ButtonMashAttachComp;

				Player.StartButtonMash(MashSettings, this);
				Player.SetButtonMashAllowCompletion(this, false);
			}

			return;
		}

		if (!bHeadPoppedOff)
		{
			float MashValue = Player.GetButtonMashProgress(this);
			Boss.AnimationData.HeadHackCharge = MashValue;
			Boss.HeadActor.MashProgress = MashValue;
			if (Game::Mio.HasControl() && MashValue >= 1.0)
			{
				CrumbPopOffHead();
			}
		}

		if (bHeadPoppedOff && !bHeadFullyLanded)
		{
			CurrentHeadLandTime += DeltaTime;
			if (CurrentHeadLandTime >= HeadLandDuration)
				HeadLanded();

			if (CurrentHeadLandTime <= 4.6)
			{
				FRotator TraceRot = Boss.HeadActor.ActorRotation;
				FHazeTraceSettings KillTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				KillTrace.UseBoxShape(300.0, 220.0, 220.0, FQuat(TraceRot));

				/*FHazeTraceDebugSettings Debug;
				Debug.Thickness = 20.0;
				Debug.TraceColor = FLinearColor::Red;
				KillTrace.DebugDraw(Debug);*/
				
				FVector KillTraceLoc = Boss.HeadActor.ActorLocation + (Boss.HeadActor.ActorUpVector * 150.0);
				FOverlapResultArray OverlapResults = KillTrace.QueryOverlaps(KillTraceLoc);
				for (FOverlapResult Result : OverlapResults)
				{
					AHazePlayerCharacter CrushedPlayer = Cast<AHazePlayerCharacter>(Result.Actor);
					if (CrushedPlayer != nullptr && CrushedPlayer.IsZoe())
						CrushedPlayer.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector), Boss.ImpactDeathEffect);
				}
			}
			else
			{
				if (!bHeadHitTheGround)
				{
					bHeadHitTheGround = true;
					// ShadowDecalComp.DestroyComponent(this);
					TelegraphActor.DestroyActor();
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPopOffHead()
	{
		bHeadPoppedOff = true;
		Player.StopButtonMash(this);

		Boss.AnimationData.bHeadPoppedOff = true;

		Boss.BP_SnapCables();

		Boss.TakeDamage(3.0);

		for (AHazePlayerCharacter _Player : Game::GetPlayers())
			_Player.PlayCameraShake(Boss.FlameThrowerCameraShake, this, 4.0);

		Timer::SetTimer(this, n"ChangeViewSize", 3.5);

		FVector HeadLandLoc = Boss.DefaultLocation;
		HeadLandLoc -= FVector::ForwardVector * 3070.0;
		HeadLandLoc -= FVector::RightVector * 1250.0;

		// ShadowDecalComp = Decal::SpawnDecalAtLocation(Boss.SmashShadowMaterial, FVector(650.0), HeadLandLoc);
		TelegraphActor = SpawnActor(Boss.TelegraphDecalClass, HeadLandLoc);
		TelegraphActor.SetActorScale3D(FVector(2.0));

		UArenaBossEffectEventHandler::Trigger_HeadHackPoppedOff(Boss);
	}

	UFUNCTION()
	private void ChangeViewSize()
	{
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::AcceleratedSlow);
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::AcceleratedSlow);
	}

	void HeadLanded()
	{
		bHeadFullyLanded = true;
		Boss.HeadActor.MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");

		for (AHazePlayerCharacter _Player : Game::GetPlayers())
			_Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		Boss.AnimationData.bHeadMagnetized = true;
		Boss.BP_SnapCables();

		Boss.OnHeadLaunched.Broadcast();

		Boss.TakeDamage(3.0);

		UArenaBossEffectEventHandler::Trigger_HeadHackMagnetBurst(Boss);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
	}
}
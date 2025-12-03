class UIslandWalkerHeadHatchInteractionCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default CapabilityTags.Add(n"HatchInteraction");

	UIslandWalkerHeadHatchInteractionComponent HatchInteractComp;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerHeadHatchRoot HatchRoot;
	USceneComponent FakePistolTarget;
	UHazeCharacterSkeletalMeshComponent HeadMesh;
	UIslandRedBlueWeaponUserComponent WeaponUser;
	UIslandWalkerHeadHatchShootablePanel ShootablePanel;
	UAnimSequence HatchStrugglingAnim;
	UIslandWalkerSettings WalkerSettings;

	float ExitTime;
	float GrabCanCancelTime;
	float GrabCompleteTime;
	float LiftOffCompleteTime;
	float HatchOpenedTime;
	bool bAllowedShooting = true;
	float ShowShootTutorialTime;
	bool bShowingTutorial;
	int LastHeadHurtReactionIndex = -1;
	float HurtReactionDoneTime;
	float LastStoppedShootingTime = 0.0;
	bool bWasButtonMashing = false;

	UIslandWalkerHeadHatchButtonMashComponent ButtonMashComp;	
	FHazeAcceleratedFloat AccButtonMashHaptic;

	EWalkerHeadHatchInteractionState PrevState;
	EIslandRedBlueWeaponUpgradeType	DefaultWeaponUpgrade;

	EWalkerHeadHatchInteractionState PendingState = EWalkerHeadHatchInteractionState::None;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ButtonMashComp = UIslandWalkerHeadHatchButtonMashComponent::GetOrCreate(Player); 
	}

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		return CheckInteraction.IsA(UIslandWalkerHeadHatchInteractionComponent);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		HatchInteractComp = Cast<UIslandWalkerHeadHatchInteractionComponent>(ActiveInteraction);
		HeadComp = UIslandWalkerHeadComponent::Get(HatchInteractComp.Owner);
		HeadMesh = Cast<AHazeCharacter>(HatchInteractComp.Owner).Mesh;
		HatchRoot = UIslandWalkerHeadHatchRoot::Get(HatchInteractComp.Owner);
		WalkerSettings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(HatchInteractComp.Owner));
		ShootablePanel = UIslandWalkerHeadHatchShootablePanel::Get(HatchInteractComp.Owner);
		WeaponUser = UIslandRedBlueWeaponUserComponent::Get(Owner);
		WeaponUser.ApplyForcedTarget(UIslandWalkerHeadHatchShootablePanel::Get(HatchInteractComp.Owner), this);
		if (Player.IsMio())
			WeaponUser.AddHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		else
			WeaponUser.AddHandBlocker(EIslandRedBlueWeaponHandType::Right, this);

		HatchInteractComp.State = EWalkerHeadHatchInteractionState::Grab;
		PrevState = EWalkerHeadHatchInteractionState::Initial;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		DisallowShooting();

		FakePistolTarget = USceneComponent::GetOrCreate(HatchInteractComp.Owner, Player.IsMio() ? n"MioFakeTarget" : n"ZoeFakeTarget");

		// We take care of cancel ourselves
		Player.BlockCapabilities(n"InteractionCancel", this);
		Player.RootComponent.AttachToComponent(HatchInteractComp, NAME_None,
			EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget,
			EAttachmentRule::KeepRelative, false);
		HatchInteractComp.SetPlayerIsAbleToCancel(Player, false);
		ExitTime = BIG_NUMBER;
		GrabCanCancelTime = BIG_NUMBER;
		GrabCompleteTime = BIG_NUMBER;	
		HatchOpenedTime = BIG_NUMBER;	
		LiftOffCompleteTime = BIG_NUMBER;
		DefaultWeaponUpgrade = WeaponUser.CurrentUpgradeType;			
		ShowShootTutorialTime = BIG_NUMBER;
		bShowingTutorial = false;
		LastHeadHurtReactionIndex = HeadComp.EscapeHurtIndex;
		HurtReactionDoneTime = BIG_NUMBER;

		auto HeadAniminstance = Cast<UFeatureAnimInstanceWalker>(HeadMesh.AnimInstance);
		if (ensure(IsValid(HeadAniminstance.HeadHatchStruggle.Sequence)))
			HatchStrugglingAnim = HeadAniminstance.HeadHatchStruggle.Sequence;

		bWasButtonMashing = false;

		PendingState = EWalkerHeadHatchInteractionState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClearAnims();

		Super::OnDeactivated();

		WeaponUser.ClearForcedTarget(this);
		FakePistolTarget.DetachFromParent();

		if (Player.IsMio())
			WeaponUser.RemoveHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		else
			WeaponUser.RemoveHandBlocker(EIslandRedBlueWeaponHandType::Right, this);

		if(Player.RootComponent.AttachParent == HatchInteractComp)
			Player.DetachRootComponentFromParent();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		AllowShooting();
		WeaponUser.RemoveForceHoldWeaponInHandInstigator(this); 
		Player.UnblockCapabilities(n"InteractionCancel", this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		HatchInteractComp.SetPlayerIsAbleToCancel(Player, true);
		HatchInteractComp.State = EWalkerHeadHatchInteractionState::None;
		HeadComp.CloseHatch(this);

		if (HeadComp.bHeadShakeOffPlayers)
		{
			// ominoreG! 
			FVector Impulse = FVector(0.0, 0.0, WalkerSettings.HeadEscapeThrowOffPlayerImpulse.Z);
			Impulse += HatchInteractComp.Owner.ActorForwardVector * WalkerSettings.HeadEscapeThrowOffPlayerImpulse.X;
			float SideSign = (HatchInteractComp.Owner.ActorRightVector.DotProduct(Player.ActorLocation - Player.OtherPlayer.ActorLocation) > 0.0) ? 1.0 : -1.0;
			Impulse += HatchInteractComp.Owner.ActorRightVector * SideSign * WalkerSettings.HeadEscapeThrowOffPlayerImpulse.Y;
			Player.AddMovementImpulse(Impulse);
		}

		// No clear for upgrade type, so reset to what we had when starting instead
		WeaponUser.SetCurrentUpgradeType(DefaultWeaponUpgrade);
		WeaponUser.ClearForcedTarget(this);

		if (bShowingTutorial)
			HideShootTutorial();
		ButtonMashComp.Hide();
	}

	void ClearAnims()
	{
		// Stop any animations we were playing (quick and dirty, we'll replace this by feature)
		Player.StopSlotAnimationByAsset(HatchInteractComp.WaitingMHAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.GrabHatchAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.StruggleAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.OpenAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.HoldingOpenMHAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.ShootingMHAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.LiftOffAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.FailOpenHatchAnim);
		Player.StopSlotAnimationByAsset(HatchInteractComp.ThrowOffAnim);
	}

	void GrabHatch()
	{
		if (PrevState != HatchInteractComp.State)
		{
			Player.PlaySlotAnimation(Animation = HatchInteractComp.GrabHatchAnim);
			GrabCanCancelTime = ActiveDuration + 0.2;
			GrabCompleteTime = ActiveDuration + HatchInteractComp.GrabHatchAnim.PlayLength - 0.2;
		}

		if (ActiveDuration > GrabCanCancelTime)
		{
			GrabCanCancelTime = BIG_NUMBER;
			HatchInteractComp.SetPlayerIsAbleToCancel(Player, true);
		}

		if (ActiveDuration > GrabCompleteTime)
		{
			// Always start with struggle, need to complete button mash to open hatch
			HatchInteractComp.State = EWalkerHeadHatchInteractionState::Struggle;
		}
	}

	void StruggleWithHatch()
	{
		if (PrevState != HatchInteractComp.State)
		{
			// Start struggling with hatch, synced with hatch anim if it's already running
			float SyncPosition = 0.0;
			if (HeadComp.HeadHatchState == EWalkerHeadHatchState::Struggling)
			{
				TArray<FHazePlayingAnimationData> Animations;
				HeadMesh.GetCurrentlyPlayingAnimations(Animations);
				for (FHazePlayingAnimationData AnimData : Animations)
				{
					if (AnimData.Sequence != HatchStrugglingAnim)
						continue;
					SyncPosition = AnimData.CurrentPosition;			
				}
			}
			Player.PlaySlotAnimation(Animation = HatchInteractComp.StruggleAnim, bLoop = true, StartTime = SyncPosition);
			ButtonMashComp.Start(HatchRoot, WalkerSettings);
			HeadComp.StruggleWithHatch(this);
		}

		// Head decides when button mash is completed for both players
		if (HeadComp.HasControl() && ButtonMashComp.IsCompleted())
			CrumbOpenHatch();

		ButtonMashComp.Update();

		if (!bWasButtonMashing && (ButtonMashComp.SyncedProgress.Value > 0.01))
		{
			bWasButtonMashing = true;
			UIslandWalkerHeadEffectHandler::Trigger_OnHatchButtonMash(Cast<AHazeActor>(HeadComp.Owner), FIslandWalkerPlayerHatchParams(Player));
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbOpenHatch()
	{
		HatchInteractComp.State = EWalkerHeadHatchInteractionState::Opening;			
		HatchInteractComp.Other.State = EWalkerHeadHatchInteractionState::Opening;			
	}

	void WaitForOtherPlayer()
	{
		// No waiting for now, always struggle
		HatchInteractComp.State = EWalkerHeadHatchInteractionState::Struggle;
	}

	void OpeningHatch()
	{
		if (PrevState != HatchInteractComp.State)
		{
			Player.PlaySlotAnimation(Animation = HatchInteractComp.OpenAnim, bLoop = true);
			HatchOpenedTime = ActiveDuration + HatchInteractComp.OpenAnim.PlayLength - 0.2;
			
			// Do not allow player to exit after we've started opening hatch
			HatchInteractComp.SetPlayerIsAbleToCancel(Player, false);

			HeadComp.OpenHatch(this);

			ButtonMashComp.Hide();
		}

		if (ActiveDuration > HatchOpenedTime)
		{
			// Progress to open hatch state so proper anim will play
			HatchInteractComp.State = EWalkerHeadHatchInteractionState::Open;	

			// Player control side decides when player is ready to shoot into open hatch
			if (HasControl())
				CrumbReadyToShoot();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbReadyToShoot()
	{
		// We're now allowed to shoot
		AllowShooting();
		ShowShootTutorialTime = ActiveDuration + WalkerSettings.HatchShowShootTutorialDelay;

		// No overheating
		WeaponUser.SetCurrentUpgradeType(EIslandRedBlueWeaponUpgradeType::Assault);

		// Forced target, no HUD
		WeaponUser.ApplyForcedTarget(ShootablePanel, this, false, EInstigatePriority::High);
	}

	void HoldOpenHatch()
	{
		if (PrevState != HatchInteractComp.State)
		{
			// React to head hurt or play base hold open hatch mh
			if (!PlayHeadHurtResponse(HatchInteractComp.HeadHurtIdleReactions)) 
				Player.PlaySlotAnimation(Animation = HatchInteractComp.HoldingOpenMHAnim, bLoop = true);
		}
		else if (HeadComp.EscapeHurtIndex != LastHeadHurtReactionIndex)
		{
			// New hurt anim
			PlayHeadHurtResponse(HatchInteractComp.HeadHurtIdleReactions); 
		}
		else if (ActiveDuration > HurtReactionDoneTime)
		{
			// Return to idle mh
			HurtReactionDoneTime = BIG_NUMBER;
			Player.PlaySlotAnimation(Animation = HatchInteractComp.HoldingOpenMHAnim, bLoop = true);
		}

		// Replicate starting to shoot
		if (HasControl() && IsActioning(ActionNames::WeaponFire))
			CrumbShootIntoHatch();
	}

	UFUNCTION(CrumbFunction)
	void CrumbShootIntoHatch()
	{
		HatchInteractComp.State = EWalkerHeadHatchInteractionState::Shooting;	
		UIslandWalkerHeadEffectHandler::Trigger_OnShootingInToHatch(Cast<AHazeActor>(HeadComp.Owner), FIslandWalkerPlayerHatchParams(Player));
	}

	void ShootIntoHatch()
	{
		if (PrevState != HatchInteractComp.State)
		{
			// React to head hurt or play base shooting mh
			if (!PlayHeadHurtResponse(HatchInteractComp.HeadHurtShootingReactions)) 
				Player.PlaySlotAnimation(Animation = HatchInteractComp.ShootingMHAnim, bLoop = true);
		}
		else if (HeadComp.EscapeHurtIndex != LastHeadHurtReactionIndex)
		{
			// New hurt anim
			PlayHeadHurtResponse(HatchInteractComp.HeadHurtShootingReactions); 
		}
		else if (ActiveDuration > HurtReactionDoneTime)
		{
			// Return to shooting mh
			HurtReactionDoneTime = BIG_NUMBER;
			Player.PlaySlotAnimation(Animation = HatchInteractComp.ShootingMHAnim, bLoop = true);
		}

		// Replicate shooting -> not shooting transition, but make sure we won't spam
		if (HasControl() && !IsActioning(ActionNames::WeaponFire) && (ActiveDuration > LastStoppedShootingTime + 0.2))
			CrumbStopShootingIntoHatch();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopShootingIntoHatch()
	{
		LastStoppedShootingTime = ActiveDuration;

		// Note that on control this sets Open state before PrevState is updated, 
		// so next tick PrevState == HatchInteractComp.State. 
		// We therefore sets a pending state. Only done here for super safety at end of project, 
		// but something likes this should properly always use a pending state or similar solution.
		// Most transitions work since they go from a state higher up in execution order in TickActive.
		// Note that minimum change is to only set this on control. On remote this crumbfunction will 
		// run before capability TickActive so work as expected.
		if (HasControl())
			PendingState = EWalkerHeadHatchInteractionState::Open;
		else 
			HatchInteractComp.State = EWalkerHeadHatchInteractionState::Open;		
	}

	bool PlayHeadHurtResponse(TArray<UAnimSequence> Responses)
	{
		LastHeadHurtReactionIndex = HeadComp.EscapeHurtIndex;
		int iHurt = HeadComp.EscapeHurtIndices.IsValidIndex(HeadComp.EscapeHurtIndex) ? HeadComp.EscapeHurtIndices[HeadComp.EscapeHurtIndex] : -1;
		if (!Responses.IsValidIndex(iHurt))
			return false;

		float AnimSyncOffset = Time::GameTimeSeconds - HeadComp.EscapeHurtReactionStartTime;
		UAnimSequence Anim = Responses[iHurt];
		if (Anim.ScaledPlayLength < AnimSyncOffset)
			return false;
		
		Player.PlaySlotAnimation(Animation = Anim, bLoop = false, StartTime = AnimSyncOffset, bExtractRootMotion = false);
		HurtReactionDoneTime = ActiveDuration + Anim.ScaledPlayLength - AnimSyncOffset;
		return true;
	}

	void LiftOff(float DeltaTime)
	{
		if (PrevState != HatchInteractComp.State)
		{
			// We'll be one frame behind walker head, so start a bit into anim
			Player.PlaySlotAnimation(Animation = HatchInteractComp.LiftOffAnim, bLoop = false, bExtractRootMotion = false, StartTime = DeltaTime);
			LiftOffCompleteTime = ActiveDuration + HatchInteractComp.LiftOffAnim.PlayLength;

			// Shoot in gun direction during liftoff, head is bucking too much
			FakePistolTarget.AttachToComponent(Player.Mesh, Player.IsMio() ? n"RightAttach" : n"LeftAttach", EAttachmentRule::SnapToTarget);
			FakePistolTarget.RelativeLocation = FVector(0.0, -1000.0, 0.0); // This is pistol barrel forward
			WeaponUser.ApplyForcedTarget(FakePistolTarget, this);

			if (bShowingTutorial)
				HideShootTutorial();
			ShowShootTutorialTime = BIG_NUMBER;
		}

		if (ActiveDuration > LiftOffCompleteTime)
		{
			// Hands are now steady
			WeaponUser.ApplyForcedTarget(UIslandWalkerHeadHatchShootablePanel::Get(HatchInteractComp.Owner), this);

			if (HasControl() && IsActioning(ActionNames::WeaponFire))
			{
				CrumbShootIntoHatch();
			}
			else
			{
				// Note that remote will fall back to open unless crumb for shooting reaches us before 
				// this state expire, in which case we won't enter this function again		
				HatchInteractComp.State = EWalkerHeadHatchInteractionState::Open; 
			}
		}
	}

	void FailOpenHatch(float DeltaTime)
	{
		if (PrevState != HatchInteractComp.State)
		{
			// We'll be one frame behind walker head, so start a bit into anim
			Player.PlaySlotAnimation(Animation = HatchInteractComp.FailOpenHatchAnim, bLoop = true, bExtractRootMotion = false, StartTime = DeltaTime);
		
			if (bShowingTutorial)
				HideShootTutorial();
			DisallowShooting();
			ShowShootTutorialTime = BIG_NUMBER;
			HeadComp.CloseHatch(this);
		}
		// No action possible until head shakes off players
	}

	void ThrownOff(float DeltaTime)
	{
		if (PrevState != HatchInteractComp.State)
		{
			// We'll be one frame behind walker head, so start a bit into anim
			Player.PlaySlotAnimation(Animation = HatchInteractComp.ThrowOffAnim, bLoop = false, bExtractRootMotion = false, StartTime = DeltaTime);
		
			if (bShowingTutorial)
				HideShootTutorial();
			DisallowShooting();
			ShowShootTutorialTime = BIG_NUMBER;
			HeadComp.CloseHatch(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Grab)
			GrabHatch();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Struggle)
			StruggleWithHatch();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Waiting)
			WaitForOtherPlayer();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Opening)
			OpeningHatch();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::LiftOff)
			LiftOff(DeltaTime);
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Open)
			HoldOpenHatch();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::Shooting)
			ShootIntoHatch();
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::FailOpen)
			FailOpenHatch(DeltaTime);
		if (HatchInteractComp.State == EWalkerHeadHatchInteractionState::ThrownOff)
			ThrownOff(DeltaTime);

		// Check if player wants to let go of the hatch
		if ((HatchInteractComp.State != EWalkerHeadHatchInteractionState::Exiting) && 
			HatchInteractComp.CanPlayerCancel(Player) &&
			Player.HasControl() && 
			WasActionStarted(ActionNames::Cancel))
		{
			CrumbCancelInteraction();
		}

	 	if (HeadComp.bHeadShakeOffPlayers)
			LeaveInteraction();
		else if (HeadComp.bHeadEscapeSuccess)
			LeaveInteraction();
		else if (ActiveDuration > ExitTime)
			LeaveInteraction();

		if (ActiveDuration > ShowShootTutorialTime)
			ShowShootTutorial();
		if (bShowingTutorial && (Time::GetGameTimeSince(WeaponUser.TimeOfStartShooting) < 2.5))
			HideShootTutorial();

		UpdateButtonMashHapticFeedback(DeltaTime);

		PrevState = HatchInteractComp.State;

		if (PendingState != EWalkerHeadHatchInteractionState::None)
		{
			// Set pending state after updating PrevState
			HatchInteractComp.State = PendingState;
			PendingState = EWalkerHeadHatchInteractionState::None;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelInteraction()
	{
		HatchInteractComp.State = EWalkerHeadHatchInteractionState::Exiting;
		HatchInteractComp.SetPlayerIsAbleToCancel(Player, false);
		ExitTime = ActiveDuration + 0.5;
		
		// No exit anim for now
		ClearAnims();
	}

	void ShowShootTutorial()
	{
		bShowingTutorial = true;
		ShowShootTutorialTime = BIG_NUMBER;
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.Text = NSLOCTEXT("IslandWalker", "ShootHatchPrompt", "Shoot");
		Player.ShowTutorialPrompt(Prompt, this);
	}

	void HideShootTutorial()
	{
		bShowingTutorial = false;
		Player.RemoveTutorialPromptByInstigator(this);
	}

	void UpdateButtonMashHapticFeedback(float DeltaTime)
	{
		bool bMashing = IsActioning(ActionNames::Interaction);
		float Alpha = ButtonMashComp.SyncedProgress.Value;
		float FeedbackAmount = Math::EaseIn(0.0, 0.3, Alpha, 1.0);
		if (bMashing)
			AccButtonMashHaptic.SnapTo(FeedbackAmount);
		AccButtonMashHaptic.AccelerateTo(0.0, 0.1, DeltaTime);
		Player.SetFrameForceFeedback(Alpha, Alpha, Alpha, Alpha, FeedbackAmount);
	}

	void AllowShooting()
	{
		if (!bAllowedShooting)
		{
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

			// Note that we dont remove this until deactivating interaction.
			// Once we're allowed to shoot, our pistol should stay in hand until done.
			WeaponUser.AddForceHoldWeaponInHandInstigator(this); 
		}
		bAllowedShooting = true;
	}

	void DisallowShooting()
	{
		if (bAllowedShooting)
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		bAllowedShooting = false;
	}
};

class UVillagePumpCartPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	AVillagePumpCart PumpCart;
	UVillagePumpCartPlayerComponent PlayerComp;

	bool bLeftSide = true;

	AHazeCameraActor Camera;

	int SuccessfulPumps = 0;
	bool bTutorialCompleted = false;
	bool bTutorialActive = false;

	float EnterDuration = 2.0;
	bool bEntered = false;

	bool bCancelled = false;
	float ExitDuration = 1.2;
	float CurrentExitTime = 0.0;
	bool bExitFinished = false;

	bool bBothPlayersEntered = false;
	bool bCanCancel = false;
	bool bBufferedPumpSuccess = false;

	bool bFullscreenTransitionFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UVillagePumpCartPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.PumpCart == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.PumpCart == nullptr)
			return true;

		if (bExitFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bEntered = false;
		bCancelled = false;
		CurrentExitTime = 0.0;
		bExitFinished = false;
		bCanCancel = false;

		PumpCart = PlayerComp.PumpCart;

		if (Player.IsZoe())
			bLeftSide = false;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Player.AttachToComponent(PumpCart.CartRoot, NAME_None, EAttachmentRule::KeepWorld);

		ULocomotionFeaturePumpCart Feature = Player.IsMio() ? PumpCart.MioFeature : PumpCart.ZoeFeature;
		Player.AddLocomotionFeature(Feature, this);

		if (!HasControl() || !Network::IsGameNetworked())
		{
			if (PumpCart.bMioInteracting && PumpCart.bZoeInteracting)
				NetLockInDoubleInteract();
			else
				NetAllowCancel();
		}
	}

	UFUNCTION(NetFunction)
	void NetLockInDoubleInteract()
	{
		if (!PumpCart.bBothPlayersInteracting)
		{
			devCheck(PumpCart.bMioInteracting && PumpCart.bZoeInteracting);
			PumpCart.BothPlayersEntered();
		}
	}

	UFUNCTION(NetFunction)
	void NetAllowCancel()
	{
		bCanCancel = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerCancel()
	{
		bCancelled = true;
		PumpCart.InteractionCancelled(Player);

		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);

		Player.SetAnimBoolParam(n"PumpCartCancel", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		if (Camera != nullptr)
			Player.DeactivateCamera(Camera);

		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);

		ULocomotionFeaturePumpCart Feature = Player.IsMio() ? PumpCart.MioFeature : PumpCart.ZoeFeature;
		Player.RemoveLocomotionFeature(Feature, this);

		PlayerComp.PumpCart = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"PumpCart", this);

		if (bCancelled || PumpCart.bReachedTop)
		{
			CurrentExitTime += DeltaTime;
			if (CurrentExitTime >= ExitDuration)
				bExitFinished = true;

			return;
		}

		if (ActiveDuration < EnterDuration)
			return;
		else
			EnterFinished();

		if (!PumpCart.bBothPlayersInteracting)
		{
			if (HasControl())
			{
				if (WasActionStarted(ActionNames::Cancel) && bCanCancel)
				{
					CrumbTriggerCancel();
				}
			}

			return;
		}
		else
		{
			if (!bBothPlayersEntered)
			{
				BothPlayersEntered();
			}
		}

		if (PumpCart.bFailActive)
			return;

		if (!bFullscreenTransitionFinished)
		{
			if (PumpCart.bFullscreenTransitionFinished)
				FullscreenTransitionFinished();
			
			return;
		}

		if (HasControl())
		{
			const bool bHasPumpInput = WasActionStarted(ActionNames::PrimaryLevelAbility);

			if (bHasPumpInput && PumpCart.bPumping)
			{
				if (bLeftSide && !PumpCart.bPumpOnLeftSide)
				{
					if (PumpCart.CurrentPumpTime >= PumpCart.BufferThreshold)
					{
						bBufferedPumpSuccess = true;
					}
					else
					{
						NetFailPump();
					}
				}
				else if (!bLeftSide && PumpCart.bPumpOnLeftSide)
				{
					if (PumpCart.CurrentPumpTime >= PumpCart.BufferThreshold)
					{
						bBufferedPumpSuccess = true;
					}
					else
					{
						NetFailPump();
					}
				}
			}
			else if (!PumpCart.bPumping && (bHasPumpInput || bBufferedPumpSuccess))
			{
				if (PumpCart.bPumpOnLeftSide && bLeftSide)
				{
					NetPump();
				}
				else if (!PumpCart.bPumpOnLeftSide && !bLeftSide)
				{
					NetPump();
				}
			}
		}

		if (!bTutorialCompleted && !PumpCart.bPumping && !bTutorialActive)
		{
			if (bLeftSide && PumpCart.bPumpOnLeftSide)
			{
				ShowTutorialPrompt();
			}
			else if (!bLeftSide && !PumpCart.bPumpOnLeftSide)
			{
				ShowTutorialPrompt();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetFailPump()
	{
		PumpCart.FailPump(Player);
		bBufferedPumpSuccess = false;
	}

	UFUNCTION(NetFunction)
	void NetPump()
	{
		PumpCart.Pump();
		bBufferedPumpSuccess = false;
		SuccessfulPumps++;

		RemoveTutorialPrompt();
	}

	void EnterFinished()
	{
		if (bEntered)
			return;

		bEntered = true;

		if (!bBothPlayersEntered)
			Player.ShowCancelPrompt(this);
	}

	void BothPlayersEntered()
	{
		bBothPlayersEntered = true;
		Player.RemoveCancelPromptByInstigator(this);
	}

	void FullscreenTransitionFinished()
	{
		bFullscreenTransitionFinished = true;

		if (bLeftSide)
			ShowTutorialPrompt();
	}

	void ShowTutorialPrompt()
	{
		if (bTutorialCompleted)
			return;

		bTutorialActive = true;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Text = PumpCart.PumpTutorialText;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

		AVillagePumpCartHandle Handle = TListedActors<AVillagePumpCartHandle>().Single;
		USceneComponent AttachComp = Player.IsMio() ? Handle.LeftHandle : Handle.RightHandle;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, AttachComp, FVector(0.0), 0.0);
	}

	void RemoveTutorialPrompt()
	{
		if (bTutorialCompleted)
			return;

		bTutorialActive = false;

		if (SuccessfulPumps >= 2)
		{
			bTutorialCompleted = true;
		}

		Player.RemoveTutorialPromptByInstigator(this);
	}
}
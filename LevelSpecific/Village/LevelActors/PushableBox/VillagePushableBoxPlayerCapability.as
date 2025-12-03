class UVillagePushableBoxPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AVillagePushableBox BoxActor;
	UVillagePushableBoxPlayerComponent PlayerComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	bool bEntered = false;
	bool bStruggling = false;
	bool bPushing = false;
	bool bPlayingMh = false;
	bool bCancelled = false;
	bool bExitFinished = false;

	bool bTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.BoxActor == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!bEntered)
			return false;

		if (PlayerComp.BoxActor == nullptr)
			return true;

		if (PlayerComp.BoxActor.bFullyPushed)
			return true;

		if (bExitFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BoxActor = PlayerComp.BoxActor;
		UInteractionComponent InteractionComp = Player.IsMio() ? BoxActor.LeftInteractionComp : BoxActor.RightInteractionComp;
		InteractionComp.BlockCancelInteraction(Player, this);

		bEntered = false;
		bStruggling = false;
		bPushing = false;
		bPlayingMh = false;
		bCancelled = false;
		bExitFinished = false;

		FHazeAnimationDelegate OnEntered;
		OnEntered.BindUFunction(this, n"EnterFinished");
		Player.PlaySlotAnimation(OnBlendingOut = OnEntered, Animation = BoxActor.EnterAnim);

		MoveComp.FollowComponentMovement(BoxActor.RootComp, this);

		PlayerComp.bPushing = false;
		PlayerComp.bStruggling = false;

		ULocomotionFeatureVillagePushBox Feature = Player.IsMio() ? BoxActor.MioFeature : BoxActor.ZoeFeature;
		Player.AddLocomotionFeature(Feature, this);

		Player.ApplyCameraSettings(BoxActor.CamSettings, 2.0, this);
	}

	UFUNCTION()
	private void EnterFinished()
	{
		if (!IsActive())
			return;

		bEntered = true;

		if (BoxActor.GetDistanceFromStart() <= 150.0)
		{
			bTutorialActive = true;
			
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Up;
			TutorialPrompt.Text = NSLOCTEXT("PushBoxTutorial", "PushBoxPrompt", "Push");
			USceneComponent AttachComp = Player.IsMio() ? BoxActor.LeftTutorialAttachComp : BoxActor.RightTutorialAttachComp;
			Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, AttachComp, FVector::ZeroVector, 0.0);
		}

		UInteractionComponent InteractionComp = Player.IsMio() ? BoxActor.LeftInteractionComp : BoxActor.RightInteractionComp;
		InteractionComp.UnblockCancelInteraction(Player, this);

		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this);

		BoxActor.CrumbSetPlayerPushStatus(Player, false);

		RemoveTutorial();
		bTutorialActive = false;

		Player.RemoveCancelPromptByInstigator(this);
		
		if (PlayerComp.BoxActor != nullptr)
		{
			UInteractionComponent InteractionComp = Player.IsMio() ? PlayerComp.BoxActor.LeftInteractionComp : PlayerComp.BoxActor.RightInteractionComp;
			InteractionComp.KickAnyPlayerOutOfInteraction();
		}

		PlayerComp.BoxActor = nullptr;

		ULocomotionFeatureVillagePushBox Feature = Player.IsMio() ? BoxActor.MioFeature : BoxActor.ZoeFeature;
		Player.RemoveLocomotionFeature(Feature, this);

		Player.ClearCameraSettingsByInstigator(this);
	}

	void RemoveTutorial()
	{
		if (bTutorialActive)
			Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bCancelled)
		{
			Player.RequestLocomotion(n"Movement", this);
			return;
		}

		Player.RequestLocomotion(n"VillagePushBox", this);

		if (bEntered)
		{
			if (WasActionStarted(ActionNames::Cancel))
			{
				CrumbCancel();
				return;
			}
		}
		else
			return;

		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
				if (Input.Y > 0.0)
				{
					if (!BoxActor.IsPlayerPushing(Player))
						BoxActor.CrumbSetPlayerPushStatus(Player, true);

					if (BoxActor.IsOtherPlayerPushing(Player))
					{
						if (!bPushing)
							CrumbStartPushAnim();
					}
					else
					{
						if (!bStruggling)
							CrumbStartStruggleAnim();
					}
				}
				else
				{
					if (BoxActor.IsPlayerPushing(Player))
						BoxActor.CrumbSetPlayerPushStatus(Player, false);
					
					if (!bPlayingMh)
						CrumbPlayMh();
				}
			}
		}

		//Just applying movement here for now so remote side actually updates follow component movement [AL].
		MoveComp.ApplyMove(Movement);

		if (bTutorialActive && BoxActor.GetDistanceFromStart() >= 150.0)
			RemoveTutorial();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartStruggleAnim()
	{
		if (bStruggling)
			return;

		if (bStruggling)
			UVillagePushableBoxEffectEventHandler::Trigger_PlayerStartStruggling(BoxActor, GetEffectEventParams());

		if (bPushing)
			UVillagePushableBoxEffectEventHandler::Trigger_PlayerStopPushing(BoxActor, GetEffectEventParams());

		bStruggling = true;
		bPlayingMh = false;
		bPushing = false;

		PlayerComp.bPushing = false;
		PlayerComp.bStruggling = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartPushAnim()
	{
		if (bPushing)
			return;

		if (bStruggling)
			UVillagePushableBoxEffectEventHandler::Trigger_PlayerStopStruggling(BoxActor, GetEffectEventParams());

		bPushing = true;
		bStruggling = false; 
		bPlayingMh = false;

		UVillagePushableBoxEffectEventHandler::Trigger_PlayerStartPushing(BoxActor, GetEffectEventParams());

		PlayerComp.bStruggling = false;
		PlayerComp.bPushing = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayMh()
	{
		if (bPlayingMh)
			return;

		if (bStruggling)
			UVillagePushableBoxEffectEventHandler::Trigger_PlayerStopStruggling(BoxActor, GetEffectEventParams());

		if (bPushing)
			UVillagePushableBoxEffectEventHandler::Trigger_PlayerStopPushing(BoxActor, GetEffectEventParams());

		bPlayingMh = true;
		bStruggling = false;
		bPushing = false;

		PlayerComp.bStruggling = false;
		PlayerComp.bPushing = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancel()
	{
		if (bCancelled)
			return;

		bCancelled = true;

		FHazeAnimationDelegate OnExitFinished;
		OnExitFinished.BindUFunction(this, n"ExitFinished");
		Player.PlaySlotAnimation(OnBlendingOut = OnExitFinished, Animation = BoxActor.ExitAnim[Player]);

		Player.RemoveCancelPromptByInstigator(this);
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION()
	private void ExitFinished()
	{
		bExitFinished = true;
	}

	FVillagePushableBoxEffectEventParams GetEffectEventParams()
	{
		FVillagePushableBoxEffectEventParams Params;
		Params.Player = Player;
		return Params;
	}
}
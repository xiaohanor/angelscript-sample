/**
 * Copy of ThreeShotInteractionCapability except it also plays animations on the teen dragons.
 */
class UTeenDragonThreeShotInteractionCapability : UInteractionCapability
{
	UTeenDragonThreeShotInteractionComponent TeenDragonThreeShotComp;

	AHazeActor InteractionActor;
	UTeenDragonThreeShotInteractionComponent ThreeShotComp;

	UPlayerTeenDragonComponent PlayerDragonComp;

	FThreeShotSettings PlayerSettings;
	FThreeShotSettings DragonSettings;

	EThreeShotState State = EThreeShotState::Initial;
	bool bIsCanceled = false;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		return CheckInteraction.IsA(UTeenDragonThreeShotInteractionComponent);
	}

	void AdvanceToState(EThreeShotState NewState)
	{
		if (NewState >= EThreeShotState::EnterBlendedIn && State < EThreeShotState::EnterBlendedIn)
		{
			UThreeShotEffectEventHandler::Trigger_EnterBlendedIn(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnEnterBlendedIn.Broadcast(Player, ThreeShotComp);
		}

        if (NewState >= EThreeShotState::EnterBlendingOut && State < EThreeShotState::EnterBlendingOut)
		{
			UThreeShotEffectEventHandler::Trigger_EnterBlendingOut(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnEnterBlendingOut.Broadcast(Player, ThreeShotComp);
		}

        if (NewState >= EThreeShotState::MHBlendedIn && State < EThreeShotState::MHBlendedIn)
		{
			UThreeShotEffectEventHandler::Trigger_MHBlendedIn(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnMHBlendedIn.Broadcast(Player, ThreeShotComp);
		}

        if (NewState >= EThreeShotState::MHBlendingOut && State < EThreeShotState::MHBlendingOut)
		{
			UThreeShotEffectEventHandler::Trigger_MHBlendingOut(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnMHBlendingOut.Broadcast(Player, ThreeShotComp);
		}

        if (NewState >= EThreeShotState::ExitBlendedIn && State < EThreeShotState::ExitBlendedIn)
		{
			UThreeShotEffectEventHandler::Trigger_ExitBlendedIn(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnExitBlendedIn.Broadcast(Player, ThreeShotComp);
		}

        if (NewState >= EThreeShotState::ExitBlendingOut && State < EThreeShotState::ExitBlendingOut)
		{
			UThreeShotEffectEventHandler::Trigger_ExitBlendingOut(InteractionActor, MakeEffectEventParams());
            ThreeShotComp.OnExitBlendingOut.Broadcast(Player, ThreeShotComp);
		}

		if (NewState > State)
			State = NewState;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		ThreeShotComp = Cast<UTeenDragonThreeShotInteractionComponent>(ActiveInteraction);
		PlayerDragonComp = UPlayerTeenDragonComponent::Get(Player);
		InteractionActor = Cast<AHazeActor>(ActiveInteraction.Owner);
		PlayerSettings = ThreeShotComp.ThreeShotSettings[Player];
		DragonSettings = ThreeShotComp.DragonThreeShotSettings[Player];
		State = EThreeShotState::Initial;
		bIsCanceled = false;

		// We take care of cancel ourselves so we can play the exit animation
		Player.BlockCapabilities(n"InteractionCancel", this);

		FMoveToDestination Destination(ThreeShotComp);
		FTransform DestinationTransform = Destination.CalculateDestination(Player.ActorTransform, ThreeShotComp.MovementSettings);

		Player.RootComponent.AttachToComponent(ThreeShotComp, NAME_None,
			EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget,
			EAttachmentRule::KeepRelative, false);
		Player.SetActorTransform(DestinationTransform);

		ThreeShotComp.SetPlayerIsAbleToCancel(Player, false);

		UThreeShotEffectEventHandler::Trigger_Activated(InteractionActor, MakeEffectEventParams());

		// Play animation
		if (PlayerSettings.EnterAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(this, n"HandleEnterBlendedIn"),
				OnBlendingOut = FHazeAnimationDelegate(this, n"HandleEnterBlendingOut"),
				Animation = PlayerSettings.EnterAnimation,
				BlendType = PlayerSettings.BlendType,
				BlendTime = PlayerSettings.BlendTime,
			);
			PlayerDragonComp.GetTeenDragon().PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(),
				Animation = DragonSettings.EnterAnimation,
				BlendType = DragonSettings.BlendType,
				BlendTime = DragonSettings.BlendTime,
			);
		}
		else
		{
			HandleEnterBlendedIn();
			HandleEnterBlendingOut();
		}

		// Play audio for enter
		if (PlayerSettings.EnterAudio != nullptr)
		{
			Player.PlayerAudioComponent.PostEvent(PlayerSettings.EnterAudio);
		}

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if (MoveComp != nullptr)
			MoveComp.ClearVerticalLerp();
	}

	UFUNCTION()
	private void HandleEnterBlendedIn()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::EnterBlendedIn);
	}

	UFUNCTION()
	private void HandleEnterBlendingOut()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::EnterBlendingOut);
		ThreeShotComp.SetPlayerIsAbleToCancel(Player, true);

		if (PlayerSettings.MHAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(this, n"HandleMHBlendedIn"),
				OnBlendingOut = FHazeAnimationDelegate(this, n"HandleMHBlendingOut"),
				Animation = PlayerSettings.MHAnimation,
				BlendType = PlayerSettings.BlendType,
				BlendTime = PlayerSettings.BlendTime,
				bLoop = true,
			);
			PlayerDragonComp.GetTeenDragon().PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(),
				Animation = DragonSettings.MHAnimation,
				BlendType = DragonSettings.BlendType,
				BlendTime = DragonSettings.BlendTime,
				bLoop = true,
			);
		}
		else
		{
			HandleMHBlendedIn();
		}
	}

	UFUNCTION()
	private void HandleMHBlendedIn()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::MHBlendedIn);
	}

	UFUNCTION()
	private void HandleMHBlendingOut()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::MHBlendingOut);
	}

	void PlayExitAnimation()
	{
		if (PlayerSettings.ExitAnimation != nullptr)
		{
			Player.PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(this, n"HandleExitBlendedIn"),
				OnBlendingOut = FHazeAnimationDelegate(this, n"HandleExitBlendingOut"),
				Animation = PlayerSettings.ExitAnimation,
				BlendType = PlayerSettings.BlendType,
				BlendTime = PlayerSettings.BlendTime,
			);
			PlayerDragonComp.GetTeenDragon().PlaySlotAnimation(
				OnBlendedIn =  FHazeAnimationDelegate(),
				OnBlendingOut = FHazeAnimationDelegate(),
				Animation = DragonSettings.ExitAnimation,
				BlendType = DragonSettings.BlendType,
				BlendTime = DragonSettings.BlendTime,
			);
		}
		else
		{
			Player.StopSlotAnimationByAsset(PlayerSettings.MHAnimation);

			HandleExitBlendedIn();
			HandleExitBlendingOut();
		}
	}

	UFUNCTION()
	private void HandleExitBlendedIn()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::ExitBlendedIn);
	}

	UFUNCTION()
	private void HandleExitBlendingOut()
	{
		if (!IsActive())
			return;

		AdvanceToState(EThreeShotState::ExitBlendingOut);
		LeaveInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Stop any animation we were playing
		if (State < EThreeShotState::EnterBlendingOut && PlayerSettings.EnterAnimation != nullptr)
		{
			Player.StopSlotAnimationByAsset(PlayerSettings.EnterAnimation);
		}
		else if (State < EThreeShotState::MHBlendingOut && PlayerSettings.MHAnimation != nullptr)
		{
			Player.StopSlotAnimationByAsset(PlayerSettings.MHAnimation);
		}
		else if (State < EThreeShotState::ExitBlendingOut && PlayerSettings.ExitAnimation != nullptr)
		{
			// Only stop exit when blocked, otherwise continue it if we can
			if (IsBlocked())
				Player.StopSlotAnimationByAsset(PlayerSettings.ExitAnimation);
		}

		// Finish the entire state sequence
		if (IsValid(InteractionActor))
			AdvanceToState(EThreeShotState::Finished);

		Super::OnDeactivated();

		// Reset state pushed by us
		if(Player.RootComponent.AttachParent == ThreeShotComp)
			Player.DetachRootComponentFromParent();
		
		Player.UnblockCapabilities(n"InteractionCancel", this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		if (IsValid(ThreeShotComp))
			ThreeShotComp.SetPlayerIsAbleToCancel(Player, true);

		// Put the player back on the ground but lerp the mesh there as the player moves
		Player.SnapToGround(bLerpVerticalOffset=true, OverrideTraceDistance = 10);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle the player canceling the threeshot
		if (!bIsCanceled && ThreeShotComp.CanPlayerCancel(Player))
		{
			if (WasActionStarted(ActionNames::Cancel))
			{
				CrumbCancelThreeShot();
			}
		}

		// Play the exit animation when canceling
		if (bIsCanceled)
		{
			if (State >= EThreeShotState::EnterBlendingOut && State < EThreeShotState::MHBlendingOut)
			{
				AdvanceToState(EThreeShotState::MHBlendingOut);
				PlayExitAnimation();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelThreeShot()
	{
		bIsCanceled = true;
		if (IsValid(ThreeShotComp))
		{
			ThreeShotComp.SetPlayerIsAbleToCancel(Player, false);
			ThreeShotComp.OnCancelPressed.Broadcast(Player, ThreeShotComp);
		}
	}

	FThreeShotEffectEventParams MakeEffectEventParams()
	{
		FThreeShotEffectEventParams Params;
		Params.Player = Player;
		Params.InteractionActor = InteractionActor;
		Params.InteractionComponent = ThreeShotComp;
		return Params;
	}
};
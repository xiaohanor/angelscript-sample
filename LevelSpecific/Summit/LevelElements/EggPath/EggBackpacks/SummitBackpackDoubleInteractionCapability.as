class USummitBackpackDoubleInteractionCapability : UInteractionCapability
{
	ASummitBackpackDoubleInteractionActor InteractionActor;

	bool bIsAttached = false;
	bool bCompletedByThisPlayer = false;
	USummitEggBackpackComponent BackpackComp;
	ASummitEggBackpack Backpack;
	FDoubleInteractionSettings Settings;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		return CheckInteraction.Owner.IsA(ASummitBackpackDoubleInteractionActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		InteractionActor = Cast<ASummitBackpackDoubleInteractionActor>(ActiveInteraction.Owner);
		Settings = InteractionActor.GetDoubleInteractionSettingsForPlayer(Player, ActiveInteraction);
		bCompletedByThisPlayer = false;

		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;

		// Try to acquire the completion lock
		InteractionActor.CompletionLock.Acquire(Player, this);

		FDoubleInteractionState& InteractionState = InteractionActor.State;
		InteractionState.PlayerState[Player].Reset();
		InteractionState.PlayerState[Player].bIsInteracting = true;

		// Player should be attached to the interaction while it's happening
		bIsAttached = true;
		if (ActiveInteraction.MovementSettings.HasMovement())
		{
			FMoveToDestination Destination(ActiveInteraction);
			FTransform DestinationTransform = Destination.CalculateDestination(Player.ActorTransform, ActiveInteraction.MovementSettings);

			Player.RootComponent.AttachToComponent(ActiveInteraction, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, false);

			Player.SetActorTransform(DestinationTransform);
		}
		else
		{
			Player.RootComponent.AttachToComponent(ActiveInteraction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepRelative, false);
		}

		// We take care of cancel ourselves so we can play the exit animation
		Player.BlockCapabilities(n"InteractionCancel", this);
		ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);

		FDoubleInteractionEventParams EventParams;
		EventParams.Player = Player;
		EventParams.InteractionActor = InteractionActor;
		EventParams.InteractionComponent = ActiveInteraction;
		UDoubleInteractionEffectEventHandler::Trigger_Activated(InteractionActor, EventParams);

		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if (MoveComp != nullptr)
			MoveComp.ClearVerticalLerp();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(InteractionActor))
		{
			FDoubleInteractionState& InteractionState = InteractionActor.State;

			// If the interaction was locked in but this capability deactivated, broadcast completion
			// This can happen if it gets blocked after lock-in
			if (bCompletedByThisPlayer)
			{
				if (InteractionState.Status == EDoubleInteractionStatus::LockedIn)
					InteractionActor.OnDoubleInteractionCompleted.Broadcast();

				InteractionState.Status = EDoubleInteractionStatus::None;
			}

			InteractionState.PlayerState[Player].bIsInteracting = false;

			// Reset state pushed by us
			InteractionActor.CompletionLock.Release(Player, this);
			ActiveInteraction.SetPlayerIsAbleToCancel(Player, true);
		}

		Player.UnblockCapabilities(n"InteractionCancel", this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		// Stop any still playing animations to be sure
		Player.StopSlotAnimationByAsset(Settings.EnterAnimation);
		Player.StopSlotAnimationByAsset(Settings.CancelAnimation);
		Player.StopSlotAnimationByAsset(Settings.CompletedAnimation);
		Player.StopSlotAnimationByAsset(Settings.MHAnimation);

		Backpack.StopAllSlotAnimations();

		if (bIsAttached && Player.RootComponent.AttachParent == ActiveInteraction)
		{
			bIsAttached = false;
			Player.DetachRootComponentFromParent();
		}

		if (IsValid(InteractionActor))
		{
			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteraction;
			UDoubleInteractionEffectEventHandler::Trigger_Deactivated(InteractionActor, EventParams);
		}

		Super::OnDeactivated();

		// Put the player back on the ground but lerp the mesh there as the player moves
		Player.SnapToGround(bLerpVerticalOffset = true, OverrideTraceDistance = 10);
	}

	UFUNCTION(BlueprintOverride)
	void OnStartQuiet()
	{
		// When the remote capability goes Quiet, we should detach so we don't
		// create weirdness when a movement capability takes over "too early" due to
		// differing network delays.
		if (bIsAttached && Player.RootComponent.AttachParent == ActiveInteraction)
		{
			bIsAttached = false;
			Player.DetachRootComponentFromParent();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle completion when both players are in the double interaction
		FDoubleInteractionState& InteractionState = InteractionActor.State;
		if (Player.HasControl() && InteractionActor.CompletionLock.IsAcquired(Player))
		{
			if (InteractionState.Status == EDoubleInteractionStatus::None)
			{
				// If both players are interacting right now and haven't canceled, complete the interaction
				if (InteractionState.PlayerState[0].bIsInteracting && InteractionState.PlayerState[1].bIsInteracting && !InteractionState.PlayerState[Player].bHasCanceled)
				{
					CrumbLockInDoubleInteract();
					if (InteractionState.PreventCompletionInstigators.Num() == 0)
					{
						if (InteractionState.PlayerState[0].bHasEnterCompleted && InteractionState.PlayerState[1].bHasEnterCompleted)
						{
							AllowImmediateDeactivationFromBlocks();
							CrumbCompleteDoubleInteract();
						}
					}
				}
				else
				{
					// We can only cancel if we hold the completion lock right now
					if (!InteractionState.PlayerState[Player].bHasCanceled)
					{
						ActiveInteraction.SetPlayerIsAbleToCancel(Player, true);
						if (ActiveInteraction.CanPlayerCancel(Player))
						{
							if (WasActionStarted(ActionNames::Cancel))
							{
								InteractionState.PlayerState[Player].bHasCanceled = true;
								ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
							}
						}
					}
					else
					{
						ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
					}
				}
			}
			else if (InteractionState.Status == EDoubleInteractionStatus::LockedIn)
			{
				ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);

				// Once nothing is preventing us from completing, trigger the double interact
				if (InteractionState.PreventCompletionInstigators.Num() == 0)
				{
					if (InteractionState.PlayerState[0].bHasEnterCompleted && InteractionState.PlayerState[1].bHasEnterCompleted)
					{
						AllowImmediateDeactivationFromBlocks();
						CrumbCompleteDoubleInteract();
					}
				}
			}
			else if (InteractionState.Status == EDoubleInteractionStatus::Completed)
			{
				ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
			}
		}
		else
		{
			ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLockInDoubleInteract()
	{
		FDoubleInteractionState& InteractionState = InteractionActor.State;
		InteractionState.Status = EDoubleInteractionStatus::LockedIn;
		bCompletedByThisPlayer = true;

		InteractionActor.OnDoubleInteractionLockedIn.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCompleteDoubleInteract()
	{
		FDoubleInteractionState& InteractionState = InteractionActor.State;
		InteractionState.Status = EDoubleInteractionStatus::Completed;
		InteractionState.PlayerState[0].bHasCompletedInteraction = true;
		InteractionState.PlayerState[1].bHasCompletedInteraction = true;
		bCompletedByThisPlayer = true;

		InteractionActor.OnDoubleInteractionCompleted.Broadcast();
	}
};

class USummitBackpackDoubleInteractionEnterAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 5;

	ASummitBackpackDoubleInteractionActor InteractionActor;
	UInteractionComponent ActiveInteractionComponent;
	FDoubleInteractionSettings BackpackSettings;

	UPlayerInteractionsComponent PlayerInteractionsComp;

	float AnimationLength = 0;
	bool bTriggeredFinish = false;
	FDoubleInteractionSettings Settings;
	USummitEggBackpackComponent BackpackComp;
	ASummitEggBackpack Backpack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDoubleInteractionCapabilityParams& Params) const
	{
		if (IsValid(PlayerInteractionsComp.ActiveInteraction))
		{
			ASummitBackpackDoubleInteractionActor Interaction = Cast<ASummitBackpackDoubleInteractionActor>(PlayerInteractionsComp.ActiveInteraction.Owner);
			if (IsValid(Interaction) && !Interaction.State.PlayerState[Player].bHasEnterCompleted)
			{
				Params.InteractionActor = Interaction;
				Params.Component = PlayerInteractionsComp.ActiveInteraction;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float AnimationPositionAtEndOfFrame = ActiveDuration + Time::GetActorDeltaSeconds(Player);
		if (AnimationPositionAtEndOfFrame >= AnimationLength)
			return true;

		if (InteractionActor.State.PlayerState[Player].bHasCompletedInteraction || InteractionActor.State.Status == EDoubleInteractionStatus::LockedIn)
		{
			// Allow blending to completion early if configured
			if (AnimationPositionAtEndOfFrame > AnimationLength - Settings.EnterAnimationSettings.EarlyBlendIntoCompletionWindowDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDoubleInteractionCapabilityParams Params)
	{
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;
		InteractionActor = Cast<ASummitBackpackDoubleInteractionActor>(Params.InteractionActor);
		ActiveInteractionComponent = Params.Component;
		BackpackSettings = InteractionActor.PlayerBackpackSettings[Player];
		bTriggeredFinish = false;

		Settings = InteractionActor.GetDoubleInteractionSettingsForPlayer(Player, ActiveInteractionComponent);
		if (Settings.EnterAnimation != nullptr)
		{
			AnimationLength = Settings.EnterAnimation.PlayLength;
			Player.PlaySlotAnimation(
				Animation = Settings.EnterAnimation,
				BlendType = Settings.EnterAnimationSettings.BlendType,
				BlendTime = Settings.EnterAnimationSettings.BlendTime);

			Backpack.PlaySlotAnimation(
				Animation = BackpackSettings.EnterAnimation,
				BlendType = BackpackSettings.EnterAnimationSettings.BlendType,
				BlendTime = BackpackSettings.EnterAnimationSettings.BlendTime);
		}
		else
		{
			AnimationLength = 0;
			TriggerFinish();
		}

		// Play audio for enter
		if (Settings.EnterAudio != nullptr)
		{
			Player.PlayerAudioComponent.PostEvent(Settings.EnterAudio);
		}

		FDoubleInteractionEventParams EventParams;
		EventParams.Player = Player;
		EventParams.InteractionActor = InteractionActor;
		EventParams.InteractionComponent = ActiveInteractionComponent;
		UDoubleInteractionEffectEventHandler::Trigger_EnterBlendedIn(InteractionActor, EventParams);

		InteractionActor.OnEnterBlendedIn.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		InteractionActor.State.PlayerState[Player].bHasEnterStarted = true;
	}

	void TriggerFinish()
	{
		if (bTriggeredFinish)
			return;

		bTriggeredFinish = true;

		if (IsValid(InteractionActor))
		{
			InteractionActor.State.PlayerState[Player].bHasEnterCompleted = true;

			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_EnterBlendingOut(InteractionActor, EventParams);

			InteractionActor.OnEnterBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TriggerFinish();
		Player.StopSlotAnimationByAsset(Settings.EnterAnimation);
	}
}

class USummitBackpackDoubleInteractionMHAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 6;

	ASummitBackpackDoubleInteractionActor InteractionActor;
	UInteractionComponent ActiveInteractionComponent;
	USummitEggBackpackComponent BackpackComp;
	ASummitEggBackpack Backpack;
	FDoubleInteractionSettings Settings;

	UPlayerInteractionsComponent PlayerInteractionsComp;

	float TimeUntilNextGesture = 0;
	UAnimSequence PreviousGesture;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDoubleInteractionCapabilityParams& Params) const
	{
		if (IsValid(PlayerInteractionsComp.ActiveInteraction))
		{
			ASummitBackpackDoubleInteractionActor Interaction = Cast<ASummitBackpackDoubleInteractionActor>(PlayerInteractionsComp.ActiveInteraction.Owner);
			if (IsValid(Interaction) && Interaction.State.PlayerState[Player].bHasEnterCompleted && !Interaction.State.PlayerState[Player].bHasMHStarted)
			{
				Params.InteractionActor = Interaction;
				Params.Component = PlayerInteractionsComp.ActiveInteraction;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(InteractionActor))
			return true;
		if (InteractionActor.State.PlayerState[Player].bHasCanceled)
			return true;
		if (InteractionActor.State.PlayerState[Player].bHasCompletedInteraction)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDoubleInteractionCapabilityParams Params)
	{
		InteractionActor = Cast<ASummitBackpackDoubleInteractionActor>(Params.InteractionActor);
		ActiveInteractionComponent = Params.Component;
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;

		if (IsValid(InteractionActor))
		{
			Settings = InteractionActor.GetDoubleInteractionSettingsForPlayer(Player, ActiveInteractionComponent);
			if (Settings.MHAnimation != nullptr)
			{
				Player.PlaySlotAnimation(
					Animation = Settings.MHAnimation,
					BlendType = Settings.MHAnimationSettings.BlendType,
					BlendTime = Settings.MHAnimationSettings.BlendTime,
					bLoop = true);

				Backpack.PlaySlotAnimation(
					Animation = InteractionActor.PlayerBackpackSettings[Player].MHAnimation,
					BlendType = InteractionActor.PlayerBackpackSettings[Player].MHAnimationSettings.BlendType,
					BlendTime = InteractionActor.PlayerBackpackSettings[Player].MHAnimationSettings.BlendTime,
					bLoop = true);
			}

			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_MHBlendedIn(InteractionActor, EventParams);

			InteractionActor.OnMHBlendedIn.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
			InteractionActor.State.PlayerState[Player].bHasMHStarted = true;
		}

		TimeUntilNextGesture = Math::RandRange(Settings.Gestures.MinTimeBetweenGestures, Settings.Gestures.MaxTimeBetweenGestures);
		PreviousGesture = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!IsValid(InteractionActor))
			return;

		TimeUntilNextGesture -= DeltaTime;
		if (TimeUntilNextGesture <= 0)
		{
			TimeUntilNextGesture += Math::RandRange(Settings.Gestures.MinTimeBetweenGestures, Settings.Gestures.MaxTimeBetweenGestures);

			UAnimSequence PlayGesture;
			float BlendTime;

			const bool bOtherPlayerIsRight = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).DotProduct(Player.ActorRightVector) > 0;
			if (bOtherPlayerIsRight)
			{
				if (Settings.Gestures.GesturesRightDirection.Sequences.Num() != 0)
				{
					PlayGesture = Settings.Gestures.GesturesRightDirection.ChooseNextSequenceBasedOnCurrentSequence(PreviousGesture);
					BlendTime = Settings.Gestures.GesturesRightDirection.BlendTimeBetweenSequences;
				}
				else
				{
					PlayGesture = Settings.Gestures.GesturesGeneric.ChooseNextSequenceBasedOnCurrentSequence(PreviousGesture);
					BlendTime = Settings.Gestures.GesturesGeneric.BlendTimeBetweenSequences;
				}
			}
			else
			{
				if (Settings.Gestures.GesturesLeftDirection.Sequences.Num() != 0)
				{
					PlayGesture = Settings.Gestures.GesturesLeftDirection.ChooseNextSequenceBasedOnCurrentSequence(PreviousGesture);
					BlendTime = Settings.Gestures.GesturesLeftDirection.BlendTimeBetweenSequences;
				}
				else
				{
					PlayGesture = Settings.Gestures.GesturesGeneric.ChooseNextSequenceBasedOnCurrentSequence(PreviousGesture);
					BlendTime = Settings.Gestures.GesturesGeneric.BlendTimeBetweenSequences;
				}
			}

			if (PlayGesture != nullptr)
			{
				PreviousGesture = PlayGesture;
				TimeUntilNextGesture += PlayGesture.PlayLength;

				Player.PlaySlotAnimation(
					Animation = PlayGesture,
					BlendTime = BlendTime,
					OnBlendingOut = FHazeAnimationDelegate(this, n"OnGestureBlendingOut"));

			}
		}
	}

	UFUNCTION()
	private void OnGestureBlendingOut()
	{
		if (IsActive())
		{
			Player.PlaySlotAnimation(
				Animation = Settings.MHAnimation,
				BlendType = Settings.MHAnimationSettings.BlendType,
				BlendTime = Settings.MHAnimationSettings.BlendTime,
				bLoop = true, );
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(InteractionActor))
		{
			if (!InteractionActor.State.PlayerState[Player].bHasMHCompleted)
			{
				FDoubleInteractionEventParams EventParams;
				EventParams.Player = Player;
				EventParams.InteractionActor = InteractionActor;
				EventParams.InteractionComponent = ActiveInteractionComponent;
				UDoubleInteractionEffectEventHandler::Trigger_MHBlendingOut(InteractionActor, EventParams);

				InteractionActor.OnMHBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
				InteractionActor.State.PlayerState[Player].bHasMHCompleted = true;
			}
		}

		Player.StopSlotAnimationByAsset(PreviousGesture);
		Player.StopSlotAnimationByAsset(Settings.MHAnimation);
		Backpack.StopSlotAnimationByAsset(InteractionActor.PlayerBackpackSettings[Player].MHAnimation);
	}
}

class USummitBackpackDoubleInteractionCancelAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 7;

	ASummitBackpackDoubleInteractionActor InteractionActor;
	UInteractionComponent ActiveInteractionComponent;
	USummitEggBackpackComponent BackpackComp;
	ASummitEggBackpack Backpack;
	FDoubleInteractionSettings Settings;

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UPlayerMovementComponent MoveComp;

	float AnimationLength;
	float MovementCancelWindow;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDoubleInteractionCapabilityParams& Params) const
	{
		if (IsValid(PlayerInteractionsComp.ActiveInteraction))
		{
			ASummitBackpackDoubleInteractionActor Interaction = Cast<ASummitBackpackDoubleInteractionActor>(PlayerInteractionsComp.ActiveInteraction.Owner);
			if (IsValid(Interaction) && Interaction.State.PlayerState[Player].bHasMHStarted && Interaction.State.PlayerState[Player].bHasCanceled)
			{
				Params.InteractionActor = Interaction;
				Params.Component = PlayerInteractionsComp.ActiveInteraction;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(InteractionActor))
			return true;

		float AnimationPositionAtEndOfFrame = ActiveDuration + Time::GetActorDeltaSeconds(Player);
		if (AnimationPositionAtEndOfFrame >= AnimationLength)
			return true;

		// Allow canceling the animation early with movement input
		if (AnimationPositionAtEndOfFrame > AnimationLength - MovementCancelWindow)
		{
			if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).Size() > 0.1)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDoubleInteractionCapabilityParams Params)
	{
		InteractionActor = Cast<ASummitBackpackDoubleInteractionActor>(Params.InteractionActor);
		ActiveInteractionComponent = Params.Component;
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;
		if (IsValid(InteractionActor))
		{
			if (!InteractionActor.State.PlayerState[Player].bHasMHCompleted)
			{
				FDoubleInteractionEventParams EventParams;
				EventParams.Player = Player;
				EventParams.InteractionActor = InteractionActor;
				EventParams.InteractionComponent = ActiveInteractionComponent;
				UDoubleInteractionEffectEventHandler::Trigger_MHBlendingOut(InteractionActor, EventParams);

				InteractionActor.OnMHBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
				InteractionActor.State.PlayerState[Player].bHasMHCompleted = true;
			}

			Settings = InteractionActor.GetDoubleInteractionSettingsForPlayer(Player, ActiveInteractionComponent);
			if (Settings.CancelAnimation != nullptr)
			{
				AnimationLength = Settings.CancelAnimation.PlayLength;
				MovementCancelWindow = Settings.CancelAnimationSettings.MovementCancelWindowDuration;
				Player.PlaySlotAnimation(
					Animation = Settings.CancelAnimation,
					BlendType = Settings.CancelAnimationSettings.BlendType,
					BlendTime = Settings.CancelAnimationSettings.BlendTime, );

				Backpack.PlaySlotAnimation(
					Animation = InteractionActor.PlayerBackpackSettings[Player].CancelAnimation,
					BlendType = InteractionActor.PlayerBackpackSettings[Player].CancelAnimationSettings.BlendType,
					BlendTime = InteractionActor.PlayerBackpackSettings[Player].CancelAnimationSettings.BlendTime);
			}
			else
			{
				AnimationLength = 0;
				PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteractionComponent);
			}

			// Play audio for cancel
			if (Settings.CancelAudio != nullptr)
			{
				Player.PlayerAudioComponent.PostEvent(Settings.CancelAudio);
			}

			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_CancelBlendedIn(InteractionActor, EventParams);

			InteractionActor.OnCancelBlendingIn.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(InteractionActor))
		{
			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_CancelBlendingOut(InteractionActor, EventParams);

			InteractionActor.OnCancelBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		}

		Player.StopSlotAnimationByAsset(Settings.CancelAnimation);
		PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteractionComponent);
		Backpack.StopSlotAnimationByAsset(InteractionActor.PlayerBackpackSettings[Player].CancelAnimation);
	}
}

class USummitBackpackDoubleInteractionCompletedAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 8;

	ASummitBackpackDoubleInteractionActor InteractionActor;
	UInteractionComponent ActiveInteractionComponent;
	USummitEggBackpackComponent BackpackComp;
	ASummitEggBackpack Backpack;
	FDoubleInteractionSettings Settings;

	UPlayerInteractionsComponent PlayerInteractionsComp;
	UPlayerMovementComponent MoveComp;

	float AnimationLength;
	float MovementCancelWindow;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerInteractionsComp = UPlayerInteractionsComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDoubleInteractionCapabilityParams& Params) const
	{
		if (IsValid(PlayerInteractionsComp.ActiveInteraction))
		{
			ASummitBackpackDoubleInteractionActor Interaction = Cast<ASummitBackpackDoubleInteractionActor>(PlayerInteractionsComp.ActiveInteraction.Owner);
			if (IsValid(Interaction) && Interaction.State.PlayerState[Player].bHasMHStarted && Interaction.State.PlayerState[Player].bHasCompletedInteraction)
			{
				Params.InteractionActor = Interaction;
				Params.Component = PlayerInteractionsComp.ActiveInteraction;
				return true;
			}
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsValid(InteractionActor))
			return true;

		float AnimationPositionAtEndOfFrame = ActiveDuration + Time::GetActorDeltaSeconds(Player);
		if (AnimationPositionAtEndOfFrame >= AnimationLength)
			return true;

		// Allow canceling the animation early with movement input
		if (AnimationPositionAtEndOfFrame > AnimationLength - MovementCancelWindow)
		{
			if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).Size() > 0.1)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDoubleInteractionCapabilityParams Params)
	{
		InteractionActor = Cast<ASummitBackpackDoubleInteractionActor>(Params.InteractionActor);
		ActiveInteractionComponent = Params.Component;
		BackpackComp = USummitEggBackpackComponent::Get(Player);
		Backpack = BackpackComp.Backpack;
		if (IsValid(InteractionActor))
		{
			if (!InteractionActor.State.PlayerState[Player].bHasMHCompleted)
			{
				FDoubleInteractionEventParams EventParams;
				EventParams.Player = Player;
				EventParams.InteractionActor = InteractionActor;
				EventParams.InteractionComponent = ActiveInteractionComponent;
				UDoubleInteractionEffectEventHandler::Trigger_MHBlendingOut(InteractionActor, EventParams);

				InteractionActor.OnMHBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
				InteractionActor.State.PlayerState[Player].bHasMHCompleted = true;
			}

			Settings = InteractionActor.GetDoubleInteractionSettingsForPlayer(Player, ActiveInteractionComponent);
			if (Settings.CompletedAnimation != nullptr)
			{
				AnimationLength = Settings.CompletedAnimation.PlayLength;
				MovementCancelWindow = Settings.CompletedAnimationSettings.MovementCancelWindowDuration;
				Player.PlaySlotAnimation(
					Animation = Settings.CompletedAnimation,
					BlendType = Settings.CompletedAnimationSettings.BlendType,
					BlendTime = Settings.CompletedAnimationSettings.BlendTime, );

				Backpack.PlaySlotAnimation(
					Animation = InteractionActor.PlayerBackpackSettings[Player].CompletedAnimation,
					BlendType = InteractionActor.PlayerBackpackSettings[Player].CompletedAnimationSettings.BlendType,
					BlendTime = InteractionActor.PlayerBackpackSettings[Player].CompletedAnimationSettings.BlendTime);
			}
			else
			{
				AnimationLength = 0;
				PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteractionComponent);
			}

			// Play audio for completed
			if (Settings.CompletedAudio != nullptr)
			{
				Player.PlayerAudioComponent.PostEvent(Settings.CompletedAudio);
			}

			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_CompletedBlendedIn(InteractionActor, EventParams);

			InteractionActor.OnCompletedBlendingIn.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(InteractionActor))
		{
			FDoubleInteractionEventParams EventParams;
			EventParams.Player = Player;
			EventParams.InteractionActor = InteractionActor;
			EventParams.InteractionComponent = ActiveInteractionComponent;
			UDoubleInteractionEffectEventHandler::Trigger_CompletedBlendingOut(InteractionActor, EventParams);

			InteractionActor.OnCompletedBlendingOut.Broadcast(Player, InteractionActor, ActiveInteractionComponent);
		}

		Player.StopSlotAnimationByAsset(Settings.CompletedAnimation);
		PlayerInteractionsComp.KickPlayerOutOfInteraction(ActiveInteractionComponent);
		Backpack.StopSlotAnimationByAsset(InteractionActor.PlayerBackpackSettings[Player].CompletedAnimation);
	}
}
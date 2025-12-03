class UGrappleFishRopeTensionerInteractionCapability : UInteractionCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 5;

	AGrappleFishRopeTensioner RopeTensioner;
	UDesertCrankInteractionComponent CrankInteractionComp;
	UDesertPlayerCrankComponent PlayerCrankComp;

	bool bRopeTensionerCompleted = false;
	bool bCompletedByThisPlayer = false;

	bool bIsAttached = false;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (!CheckInteraction.Owner.IsA(AGrappleFishRopeTensioner))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		RopeTensioner = Cast<AGrappleFishRopeTensioner>(Params.Interaction.Owner);
		CrankInteractionComp = Cast<UDesertCrankInteractionComponent>(Params.Interaction);
		PlayerCrankComp = UDesertPlayerCrankComponent::Get(Player);

		PlayerCrankComp.AddLocomotionFeature(this);

		// Try to acquire the completion lock
		RopeTensioner.CompletionLock.Acquire(Player, this);

		RopeTensioner.InteractingPlayers[Player] = true;

		// We take care of cancel ourselves so we can play the exit animation
		Player.BlockCapabilities(n"InteractionCancel", this);
		ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);

		RopeTensioner.OnCompleted.AddUFunction(this, n"HandleCompleted");
		RopeTensioner.OnStarted.AddUFunction(this, n"HandleStarted");
		RopeTensioner.InteractingPlayers[Player] = true;

		Timer::SetTimer(this, n"OnEnterBlendedIn", 0.5);
		bIsAttached = true;
		Player.RootComponent.AttachToComponent(ActiveInteraction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepRelative, false);
	}

	UFUNCTION()
	private void HandleStarted()
	{
		PlayerCrankComp.StartCranking();
	}

	UFUNCTION()
	void OnEnterBlendedIn()
	{
		if (!bIsAttached)
			return;

		if (Player.IsMio())
			RopeTensioner.LeftHandle.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::KeepWorld);
		else
			RopeTensioner.RightHandle.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::KeepWorld);
		RopeTensioner.WaitingPlayers[Player] = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(RopeTensioner))
		{
			RopeTensioner.InteractingPlayers[Player] = false;
			RopeTensioner.WaitingPlayers[Player] = false;
			// Reset state pushed by us
			RopeTensioner.CompletionLock.Release(Player, this);
			ActiveInteraction.SetPlayerIsAbleToCancel(Player, true);
		}

		if (bIsAttached)
		{
			bIsAttached = false;
			Player.DetachRootComponentFromParent();
		}

		Player.UnblockCapabilities(n"InteractionCancel", this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Super::OnDeactivated();

		PlayerCrankComp.RemoveLocomotionFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PlayerCrankComp.RequestLocomotion(CrankInteractionComp.bIsRightSideCrank, this);
		if (Player.HasControl() && RopeTensioner.CompletionLock.IsAcquired(Player) && !bCompletedByThisPlayer)
		{
			if (RopeTensioner.WaitingPlayers[Player] && RopeTensioner.WaitingPlayers[Player.OtherPlayer])
			{
				CrumbLockInDoubleInteract();
			}
			else if (!bCompletedByThisPlayer)
			{
				ActiveInteraction.SetPlayerIsAbleToCancel(Player, true);
				if (ActiveInteraction.CanPlayerCancel(Player))
				{
					if (WasActionStarted(ActionNames::Cancel))
					{
						HandleLeaveInteraction();
					}
				}
			}
			else
			{
				ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLockInDoubleInteract()
	{
		bCompletedByThisPlayer = true;
		ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);
		RopeTensioner.Start();
	}

	UFUNCTION()
	private void HandleCompleted()
	{
		PlayerCrankComp.StopCranking();
		Timer::SetTimer(this, n"HandleLeaveInteraction", 1.0);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDetachHandle()
	{
		if (Player.IsMio())
			RopeTensioner.LeftHandle.AttachToComponent(RopeTensioner.OffsetComp, NAME_None, EAttachmentRule::KeepWorld);
		else
			RopeTensioner.RightHandle.AttachToComponent(RopeTensioner.OffsetComp, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void HandleLeaveInteraction()
	{
		Timer::ClearTimer(this, n"OnEnterBlendedIn");
		if (HasControl())
			CrumbDetachHandle();
		bRopeTensionerCompleted = true;
		LeaveInteraction();
	}
};
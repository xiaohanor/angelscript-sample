class UDesertTrapGateCrankInteractionCapability : UInteractionCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 29;
	default TickGroupSubPlacement = 5;

	ADesertTrapGateCrank Crank;

	bool bCompleted = false;
	bool bCompletedByThisPlayer = false;

	bool bIsAttached = false;

	UDesertPlayerCrankComponent PlayerCrankComp;

	UDesertCrankInteractionComponent CrankInteractionComp;

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (!CheckInteraction.Owner.IsA(ADesertTrapGateCrank))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		Crank = Cast<ADesertTrapGateCrank>(Params.Interaction.Owner);
		CrankInteractionComp = Cast<UDesertCrankInteractionComponent>(Params.Interaction);
		PlayerCrankComp = UDesertPlayerCrankComponent::Get(Player);
		// Try to acquire the completion lock
		Crank.CompletionLock.Acquire(Player, this);

		Crank.InteractingPlayers[Player] = true;

		// We take care of cancel ourselves so we can play the exit animation
		Player.BlockCapabilities(n"InteractionCancel", this);
		ActiveInteraction.SetPlayerIsAbleToCancel(Player, false);

		Crank.OnCompleted.AddUFunction(this, n"HandleCompleted");
		Crank.OnStarted.AddUFunction(this, n"HandleStarted");
		Crank.InteractingPlayers[Player] = true;

		Timer::SetTimer(this, n"OnEnterBlendedIn", 0.5);
		PlayerCrankComp.AddLocomotionFeature(Crank);
		bIsAttached = true;
		Player.RootComponent.AttachToComponent(ActiveInteraction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepRelative, false);
		bCompletedByThisPlayer = false;
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
			Crank.LeftHandleMesh.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::KeepWorld);
		else
			Crank.RightHandleMesh.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::KeepWorld);
		Crank.WaitingPlayers[Player] = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (IsValid(Crank))
		{
			Crank.InteractingPlayers[Player] = false;
			Crank.WaitingPlayers[Player] = false;
			// Reset state pushed by us
			Crank.CompletionLock.Release(Player, this);
			ActiveInteraction.SetPlayerIsAbleToCancel(Player, true);
		}

		PlayerCrankComp.RemoveLocomotionFeature(Crank);

		if (bIsAttached)
		{
			bIsAttached = false;
			Player.DetachRootComponentFromParent();
		}

		Player.UnblockCapabilities(n"InteractionCancel", this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PlayerCrankComp.RequestLocomotion(CrankInteractionComp.bIsRightSideCrank, this);
		if (Player.HasControl() && Crank.CompletionLock.IsAcquired(Player) && !bCompletedByThisPlayer)
		{
			if (Crank.WaitingPlayers[Player] && Crank.WaitingPlayers[Player.OtherPlayer])
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
		Crank.Start();
	}

	UFUNCTION()
	private void HandleCompleted()
	{
		bCompleted = true;
		PlayerCrankComp.StopCranking();
		Timer::SetTimer(this, n"HandleLeaveInteraction", 1.0);
		// LeaveInteraction();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDetachHandle()
	{
		if (Player.IsMio())
			Crank.LeftHandleMesh.AttachToComponent(Crank.OffsetComp, NAME_None, EAttachmentRule::KeepWorld);
		else
			Crank.RightHandleMesh.AttachToComponent(Crank.OffsetComp, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void HandleLeaveInteraction()
	{
		Timer::ClearTimer(this, n"OnEnterBlendedIn");
		if (HasControl())
			CrumbDetachHandle();
		
		LeaveInteraction();
	}
};
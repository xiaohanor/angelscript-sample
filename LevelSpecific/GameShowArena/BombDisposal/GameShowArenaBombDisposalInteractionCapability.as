UCLASS()
class UGameShowArenaBombDisposalInteractionCapability : UInteractionCapability
{
	AGameShowArenaBombDisposal DisposalActor;
	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;

	FHazeAnimationDelegate PlayerEnterInteractionBlendedOut;

	TSet<AGameShowArenaBomb> TrackedNonExplodedBombs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	// Determines whether this interaction capability is intended for the given interaction
	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		auto Disposal = Cast<AGameShowArenaBombDisposal>(CheckInteraction.Owner);

		if (Disposal == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		BombTossPlayerComponent.HandleInteractionStart();

		// `ActiveInteraction` is available here as the interaction component the player is using
		DisposalActor = Cast<AGameShowArenaBombDisposal>(ActiveInteraction.Owner);

		if (HasControl())
		{
			CrumbHandleEnterInteraction(BombTossPlayerComponent.bHoldingBomb);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleEnterInteraction(bool bWasHoldingBomb)
	{
		DisposalActor.InteractingPlayers[Player] = true;
		UAnimSequence EnterSequence;
		if (bWasHoldingBomb)
		{
			auto Bomb = BombTossPlayerComponent.CurrentBomb;
			if (Bomb.TimeUntilExplosion < 2 && !TrackedNonExplodedBombs.Contains(Bomb))
			{
				Bomb.OnBombStartExploding.AddUFunction(this, n"OnBombExploded");
				Bomb.TimeUntilExplosion = 2;
				TrackedNonExplodedBombs.Add(Bomb);
			}
			DisposalActor.BombHoldingPlayer = Player;
			EnterSequence = DisposalActor.CarrierEnter;
		}
		else
		{
			DisposalActor.LidHoldingPlayer = Player;
			DisposalActor.OpenLid();
			EnterSequence = DisposalActor.HolderEnter;
		}

		if (DisposalActor.InteractingPlayers[Player.OtherPlayer])
		{
			auto Bomb = DisposalActor.BombTossComps[DisposalActor.BombHoldingPlayer].CurrentBomb;
			ActiveInteraction.bPlayerCanCancelInteraction = false;

			//DisposalActor.AttachBombToPlayer(DisposalActor.BombHoldingPlayer);

			Bomb.ResetTimeToExplode();

			if (Player.IsMio())
				DisposalActor.ZoeInteractionComp.bPlayerCanCancelInteraction = false;
			else
				DisposalActor.MioInteractionComp.bPlayerCanCancelInteraction = false;
		}

		PlayerEnterInteractionBlendedOut.BindUFunction(this, n"OnPlayerEnterInteractionBlendedOut");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), PlayerEnterInteractionBlendedOut, EnterSequence);
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		TrackedNonExplodedBombs.Remove(Bomb);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (Player.IsMio())
			DisposalActor.MioInteractionComp.Disable(this);
		else
			DisposalActor.ZoeInteractionComp.Disable(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Timer::SetTimer(this, n"OnTimerInteractionEnded", 0.8);
		BombTossPlayerComponent.HandleInteractionEnd();
		if (DisposalActor.bSequenceCompleted)
			return;

		if (HasControl())
			CrumbHandleExitInteraction();
	}

	UFUNCTION()
	private void OnTimerInteractionEnded()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		if (Player.IsMio())
			DisposalActor.MioInteractionComp.Enable(this);
		else
			DisposalActor.ZoeInteractionComp.Enable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleExitInteraction()
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = false;

		if (DisposalActor.LidHoldingPlayer == Player)
		{
			if (DisposalActor.bLidIsRaised)
				DisposalActor.CloseLid();

			Params.Animation = DisposalActor.HolderExit;
			// DisposalActor.LidHoldingPlayer = nullptr;
		}
		else if (DisposalActor.BombHoldingPlayer == Player)
		{
			Params.Animation = DisposalActor.CarrierExit;

			// DisposalActor.HideBomb();

			DisposalActor.BombHoldingPlayer = nullptr;
			// BombTossPlayerComponent.CurrentBomb.RemoveActorDisable(this);
		}
		Player.PlaySlotAnimation(Params);
		DisposalActor.InteractingPlayers[Player] = false;
		DisposalActor.FinishedInteractingPlayers[Player] = false;
		PlayerEnterInteractionBlendedOut.Clear();
	}

	UFUNCTION()
	private void OnPlayerEnterInteractionBlendedOut()
	{
		if (!IsActive())
			return;

		DisposalActor.FinishedInteractingPlayers[Player] = true;
		if (DisposalActor.FinishedInteractingPlayers[Player.OtherPlayer])
		{
			DisposalActor.DisposeBomb();
			DisposalActor.BombTossComps[DisposalActor.BombHoldingPlayer].CurrentBomb.ApplyBlockExplosion(this, EInstigatePriority::Override);
		}
		else
		{
			FHazePlaySlotAnimationParams Params;
			if (DisposalActor.BombHoldingPlayer == Player)
				Params.Animation = DisposalActor.CarrierMH;
			else
				Params.Animation = DisposalActor.HolderMH;

			Params.bLoop = true;
			Player.PlaySlotAnimation(Params);
		}
	}
};
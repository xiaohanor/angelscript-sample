UCLASS()
class UGameShowArenaHatchInteractionCapability : UInteractionCapability
{
	AGameShowArenaAnnouncer Announcer;
	UGameShowArenaAnnouncerHatchComponent HatchComp;
	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;

	FHazeAnimationDelegate PlayerEnterInteractionBlendedOut;

	TSet<AGameShowArenaBomb> TrackedNonExplodedBombs;

	bool bCanCancel = true;
	bool bWasHoldingBomb = false;

	// TODO (DB): Stress test this even more in network, though it seems to be working

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	// Determines whether this interaction capability is intended for the given interaction
	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if (!CheckInteraction.Owner.IsA(AGameShowArenaAnnouncer))
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
		Announcer = Cast<AGameShowArenaAnnouncer>(ActiveInteraction.Owner);
		HatchComp = UGameShowArenaAnnouncerHatchComponent::Get(Announcer);
		HatchComp.OnBothPlayersReady.AddUFunction(this, n"OnBothReady");

		if (HasControl())
		{
			CrumbHandleEnterInteraction(BombTossPlayerComponent.bHoldingBomb);
		}
	}

	UFUNCTION()
	private void OnBothReady()
	{
		FHazeAnimationDelegate _;
		UAnimSequence Animation;
		if (Player == HatchComp.BombHoldingPlayer)
			Animation = HatchComp.BombAnimations[Player].CompletedAnimation;
		else
			Animation = HatchComp.HatchAnimations[Player].CompletedAnimation;
		Player.PlaySlotAnimation(_, _, Animation);
		bCanCancel = false;
		if (BombTossPlayerComponent.CurrentBomb != nullptr)
		{
			BombTossPlayerComponent.CurrentBomb.ApplyBlockExplosion(this, EInstigatePriority::Override);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleEnterInteraction(bool bInWasHoldingBomb)
	{
		bWasHoldingBomb = bInWasHoldingBomb;
		HatchComp.InteractingPlayers[Player] = true;
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
			HatchComp.BombHoldingPlayer = Player;
			EnterSequence = HatchComp.BombAnimations[Player].EnterAnimation;
		}
		else
		{
			HatchComp.HatchHoldingPlayer = Player;
			EnterSequence = HatchComp.HatchAnimations[Player].EnterAnimation;
		}

		if (Player.IsMio())
			Announcer.MioInteractionComp.bPlayerCanCancelInteraction = false;
		else
			Announcer.ZoeInteractionComp.bPlayerCanCancelInteraction = false;

		if (HatchComp.InteractingPlayers[Player.OtherPlayer])
		{
			ActiveInteraction.bPlayerCanCancelInteraction = false;
			Announcer.MioInteractionComp.bPlayerCanCancelInteraction = false;
			Announcer.ZoeInteractionComp.bPlayerCanCancelInteraction = false;

			if (HatchComp.BombHoldingPlayer != nullptr)
			{
				auto Bomb = HatchComp.BombTossComps[HatchComp.BombHoldingPlayer].CurrentBomb;
				if (Bomb != nullptr)
				{
					Bomb.ResetTimeToExplode();
					Bomb.ApplyBlockExplosion(this, EInstigatePriority::Override);
				}
			}
		}

		PlayerEnterInteractionBlendedOut.BindUFunction(this, n"OnPlayerEnterInteractionBlendedOut");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), PlayerEnterInteractionBlendedOut, EnterSequence);
	}

	// Attaching is called from animation
	UFUNCTION()
	void DetachHatchFromPlayer()
	{
		if (bCanCancel)
		{
			Announcer.HatchMeshComp.AttachToComponent(Announcer.SkeletalMeshComp, n"HatchSocket", EAttachmentRule::SnapToTarget);
			Announcer.HatchMeshComp.RelativeRotation = Announcer.HatchRelativeRotation;
		}
		else
			Announcer.HatchMeshComp.AttachToComponent(Announcer.SkeletalMeshComp, n"HatchSocket", EAttachmentRule::KeepWorld);
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
			Announcer.MioInteractionComp.Disable(this);
		else
			Announcer.ZoeInteractionComp.Disable(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		if (UGameShowArenaHatchPlayerComponent::Get(Game::Mio).bFinalSequenceCompleted)
			return;

		Timer::SetTimer(this, n"OnTimerInteractionEnded", 0.4);
		BombTossPlayerComponent.HandleInteractionEnd();
		HatchComp.OnBothPlayersReady.Unbind(this, n"OnBothReady");

		if (HasControl())
			CrumbHandleExitInteraction();
	}

	UFUNCTION()
	private void OnTimerInteractionEnded()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		if (Player.IsMio())
			Announcer.MioInteractionComp.Enable(this);
		else
			Announcer.ZoeInteractionComp.Enable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleExitInteraction()
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = false;

		if (!bWasHoldingBomb)
		{
			Params.Animation = HatchComp.HatchAnimations[Player].CancelAnimation;
		}
		else
		{
			Params.Animation = HatchComp.BombAnimations[Player].CancelAnimation;
			HatchComp.BombHoldingPlayer = nullptr;
		}

		if (!Player.IsPlayerDeadOrRespawning())
		{
			if (Params.Animation != nullptr)
			{
				Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnExitBlendedOut"), Params);
			}
			else
				Player.StopAllSlotAnimations();
		}
		else
		{
			if (HasControl())
				CrumbDetachHatch();
		}

		HatchComp.InteractingPlayers[Player] = false;
		if (HasControl())
			HatchComp.NetSetPlayerNotReady(Player);

		PlayerEnterInteractionBlendedOut.Clear();
	}

	UFUNCTION()
	private void OnExitBlendedOut()
	{
		DetachHatchFromPlayer();
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbDetachHatch()
	{
		DetachHatchFromPlayer();
	}

	UFUNCTION()
	private void OnPlayerEnterInteractionBlendedOut()
	{
		if (!IsActive())
			return;

		if (HasControl())
			HatchComp.NetSetPlayerReady(Player);

		if (!HatchComp.InteractingPlayers[Player.OtherPlayer])
		{
			if (Player.IsMio())
				Announcer.MioInteractionComp.bPlayerCanCancelInteraction = true;
			else
				Announcer.ZoeInteractionComp.bPlayerCanCancelInteraction = true;
		}
		else
		{
			Announcer.MioInteractionComp.bPlayerCanCancelInteraction = false;
			Announcer.ZoeInteractionComp.bPlayerCanCancelInteraction = false;
		}

		if (HatchComp.PlayersEntered[Player.OtherPlayer])
		{
			// DisposalActor.DisposeBomb();
			// DisposalActor.BombTossComps[DisposalActor.BombHoldingPlayer].CurrentBomb.ApplyBlockExplosion(this, EInstigatePriority::Override);
		}
		else
		{
			FHazePlaySlotAnimationParams Params;
			if (HatchComp.BombHoldingPlayer == Player)
				Params.Animation = HatchComp.BombAnimations[Player].MHAnimation;
			else
				Params.Animation = HatchComp.HatchAnimations[Player].MHAnimation;

			Params.bLoop = true;
			Player.PlaySlotAnimation(Params);
		}
	}
};
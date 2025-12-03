
event void FGameShowArenaHatchOnBothPlayersReady();
UCLASS()
class UGameShowArenaAnnouncerHatchComponent : UActorComponent
{
	AGameShowArenaAnnouncer Announcer;

	UPROPERTY()
	TPerPlayer<FDoubleInteractionSettings> BombAnimations;

	UPROPERTY()
	TPerPlayer<FDoubleInteractionSettings> HatchAnimations;

	TPerPlayer<UGameShowArenaBombTossPlayerComponent> BombTossComps;
	TPerPlayer<bool> InteractingPlayers;
	TPerPlayer<bool> PlayersEntered;

	UPROPERTY()
	FGameShowArenaHatchOnBothPlayersReady OnBothPlayersReady;

	AHazePlayerCharacter HatchHoldingPlayer;
	AHazePlayerCharacter BombHoldingPlayer;

	UGameShowArenaHatchPlayerComponent MioHatchComp;
	UGameShowArenaHatchPlayerComponent ZoeHatchComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);

		if (!Announcer.bIsEndingAnnouncer)
		{
			Announcer.MioInteractionComp.Disable(this);
			Announcer.ZoeInteractionComp.Disable(this);
			return;
		}

		Announcer.MioInteractionComp.AddInteractionCondition(this, FInteractionCondition(this, n"InteractionCondition"));
		Announcer.ZoeInteractionComp.AddInteractionCondition(this, FInteractionCondition(this, n"InteractionCondition"));

		Announcer.MioInteractionComp.OnInteractionStarted.AddUFunction(this, n"TriggerStartInteraction");
		Announcer.ZoeInteractionComp.OnInteractionStarted.AddUFunction(this, n"TriggerStartInteraction");

		Announcer.MioInteractionComp.OnInteractionStopped.AddUFunction(this, n"TriggerStopInteraction");
		Announcer.ZoeInteractionComp.OnInteractionStopped.AddUFunction(this, n"TriggerStopInteraction");

		MioHatchComp = UGameShowArenaHatchPlayerComponent::GetOrCreate(Game::Mio);
		ZoeHatchComp = UGameShowArenaHatchPlayerComponent::GetOrCreate(Game::Zoe);

		MioHatchComp.EndingAnnouncer = Announcer;
		ZoeHatchComp.EndingAnnouncer = Announcer;
		
		MioHatchComp.OnBombDunk.AddUFunction(this, n"OnPlayerBombDunk");
		ZoeHatchComp.OnBombDunk.AddUFunction(this, n"OnPlayerBombDunk");
	}

	UFUNCTION()
	private EInteractionConditionResult InteractionCondition(
		const UInteractionComponent InteractionComponent,
		AHazePlayerCharacter Player)
	{
		if (BombTossComps[Player] == nullptr)
			BombTossComps[Player] = UGameShowArenaBombTossPlayerComponent::Get(Player);

		auto Bomb = GameShowArena::GetClosestEnabledBombToLocation(Player.ActorLocation);
		if (Bomb != nullptr && Bomb.State.Get() == EGameShowArenaBombState::Exploding)
			return EInteractionConditionResult::Disabled;

		if (!BombTossComps[Player].bHoldingBomb && HatchHoldingPlayer != nullptr)
			return EInteractionConditionResult::DisabledVisible;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void TriggerStartInteraction(UInteractionComponent InteractionComponent,
								 AHazePlayerCharacter Player)
	{
		if (BombTossComps[Player].bHoldingBomb)
		{
			BombHoldingPlayer = Player;
			FGameShowArenaHatchBombHolderParams Params;
			Params.PlayerHoldingBomb = Player;
			UGameShowArenaAnnouncerEffectHandler::Trigger_OnHatchBombPlayerReadyStart(Announcer, Params);
		}
		else
		{
			HatchHoldingPlayer = Player;
			FGameShowArenaHatchHolderParams Params;
			Params.PlayerHoldingHatch = Player;
			UGameShowArenaAnnouncerEffectHandler::Trigger_OnHatchOpenStart(Announcer, Params);
		}
	}

	UFUNCTION()
	private void TriggerStopInteraction(UInteractionComponent InteractionComponent,
								AHazePlayerCharacter Player)
	{
		if (BombHoldingPlayer == Player)
		{
			FGameShowArenaHatchBombHolderParams Params;
			Params.PlayerHoldingBomb = Player;
			UGameShowArenaAnnouncerEffectHandler::Trigger_OnHatchBombPlayerReadyStopped(Announcer, Params);
		}
		else
		{
			FGameShowArenaHatchHolderParams Params;
			Params.PlayerHoldingHatch = Player;
			UGameShowArenaAnnouncerEffectHandler::Trigger_OnHatchCloseStart(Announcer, Params);
		}
	}

	UFUNCTION()
	private void OnPlayerBombDunk(AHazePlayerCharacter Player)
	{
		auto Bomb = UGameShowArenaBombTossPlayerComponent::Get(Player).CurrentBomb;
		FGameShowArenaHatchBothPlayerParams Params;
		Params.PlayerHoldingBomb = Player;
		Params.PlayerHoldingHatch = Player.OtherPlayer;
		auto BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		BombTossPlayerComponent.RemoveBomb();

		Bomb.ApplyState(EGameShowArenaBombState::Disposed, this, EInstigatePriority::Override);
		Bomb.AddActorDisable(this);

		Announcer.HandleBombDunkedInHead();
	}

	UFUNCTION(NetFunction)
	void NetSetPlayerReady(AHazePlayerCharacter Player)
	{
		PlayersEntered[Player] = true;
		if (PlayersEntered[Game::Mio] && PlayersEntered[Game::Zoe])
		{
			OnBothPlayersReady.Broadcast();
			FGameShowArenaHatchBothPlayerParams Params;
			Params.PlayerHoldingBomb = BombHoldingPlayer;
			Params.PlayerHoldingHatch = HatchHoldingPlayer;
			UGameShowArenaAnnouncerEffectHandler::Trigger_OnBombDisposalStarted(Announcer, Params);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetPlayerNotReady(AHazePlayerCharacter Player)
	{
		PlayersEntered[Player] = false;
		if (Player == HatchHoldingPlayer)
			HatchHoldingPlayer = nullptr;
		else
			BombHoldingPlayer = nullptr;
	}
};
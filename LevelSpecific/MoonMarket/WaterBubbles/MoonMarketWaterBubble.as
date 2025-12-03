struct FMoonMarketWaterBubbleData
{
	UPROPERTY()
	float LifeTime = 20.0;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 45.0;
}

class AMoonMarketWaterBubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 7000;

	UPROPERTY()
	UNiagaraSystem WaterExplodeSystem;

	UPROPERTY(DefaultComponent)
	UMoonMarketBubbleAutoAimTargetComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketBobbingComponent BobbingComp;
	default BobbingComp.BobAmount = 40.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;
	default ListComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditAnywhere)
	bool bUseScaling = true;

	UPROPERTY(EditAnywhere)
	FMoonMarketWaterBubbleData Data;

	TPerPlayer<UMoonMarketPlayerBubbleComponent> PlayersInBubble;

	float ScaleInterp = 0.5;
	float CurrentScale = 0.;

	FVector StartingScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		OnDestroyed.AddUFunction(this, n"HandleDestroyed");

		Data.LifeTime += Time::GameTimeSeconds;

		StartingScale = ActorScale3D;

		if (bUseScaling)
			ActorScale3D = FVector(CurrentScale);

	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersInBubble[Player] = UMoonMarketPlayerBubbleComponent::GetOrCreate(Player);
		PlayersInBubble[Player].CurrentBubble = this;
		if(PlayersInBubble[Player].ShapeshiftComp.IsShapeshiftActive() && PlayersInBubble[Player].ShapeshiftComp.ShapeData.bIsBubbleBlockingShape)
		{
			PlayersInBubble[Player].ShapeshiftComp.ShapeshiftShape.StopInteraction(Player);
		}

		auto InteractComp = UMoonMarketPlayerInteractionComponent::Get(Player);
		for(int i = InteractComp.CurrentInteractions.Num() -1; i >= 0; i--)
		{
			if(Cast<AMoonMarketHoldableActor>(InteractComp.CurrentInteractions[i]) != nullptr)
				InteractComp.CurrentInteractions[i].StopInteraction(Player);
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersInBubble[Player].CurrentBubble = nullptr;
		PlayersInBubble[Player] = nullptr;

		FMoonMarketOnLeaveBubbleEventData EventData;
		EventData.Player = Player;
		EventData.LeaveLocation = Player.ActorLocation;
		EventData.LeaveVelocity = Player.ActorVelocity;

		UMoonMarketWaterBubbleEventHandler::Trigger_OnLeaveBubble(this, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bUseScaling)
		{
			CurrentScale = Math::FInterpConstantTo(CurrentScale, 1.0, DeltaSeconds, ScaleInterp);
			ActorScale3D = FVector(CurrentScale);
			if(Math::IsNearlyEqual(CurrentScale, 1))
				SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void HandleDestroyed(AActor DestroyedActor)
	{
		for(auto Player : Game::GetPlayers())
		{
			if(PlayersInBubble[Player] != nullptr)
			{
				Cast<AHazePlayerCharacter>(PlayersInBubble[Player].Owner).StopSlotAnimation();
				PlayersInBubble[Player].CurrentBubble = nullptr;
				PlayersInBubble[Player] = nullptr;
			}
		}
	}
};
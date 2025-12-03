class UMoonMarketMoleBalloonInteractionComponent : UInteractionComponent
{
	default bIsImmediateTrigger = true;
	default MovementSettings.Position = EMoveToPosition::RangeFromDestination;

	UMoonMarketMoleHoldBalloonComponent HoldBalloonComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HoldBalloonComp = UMoonMarketMoleHoldBalloonComponent::GetOrCreate(Owner);
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"CanInteract");
		AddInteractionCondition(this, Condition);
		OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		UMoonMarketHoldBalloonComp BalloonComp = UMoonMarketHoldBalloonComp::Get(Player);
		if(BalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return;

		if(HoldBalloonComp.Balloon != nullptr)
			return;

		if(Player.HasControl())
		{
			AMoonMarketFollowBalloon PlayerBalloon = BalloonComp.CurrentlyHeldBalloons[Math::RandRange(0, BalloonComp.CurrentlyHeldBalloons.Num() -1)];
			UMoonMarketPlayerInteractionComponent::Get(Player).CrumbStopInteraction(PlayerBalloon);
			HoldBalloonComp.CrumbSetBalloon(PlayerBalloon, Player);
		}
	}

	UFUNCTION()
	private EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player)
	{
		if(HoldBalloonComp.Balloon != nullptr)
			return EInteractionConditionResult::Disabled;

		if(UMoonMarketHoldBalloonComp::Get(Player).CurrentlyHeldBalloons.IsEmpty())
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

};
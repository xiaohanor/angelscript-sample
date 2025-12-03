class AMoonMarketGardenFatMushroom : AMushroomPeople
{
	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent Interaction;
	default Interaction.InteractionSheet = MoonMarketPushMushroomSheet;
	default Interaction.bShowCancelPrompt = true;
	default Interaction.bPlayerCanCancelInteraction = true;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UPROPERTY()
	FHazePlaySlotAnimationParams PushAnim;
	
	UPROPERTY(EditInstanceOnly)
	AMoonMarketCat Cat;

	bool bIsPushed = false;
	float TargetPitch = 20;
	float PushStiffness = 13;
	float PushDamping = 0.9;
	float ReturnStiffness = 50;
	float ReturnDamping = 0.5;

	FHazeAcceleratedFloat Pitch;

	bool bCatEnabled = false;
	bool bCatCaught;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		DisableCat();
		PolymorphAimComp.Disable(this);
		Interaction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		Interaction.OnExitBlendedIn.AddUFunction(this, n"OnInteractionStopped");
		Cat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");

		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsPushed = true;
		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = Player;
		UMoonMarketFatMushroomEventHandler::Trigger_OnStartBeingPushed(this, Params);
		EnableCat();

		auto InteractComp = UMoonMarketPlayerInteractionComponent::Get(Player);
		for(int i = InteractComp.CurrentInteractions.Num()-1; i >= 0; i--)
		{
			if(InteractComp.CurrentInteractions[i].InteractableTag == EMoonMarketInteractableTag::FlowerHat)
				continue;

			InteractComp.StopInteraction(InteractComp.CurrentInteractions[i]);
		}
	}


	UFUNCTION()
	private void OnInteractionStopped(AHazePlayerCharacter Player,
	                                  UThreeShotInteractionComponent _Interaction)
	{
		bIsPushed = false;
		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = Player;
		UMoonMarketFatMushroomEventHandler::Trigger_OnStopPushed(this, Params);
		UPolymorphResponseComponent::Get(Player).DesiredMorphClass = nullptr;

		DisableCat();
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat CurrentCat)
	{
		bCatCaught = true;
		Interaction.Disable(this);
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		Interaction.Disable(this);
	}

	void DisableCat()
	{
		Cat.InteractComp.Disable(this);
		bCatEnabled = false;
	}

	void EnableCat()
	{
		Cat.InteractComp.Enable(this);
		bCatEnabled = true;
	}

	void Bounce(AHazePlayerCharacter Player) override
	{
		Super::Bounce(Player);
		UMoonMarketFatMushroomEventHandler::Trigger_OnFatMushroomBouncedOn(this);
	}
};
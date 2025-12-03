event void FSummitEggHolderSignature();

class ASummitEggHolder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent EggPlacementLocation;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Both;
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.bIsImmediateTrigger = true;
	default InteractionComp.MovementSettings = FMoveToParams::SmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLockPlayerWhileInteracting = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bImmediatelyReset;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsDoubleInteract = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = bIsDoubleInteract, EditConditionHides))
	bool bDisableAfterDoubleInteractCompleted = true;

	UPROPERTY(EditInstanceOnly, Category = "Settings", Meta = (EditCondition = bIsDoubleInteract, EditConditionHides))
	ASummitEggHolder OtherEggHolder;

	UPROPERTY(BlueprintReadWrite, Category = "Audio")
	bool bHasAttachedSoundDef = false;

	UPROPERTY()
	FSummitEggHolderSignature OnEggPlaced;

	UPROPERTY()
	FSummitEggHolderSignature OnEggRemoved;

	UPROPERTY()
	FSummitEggHolderSignature OnEggReset;

	UPROPERTY()
	FSummitEggHolderSignature OnBothEggsPlaced;

	TPerPlayer<bool> IsHoldingEgg;
	TPerPlayer<bool> EggIsBeingPlaced;
	TPerPlayer<USummitEggBackpackComponent> BackpackComps;

	private bool bHasFoundBackpackComps = false;

	float ResetDelay = 6;

	UPROPERTY()
	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	bool bEggIsPlaced;

	UPROPERTY()
	bool bCompleted;

	UPROPERTY(EditAnywhere)
	bool bQuickCheckEgg;

	UPROPERTY(EditAnywhere)
	bool bFastAnimation = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazeDevToggleCategory Category = FHazeDevToggleCategory(n"Summit Eggpath");
		FName SubCategory = FName(ActorNameOrLabel);
		FHazeDevToggleBool EggPlaced = FHazeDevToggleBool(Category, SubCategory, n"EggPlaced", "");
		if (EggPlaced.IsEnabled())
			bEggIsPlaced = true;

		EggPlaced.BindOnChanged(this, n"OnToggleBoolChanged");
		EggPlaced.MakeVisible();
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
		OnEggPlaced.AddUFunction(this, n"HandleEggPlaced");
		OnEggRemoved.AddUFunction(this, n"HandleEggRemoved");

		if (bLockPlayerWhileInteracting)
			InteractionComp.bPlayerCanCancelInteraction = true;
	}

	UFUNCTION()
	private void OnToggleBoolChanged(bool bNewState)
	{
		if (bNewState)
			HandleEggPlaced();
		else
			HandleEggRemoved();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHasFoundBackpackComps)
		{
			for (auto Player : Game::Players)
			{
				auto BackpackComp = USummitEggBackpackComponent::Get(Player);
				if (BackpackComp == nullptr)
					return;

				BackpackComps[Player] = BackpackComp;
				InteractionComp.AddInteractionCondition(this, FInteractionCondition(this, n"CanInteractWithHolder"));
				bHasFoundBackpackComps = true;
				ActorTickEnabled = false;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private EInteractionConditionResult CanInteractWithHolder(
		const UInteractionComponent InteractionComponent,
		AHazePlayerCharacter Player)
	{
		if (IsHoldingEgg[Player] && bLockPlayerWhileInteracting)
			return EInteractionConditionResult::Disabled;
		// Other player is placing their egg here
		else if(EggIsBeingPlaced[Player.OtherPlayer])
			return EInteractionConditionResult::Disabled;
		// The players egg is placed here
		else if (IsHoldingEgg[Player])
			return EInteractionConditionResult::Enabled;
		// The other players egg is placed here
		else if (IsHoldingEgg[Player.OtherPlayer])
			return EInteractionConditionResult::Disabled;
		// No egg is placed here and the player is holding their egg
		else
			return EInteractionConditionResult::Enabled;
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		USummitEggBackpackComponent BackpackComp = USummitEggBackpackComponent::Get(Player);
		CurrentPlayer = Player;

		// InteractionComponent.Disable(this);

		if (BackpackComp.CurrentEggHolder.IsSet())
		{
			// Placing capability clears the holder, because it is delayed
			BackpackComp.bPickupRequested = true;
		}
		else
		{
			BackpackComp.CurrentEggHolder.Set(this);
			BackpackComp.bPlacementRequested = true;
			if (bQuickCheckEgg)
				bEggIsPlaced = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStopped(UInteractionComponent InteractionComponent,
							AHazePlayerCharacter Player)
	{
		USummitEggBackpackComponent BackpackComp = USummitEggBackpackComponent::Get(Player);
		BackpackComp.bPickupRequested = true;
		InteractionComponent.Enable(this);
	}

	UFUNCTION()
	void ForceInteraction(AHazePlayerCharacter Player)
	{
		USummitEggBackpackComponent BackpackComp = USummitEggBackpackComponent::Get(Player);
		if (BackpackComp.CurrentEggHolder.IsSet())
		{
			// Placing capability clears the holder, because it is delayed
			BackpackComp.bPickupRequested = true;
		}
		else
		{
			BackpackComp.CurrentEggHolder.Set(this);
			BackpackComp.bPlacementRequested = true;
			if (bQuickCheckEgg)
				bEggIsPlaced = true;
		}
	}

	UFUNCTION()
	void HandleEggPlaced()
	{
		if (!bQuickCheckEgg)
			bEggIsPlaced = true;

		if (HasControl() && bIsDoubleInteract)
		{
			if (OtherEggHolder != nullptr && OtherEggHolder.bEggIsPlaced)
			{
				NetNotifyBothEggsPlaced();
			}
		}

		BP_HandleEggPlaced();

		if (ForceFeedback != nullptr && CurrentPlayer != nullptr)
			CurrentPlayer.PlayForceFeedback(ForceFeedback, false, false, this);
	}

	UFUNCTION()
	void HandleEggRemoved()
	{
		bEggIsPlaced = false;
		BP_HandleEggRemoved();
	}

	UFUNCTION()
	void ResetEggHolder()
	{
		if (bCompleted)
			return;

		bEggIsPlaced = false;
		OnEggReset.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void PickUpEggForCurrentPlayer()
	{
		if (CurrentPlayer == nullptr)
			return;

		if (HasControl())
			CrumbPickupEgg(CurrentPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPickupEgg(AHazePlayerCharacter Player)
	{
		USummitEggBackpackComponent::Get(Player).bExternalPickupRequested = true;
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetNotifyBothEggsPlaced()
	{
		OnBothEggsPlaced.Broadcast();
		// Only runs once because it checks if the other one has been placed before running this function, so it gets discarded if the other one is not placed
		OtherEggHolder.OnBothEggsPlaced.Broadcast();
		if (bDisableAfterDoubleInteractCompleted)
		{
			bCompleted = true;
			OtherEggHolder.bCompleted = true;
			BP_DisableEggHolder();
			OtherEggHolder.BP_DisableEggHolder();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleEggPlaced()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_HandleEggRemoved()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_DisableEggHolder()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_EnableEggHolder()
	{}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bIsDoubleInteract)
		{
			if (OtherEggHolder != nullptr)
			{
				OtherEggHolder.OtherEggHolder = this;
				OtherEggHolder.bIsDoubleInteract = true;
			}
		}
		else
		{
			if (OtherEggHolder != nullptr)
			{
				OtherEggHolder.OtherEggHolder = nullptr;
				OtherEggHolder.bIsDoubleInteract = false;
				OtherEggHolder = nullptr;
			}
		}
	}
};
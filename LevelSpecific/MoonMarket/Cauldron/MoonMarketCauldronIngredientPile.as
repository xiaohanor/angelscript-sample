class AMoonMarketCauldronIngredientPile : AMoonMarketInteractableActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(2.0));
#endif

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMoonMarketCauldronIngredient> IngredientClass;

	int SpawnedIngredients = 0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"CanInteract");
		InteractComp.AddInteractionCondition(this, Condition);
	}

	EInteractionConditionResult CanInteract(const UInteractionComponent InteractionComponent,
	                                                AHazePlayerCharacter Player) override
	{
		auto PlayerComp = UMoonMarketWitchCauldronPlayerComponent::Get(Player);
		if(PlayerComp.HeldIngredient == nullptr)
			return EInteractionConditionResult::Enabled;

		if(PlayerComp.HeldIngredient.IngredientType == IngredientClass.DefaultObject.IngredientType)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		AMoonMarketCauldronIngredient Ingredient = SpawnActor(IngredientClass);
		Ingredient.MakeNetworked(this, SpawnedIngredients);
		SpawnedIngredients++;
		UMoonMarketWitchCauldronPlayerComponent::Get(Player).HeldIngredient = Ingredient;
		UMoonMarketPlayerInteractionComponent::Get(Player).PendingInteractions.Add(Ingredient);
		Ingredient.AttachToComponent(Player.Mesh, n"RightHand");
		Ingredient.SetActorRelativeLocation(Ingredient.RelativeOffset);
		Ingredient.SetActorRelativeRotation(Ingredient.RelativeRotation);
		Ingredient.IngredientPile = this;
		Enable();
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		InteractingPlayers.Remove(Player);
		InteractingPlayer = nullptr;
	}

	UFUNCTION()
	void Enable()
	{
		InteractComp.Enable(this);
	}
};
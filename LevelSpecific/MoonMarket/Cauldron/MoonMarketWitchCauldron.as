event void FMoonMarketBrewingFinishedEvent();

class AMoonMarketWitchCauldron : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoonMarketCauldronAnimationComponent CauldronAnimComp;

	UPROPERTY(DefaultComponent, Attach = CauldronAnimComp)
	UMoonMarketCauldronShakeComponent ShakeComp;

	UPROPERTY(DefaultComponent, Attach = ShakeComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UMoonMarketCauldronAnimationComponent LiquidDrainAnimationComp;

	UPROPERTY(DefaultComponent, Attach = LiquidDrainAnimationComp)
	UStaticMeshComponent LiquidSurface;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent SmokeMesh;

	UPROPERTY(EditAnywhere)
	const FLinearColor DefaultLiquidColor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PotionTable;

	UPROPERTY(DefaultComponent, Attach = PotionTable)
	USceneComponent PotionSpawnPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoonMarketDropIngredientInCauldronComponent IngredientDropComponent;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent IngredientSplashLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent CauldronSmoke;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;
	
	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	TArray<UMoonMarketCauldronRecipeDataAsset> Recipes;

	UPROPERTY()
	UNiagaraSystem PotionSpawnEffect;

	UPROPERTY()
	UNiagaraSystem IngredientAddedEffect;

	FMoonMarketBrewingFinishedEvent OnBrewingFinishedEvent;

	UPROPERTY(EditInstanceOnly)
	AMoonMarketPotion CurrentPotion;

	bool bIsBrewing = false;
	int PotionsSpawned = 0;
	float SmokeOpacity = 1;

	TArray<AMoonMarketCauldronIngredient> CurrentIngredients;
	
	FLinearColor CurrentLiquidColor;
	FLinearColor CurrentRippleColor;
	FLinearColor IngredientOneColor;
	FLinearColor IngredientTwoColor;
	FLinearColor TargetLiquidColor;
	FLinearColor TargetIngredientOneColor;
	FLinearColor TargetIngredientTwoColor;
	FHazeAcceleratedFloat EffectAlpha;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LiquidDrainAnimationComp.AnimationDone.AddUFunction(this, n"OnLiquidAnimDone");
		LiquidDrainAnimationComp.bUseAttachParentBound = true;
		LiquidSurface.bUseAttachParentBound = true;
		LiquidDrainAnimationComp.SetWorldRotation(FRotator::ZeroRotator);

		IngredientOneColor = DefaultLiquidColor;
		IngredientTwoColor = DefaultLiquidColor * 5;
		CurrentLiquidColor = DefaultLiquidColor;
		ResetColors();

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CheckCanInteract"));

		CurrentPotion.OnDrunk.AddUFunction(this, n"OnPotionDrunk");
	}

	UFUNCTION()
	private EInteractionConditionResult CheckCanInteract(
	                                                     const UInteractionComponent InteractionComponent,
	                                                     AHazePlayerCharacter Player)
	{
		auto PlayerComp = UMoonMarketWitchCauldronPlayerComponent::Get(Player);
		if(PlayerComp == nullptr)
			return EInteractionConditionResult::Disabled;

		if(!Player.IsOnWalkableGround())
			return EInteractionConditionResult::Disabled;

		if(PlayerComp.HeldIngredient == nullptr)
			return EInteractionConditionResult::Disabled;

		if(CurrentIngredients.Num() == 2)
			return EInteractionConditionResult::Disabled;

		if(CurrentPotion.bIsFilled)
			return EInteractionConditionResult::Disabled;
		
		if(IngredientDropComponent.CurrentIngredient != nullptr)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void OnPotionDrunk()
	{
		LiquidDrainAnimationComp.StartAnimationReverse();
		UMoonMarketWitchCauldronEventHandler::Trigger_OnStartRefilling(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"InUse");

		if(!Player.HasControl())
			return;

		auto PlayerComp = UMoonMarketWitchCauldronPlayerComponent::Get(Player);
		if (PlayerComp == nullptr)
		{
			CrumbDoneWithInteraction();
			return;
		}

		AMoonMarketCauldronIngredient Ingredient = PlayerComp.HeldIngredient;
		if(Ingredient == nullptr)
		{
			CrumbDoneWithInteraction();
			return;
		}

		PlayerComp.StartThrowingIngredientInCauldron(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDoneWithInteraction()
	{
		InteractComp.Enable(n"InUse");
	}

	UFUNCTION(NetFunction)
	void NetAddIngredient(AMoonMarketCauldronIngredient Ingredient)
	{
		AHazePlayerCharacter InteractingPlayer = Ingredient.InteractingPlayer;

		Ingredient.bUseSpawnEffect = false;
		IngredientDropComponent.StartDroppingIngredientIntoCauldron(Ingredient);
		CurrentIngredients.Add(Ingredient);
		Ingredient.StopInteraction(Ingredient.InteractingPlayer);

		if(CurrentIngredients.Num() == 2)
			InteractComp.Disable(this);

		if (InteractingPlayer.HasControl())
			CrumbDoneWithInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float InterpSpeed = 2;
		CurrentLiquidColor = Math::CInterpTo(CurrentLiquidColor, TargetLiquidColor, DeltaSeconds, InterpSpeed);
		CurrentRippleColor = Math::CInterpTo(CurrentRippleColor, TargetLiquidColor * 5, DeltaSeconds, InterpSpeed);

		LiquidSurface.SetColorParameterValueOnMaterials(n"LiquidColor", CurrentLiquidColor);
		LiquidSurface.SetColorParameterValueOnMaterials(n"RippleColor", CurrentRippleColor);

		SmokeMesh.SetColorParameterValueOnMaterials(n"EmissiveColor", CurrentLiquidColor * 0.5);

		if(bIsBrewing)
		{
			SmokeOpacity = Math::FInterpConstantTo(SmokeOpacity, 0, DeltaSeconds, 3);
		}
		else
		{
			SmokeOpacity = Math::FInterpConstantTo(SmokeOpacity, 1, DeltaSeconds, 1);
		}

		SmokeMesh.SetScalarParameterValueOnMaterials(n"Opacity", SmokeOpacity);

		EffectAlpha.AccelerateTo(bIsBrewing ? 0 : 1, 2, DeltaSeconds);
		CauldronSmoke.SetColorParameter(n"Color", CurrentLiquidColor);
		CauldronSmoke.SetFloatParameter(n"EffectAlpha", EffectAlpha.Value);

		IngredientOneColor = Math::CInterpTo(IngredientOneColor, TargetIngredientOneColor, DeltaSeconds, InterpSpeed);
		IngredientTwoColor = Math::CInterpTo(IngredientTwoColor, TargetIngredientTwoColor, DeltaSeconds, InterpSpeed);
		LiquidSurface.SetColorParameterValueOnMaterials(n"ColorA", IngredientOneColor);
		LiquidSurface.SetColorParameterValueOnMaterials(n"ColorB", IngredientTwoColor);
	}

	void OnIngredientDroppedInCauldron(AMoonMarketCauldronIngredient Ingredient)
	{
		UMoonMarketWitchCauldronEventHandler::Trigger_OnIngredientAdded(this);
		Ingredient.SetActorHiddenInGame(true);

		auto SplashEffect = Niagara::SpawnOneShotNiagaraSystemAtLocation(IngredientAddedEffect, IngredientSplashLocation.WorldLocation);
		SplashEffect.SetColorParameter(n"Color", CurrentLiquidColor);

		FShakeSettings IngredientAddedShake;
		IngredientAddedShake.ShakeAmountX = 2;
		IngredientAddedShake.ShakeAmountY = 2;
		IngredientAddedShake.ShakeSpeed = 50;

		ShakeComp.OverrideShakeSettings(IngredientAddedShake);

		if(CurrentIngredients.Num() == 2)
		{
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
			Timer::SetTimer(this, n"StartDrainAnim", 1);
			Timer::SetTimer(this, n"OnBrewingFinished", 2);
			CauldronAnimComp.StartAnimation();
			bIsBrewing = true;
			UMoonMarketWitchCauldronEventHandler::Trigger_OnBrewingStarted(this);
		}

		if(CurrentIngredients.Num() == 1)
		{
			TargetLiquidColor = Ingredient.IngredientColor;
			TargetIngredientOneColor = Ingredient.IngredientColor;
			TargetIngredientTwoColor = TargetIngredientOneColor;
		}
		else
		{
			TargetLiquidColor = (Ingredient.IngredientColor + TargetLiquidColor) / 2.0;
			TargetIngredientTwoColor = Ingredient.IngredientColor;
		}
	}

	UFUNCTION()
	private void StartDrainAnim()
	{
		LiquidDrainAnimationComp.StartAnimation();
	}

	UFUNCTION()
	void OnBrewingFinished()
	{
		Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
		FOnPotionBrewedParams Params;
		Params.PotionLocation = PotionSpawnPoint.WorldLocation;
		UMoonMarketWitchCauldronEventHandler::Trigger_OnBrewingFinished(this, Params);
		BrewPotion();
		OnBrewingFinishedEvent.Broadcast();
	}

	UFUNCTION()
	void OnLiquidAnimDone()
	{
		if(LiquidDrainAnimationComp.bReversed)
		{
			bIsBrewing = false;
		}
		else
		{
			ResetColors();
		}
	}

	void ResetColors()
	{
		TargetLiquidColor = DefaultLiquidColor;
		TargetIngredientOneColor = DefaultLiquidColor;
		TargetIngredientTwoColor = DefaultLiquidColor * 5;
	}

	void BrewPotion()
	{
		InteractComp.Enable(this);

		UMoonMarketCauldronRecipeDataAsset PotionResult = GetPotionResult();
		if(PotionResult != nullptr)
		{
			CurrentPotion.FillPotion(PotionResult.PotionID, TargetIngredientOneColor, TargetIngredientTwoColor, TargetLiquidColor, PotionResult.Sheet);
		}
		else
		{
			check(false, "Potion recipe not valid");
		}

		for(auto Ingredient : CurrentIngredients)
		{
			Ingredient.IngredientPile.Enable();
			Ingredient.DestroyActor();
		}

		CurrentIngredients.Empty();
	}

	UMoonMarketCauldronRecipeDataAsset GetPotionResult()
	{
		for(auto Recipe : Recipes)
		{
			bool bRecipeMatch = true;
			
			int IngredientUsed = -1;
			for(auto CurrentIngredient : CurrentIngredients)
			{
				bool bIngredientMatch = false;
				
				for(int i = 0; i < 2; i++)
				{
					if(i == IngredientUsed)
						continue;

					if(Recipe.Ingredients[i] == CurrentIngredient.IngredientType)
					{
						bIngredientMatch = true;
						IngredientUsed = i;
						break;
					}
				}

				if(!bIngredientMatch)
					bRecipeMatch = false;
			}

			if(bRecipeMatch)
				return Recipe;
		}

		return nullptr;
	}
};
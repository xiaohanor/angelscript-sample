event void FMoonMarketOnPotionDrunk();

class AMoonMarketPotion : AMoonMarketInteractableActor
{
	default bShowCancelPrompt = false;
	default bCancelByThunder = true;
	default InteractComp.bIsImmediateTrigger = false;
	FHazeShapeSettings FocusSettings;
	default FocusSettings.Type = EHazeShapeType::Sphere;
	default FocusSettings.SphereRadius = 1100.0;
	default InteractComp.FocusShape = FocusSettings;

	default InteractComp.bShowCancelPrompt = false;
	default InteractComp.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent Liquid;
	default Liquid.RelativeScale3D = FVector::OneVector * 0.95;
	default Liquid.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent Cork;
	default Cork.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere, Category = "Potion settings")
	UHazeCapabilitySheet SheetToStartWhenConsumed;

	UPROPERTY(EditAnywhere)
	bool bDestroyAfterConsumption = false;

	FMoonMarketOnPotionDrunk OnDrunk;

	float LiquidLevel = 0;
	float SpawnTime = 0;

	bool bIsFilled = false;
	EMoonMarketPotionID PotionID;

	FVector OriginalLocation;
	FRotator OriginalRotation;

	float LiquidTargetAmount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OriginalLocation = ActorLocation;
		OriginalRotation = ActorRotation;
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CheckInteractionAvailable"));
		Liquid.SetScalarParameterValueOnMaterials(n"LiquidFillPercent", 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LiquidLevel = Math::FInterpConstantTo(LiquidLevel, LiquidTargetAmount, DeltaSeconds, 0.5);
		Liquid.SetScalarParameterValueOnMaterials(n"LiquidFillPercent", LiquidLevel);
	}

	void FillPotion(EMoonMarketPotionID FillPotionID, FLinearColor IngredientColor1,  FLinearColor IngredientColor2, FLinearColor LiquidColor, UHazeCapabilitySheet Sheet)
	{
		UMoonMarketPotionEventHandler::Trigger_OnStartFilling(this);
		SheetToStartWhenConsumed = Sheet;
		Liquid.SetColorParameterValueOnMaterials(n"LiquidColor", LiquidColor);
		Liquid.SetColorParameterValueOnMaterials(n"IngredientOneColor", IngredientColor1);
		Liquid.SetColorParameterValueOnMaterials(n"IngredientTwoColor", IngredientColor2);
		LiquidTargetAmount = 1;
		bIsFilled = true;
		PotionID = FillPotionID;
		SpawnTime = Time::GameTimeSeconds;
	}

	void StartDrinkingPotion()
	{
		UMoonMarketPotionEventHandler::Trigger_OnBeingDrunk(this, FMoonMarketInteractingPlayerEventParams(InteractingPlayer));
		LiquidTargetAmount = 0;
		OnDrunk.Broadcast();
	}

	void EmptyPotion()
	{
		LiquidTargetAmount = 0;
		LiquidLevel = 0;
	}

	UFUNCTION()
	private EInteractionConditionResult CheckInteractionAvailable(
	                                                              const UInteractionComponent InteractionComponent,
	                                                              AHazePlayerCharacter Player)
	{
		if(!bIsFilled)
			return EInteractionConditionResult::Disabled;

		if(Time::GetGameTimeSince(SpawnTime) < 1.5)
			return EInteractionConditionResult::Disabled;

		if(!UHazeMovementComponent::Get(Player).HasGroundContact())
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		bIsFilled = false;
		UMoonMarketPotionEventHandler::Trigger_OnInteractionStarted(this, FMoonMarketInteractingPlayerEventParams(Player));

		// Mark the potion as having been drank, and unlock the achievement if all potions have been drank before
		bool bAllPotionsDrank = true;
		Profile::SetProfileValue(Online::PrimaryIdentity, FName(f"Potion.{int(PotionID)}"), "true");
		for (int i = 0; i < int(EMoonMarketPotionID::MAX); ++i)
		{
			FString StoredValue;
			bool bHadValue = Profile::GetProfileValue(Online::PrimaryIdentity, FName(f"Potion.{i}"), StoredValue);
			if (!bHadValue || StoredValue != "true")
			{
				bAllPotionsDrank = false;
				break;
			}
		}

		if (bAllPotionsDrank)
		{
			Online::UnlockAchievement(n"AllCauldronForms");
		}
	}
};
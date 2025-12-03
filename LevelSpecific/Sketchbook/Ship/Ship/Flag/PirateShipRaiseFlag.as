UCLASS(Abstract)
class APirateShipRaiseFlag : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent InteractionComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(EditInstanceOnly)
	AHazeActor FlagActor;

	EPirateShipFlagType RaisedFlag;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"InteractCondition");
		InteractionComp.AddInteractionCondition(this, Condition);

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		SetFlagMaterial(nullptr);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto FlagComp = UPirateShipFlagPlayerComponent::Get(Player);

		// We have a flag, it can always be removed
		if(RaisedFlag != EPirateShipFlagType::None)
			return EInteractionConditionResult::Enabled;

		// The player has a flag to put up
		if(FlagComp.CarriedFlag != EPirateShipFlagType::None)
			return EInteractionConditionResult::Enabled;

		return EInteractionConditionResult::DisabledVisible;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto FlagComp = UPirateShipFlagPlayerComponent::Get(Player);

		if(RaisedFlag != EPirateShipFlagType::None)
		{
			// We have a raised flag
			if(FlagComp.CarriedFlag != EPirateShipFlagType::None)
			{
				// And the player is carrying one
				// Swap flag
				EPirateShipFlagType Temp = RaisedFlag;
				RaisedFlag = FlagComp.CarriedFlag;
				FlagComp.CarriedFlag = Temp;

				SetFlagMaterial(FlagComp.FlagMaterials[RaisedFlag]);
			}
			else
			{
				// But the player has no flag
				// Lower flag
				FlagComp.CarriedFlag = RaisedFlag;
				RaisedFlag = EPirateShipFlagType::None;
				SetFlagMaterial(nullptr);
			}
		}
		else
		{
			// We don't have a raised flag
			if(FlagComp.CarriedFlag != EPirateShipFlagType::None)
			{
				// But the player is carrying one
				// Raise flag
				RaisedFlag = FlagComp.CarriedFlag;
				FlagComp.CarriedFlag = EPirateShipFlagType::None;

				SetFlagMaterial(FlagComp.FlagMaterials[RaisedFlag]);
			}
		}
	}

	private void SetFlagMaterial(UMaterialInterface Material)
	{
		auto ClothComp = UEnvironmentClothSimComponent::Get(FlagActor);
		if(Material == nullptr)
		{
			ClothComp.SetHiddenInGame(true);
		}
		else
		{
			ClothComp.SetHiddenInGame(false);
			ClothComp.SetNewClothMaterial(Material);
		}
	}
};
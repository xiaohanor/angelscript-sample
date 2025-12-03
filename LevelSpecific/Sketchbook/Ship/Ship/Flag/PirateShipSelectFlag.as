UCLASS(Abstract)
class APirateShipSelectFlag : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent FlagMeshRoot;

	UPROPERTY(DefaultComponent, Attach = FlagMeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(EditInstanceOnly)
	EPirateShipFlagType FlagType;

	bool bIsPickedUp = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"InteractCondition");
		InteractionComp.AddInteractionCondition(this, Condition);

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto FlagComp = UPirateShipFlagPlayerComponent::Get(Player);

		if(!bIsPickedUp)
			return EInteractionConditionResult::Enabled;

		if(Pirate::Flag::bAllowReturningFlags)
		{
			if(FlagComp.CarriedFlag == FlagType)
				return EInteractionConditionResult::Enabled;
		}

		return EInteractionConditionResult::Disabled;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto FlagComp = UPirateShipFlagPlayerComponent::Get(Player);

		if(Pirate::Flag::bAllowReturningFlags)
		{
			if(bIsPickedUp && FlagComp.CarriedFlag == FlagType)
			{
				// Returning flag
				PutBack();
				FlagComp.CarriedFlag = EPirateShipFlagType::None;
				return;
			}
		}

		if(FlagComp.CarriedFlag != EPirateShipFlagType::None)
		{
			Pirate::Flag::ReturnFlag(FlagComp.CarriedFlag);
		}

		FlagComp.CarriedFlag = FlagType;
		PickUp();
	}

	void PickUp()
	{
		bIsPickedUp = true;
		MeshComp.SetHiddenInGame(true);
	}

	void PutBack()
	{
		MeshComp.SetHiddenInGame(false);
		bIsPickedUp = false;
	}
};

namespace Pirate
{
	namespace Flag
	{
		void ReturnFlag(EPirateShipFlagType FlagType)
		{
			auto FlagSelectActors = TListedActors<APirateShipSelectFlag>().Array;
			for(auto FlagSelectActor : FlagSelectActors)
			{
				if(FlagSelectActor.FlagType == FlagType)
				{
					FlagSelectActor.PutBack();
					break;
				}
			}
		}
	}
}
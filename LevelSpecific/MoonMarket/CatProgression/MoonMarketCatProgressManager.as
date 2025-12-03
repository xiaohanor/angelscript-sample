struct FMoonMarketCatProgressionData
{
	AMoonMarketCat Cat;
	TArray<AActor> ActorsToProgress;
}

namespace MoonMarketCatProgressionAreas
{
	const FName GardenCat = n"GardenCat";
	const FName BabaYagaCat = n"BabaYagaCat";
	const FName GraveyardCat = n"GraveyardCat";
	const FName EntranceCat = n"EntranceCat";
}

enum EMoonMarketCatProgressionAreas
{
	GardenCat,
	BabaYagaCat,
	GraveyardCat,
	EntranceCat
}

struct FMoonMarketProgressData
{
	UPROPERTY(EditAnywhere)
	AMoonMarketCat Cat;

	UPROPERTY(EditAnywhere)
	TArray<AActor> LinkedActors;

	UPROPERTY(EditAnywhere)
	TArray<AActor> LinkedActorsCatCompletedOnly;
}

class AMoonMarketCatProgressManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5));
#endif	

	UPROPERTY(EditAnywhere)
	TArray<FMoonMarketProgressData> CatData;

	UFUNCTION()
	private void OnMoonCatFinishDelivering(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		// Print(f"{Cat.Name=}");
		Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, Cat.GetCatName(), true);
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		// Print(f"{GetSoulCaughtName(Player, Cat)=}");
		// Print(f"{Player.Name=}");
		// Print(f"{Cat.Name=}");

		if (!Cat.bSaveCatOnCompletedOnly)
			Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, GetSoulCaughtName(Player, Cat), true);
	}

	UFUNCTION()
	void ResetSavedFlags()
	{
		for (FMoonMarketProgressData& Data : CatData)
		{
			Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, Data.Cat.GetCatName(), false);
			Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, GetSoulCaughtName(Game::Mio, Data.Cat), false);
			Save::ModifyPersistentProfileFlag(EHazeSaveDataType::Progress, GetSoulCaughtName(Game::Zoe, Data.Cat), false);
		}
	}

	UFUNCTION()
	void SetSavedStates()
	{
		for (FMoonMarketProgressData& Data : CatData)
		{
			if (Save::IsPersistentProfileFlagSet(EHazeSaveDataType::Progress, Data.Cat.GetCatName()))
			{
				Data.Cat.SetCatEndState();
				for (AActor Actor : Data.LinkedActors)
				{
					auto Comp = UMoonMarketCatProgressComponent::Get(Actor);

					if (Comp != nullptr)
						Comp.SetProgressionActivated();
				}
				for (AActor Actor : Data.LinkedActorsCatCompletedOnly)
				{
					auto Comp = UMoonMarketCatProgressComponent::Get(Actor);

					if (Comp != nullptr)
						Comp.SetProgressionActivated();
				}
			}
			else
			{
				AHazePlayerCharacter PlayerTarget = nullptr;

				if (Save::IsPersistentProfileFlagSet(EHazeSaveDataType::Progress, GetSoulCaughtName(Game::Mio, Data.Cat)))
					PlayerTarget = Game::Mio;
				else if (Save::IsPersistentProfileFlagSet(EHazeSaveDataType::Progress, GetSoulCaughtName(Game::Zoe, Data.Cat)))
					PlayerTarget = Game::Zoe;

				if (PlayerTarget != nullptr)
				{
					Data.Cat.SetCatCaughtState(PlayerTarget);
					for (AActor Actor : Data.LinkedActors)
					{
						// Print("Activate Progress for: " + Data.Cat.Name + " -> " + Actor.Name, 10.0);
						UMoonMarketCatProgressComponent::Get(Actor).SetProgressionActivated();
					}
				}
			}

			Data.Cat.OnMoonCatFinishDelivering.AddUFunction(this, n"OnMoonCatFinishDelivering");
			Data.Cat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
		}
	}

	FName GetSoulCaughtName(AHazePlayerCharacter Player, AMoonMarketCat Cat) const
	{
		FString StringCat = Cat.GetCatName().GetPlainNameString();
		FString StringPlayer = "";
		
		if (Player.IsMio())
			StringPlayer = "Mio";
		else  
			StringPlayer = "Zoe";

		FString Combined = StringCat + StringPlayer;
		return FName(Combined); 
	}

	FString GetSoulCaughtString(AHazePlayerCharacter Player, AMoonMarketCat Cat) const
	{
		FString StringCat = Cat.GetCatName().GetPlainNameString();
		FString StringPlayer = "";
		
		if (Player.IsMio())
			StringPlayer = "Mio";
		else  
			StringPlayer = "Zoe";

		FString Combined = StringCat + StringPlayer;
		return Combined; 
	}
};
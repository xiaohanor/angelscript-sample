class AIslandJetpack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent InitialJetEffect;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent HoldJetEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent FuelMeter;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase JetpackMesh;

	UPROPERTY(DefaultComponent)
	UWidgetComponent FuelMeterWidget;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UMaterialInstanceDynamic FuelMeterMaterial;
	UIslandJetpackWorldSpaceFuelWidget WorldSpaceWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		FuelMeterMaterial = JetpackMesh.CreateDynamicMaterialInstance(1);
		
		WorldSpaceWidget = Cast<UIslandJetpackWorldSpaceFuelWidget>(FuelMeterWidget.GetWidget());
		WorldSpaceWidget.JetpackComp = UIslandJetpackComponent::Get(Player);
		WorldSpaceWidget.PlayerOwner = Player;
		WorldSpaceWidget.Settings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintPure)
	float GetFuelAmount()
	{
		return WorldSpaceWidget.GetCurrentFuel();
	}
};

namespace IslandJetpack
{
	const FName Jetpack = n"Jetpack";
	const FName BlockedWhileInPhasableMovement = n"BlockedWhileInPhasableMovement";
	const FString JetpackTemporalLog = "Jetpack";
	
	UFUNCTION(BlueprintCallable, Category = "Island")
	void IslandToggleJetpack(bool bToggleOn, EHazeSelectPlayer PlayersToToggle = EHazeSelectPlayer::Both)
	{
		TArray<AHazePlayerCharacter> SelectedPlayers;
		if (PlayersToToggle == EHazeSelectPlayer::Mio)
		{
			SelectedPlayers.Add(Game::Mio);
		}
		else if (PlayersToToggle == EHazeSelectPlayer::Zoe)
		{
			SelectedPlayers.Add(Game::Zoe);
		}
		else if (PlayersToToggle == EHazeSelectPlayer::Both)
		{
			SelectedPlayers.Add(Game::Mio);
			SelectedPlayers.Add(Game::Zoe);
		}

		for(auto Player : SelectedPlayers)
		{
			auto JetpackComp = UIslandJetpackComponent::Get(Player);
			JetpackComp.ToggleJetpack(bToggleOn);
		}
	}

	UFUNCTION(BlueprintPure, Category = "Island") const
	AIslandJetpack IslandGetPlayerJetpackActor(AHazePlayerCharacter Player)
	{
		if(Player == nullptr)
			return nullptr;
	
		auto JetpackComp = UIslandJetpackComponent::Get(Player);
		if(JetpackComp == nullptr)
			return nullptr;

		return JetpackComp.Jetpack;		
	}
}
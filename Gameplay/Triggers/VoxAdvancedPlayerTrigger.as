
enum EVoxPlayerAdvancedTriggerCondition
{
	AnyPlayersInside,
	BothPlayersInside,
	OnlyOnePlayerInside,
	VisitedByBothPlayers, // + TimeInTrigger Invalid because players can't leave
						  // VisitedByBothPlayerAnyInside -> used for TimeInTrigger + VisitedByBothPlayers where one user has to stay in it
}

enum EVoxPlayerAdvancedTriggerWhoPlays
{
	FirstInside,
	LastInside,
}

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class AVoxAdvancedPlayerTrigger : AVolume
{
	// Editor/debug properties
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.8, 1.0));
	default BrushComponent.LineThickness = 4.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default BrushColor = FLinearColor::Teal;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "VoxSpeaker";
#endif

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	EVoxPlayerAdvancedTriggerCondition TriggerCondition = EVoxPlayerAdvancedTriggerCondition::AnyPlayersInside;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	EVoxPlayerAdvancedTriggerWhoPlays WhoPlays = EVoxPlayerAdvancedTriggerWhoPlays::FirstInside;

	// True if the trigger should detect Mio
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	bool bTriggerForMio = true;

	// True if the trigger should detect Zoe
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	bool bTriggerForZoe = true;

	// Whether the trigger should ignore networking and only trigger locally
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox", AdvancedDisplay)
	bool bTriggerLocally = false;

	// Default trigger component
	UPROPERTY(EditAnywhere, DefaultComponent, ShowOnActor)
	UVoxAdvancedPlayerTriggerComponent VoxAdvancedTriggerComponent;

	// Events
	UPROPERTY(Category = "HazeVox")
	FPlayerTriggerEvent OnPlayerEnter;

	UPROPERTY(Category = "HazeVox")
	FPlayerTriggerEvent OnPlayerLeave;

	UPROPERTY(Category = "HazeVox")
	FVoxTriggerEvent OnTriggered;

	private TArray<AHazePlayerCharacter> EnteredPlayers;
	private TArray<EHazePlayer> VisitedPlayers;
	private bool bIsControlSideOnly = false;

	private TPerPlayer<FVoxAdvancedPlayerTriggerPerPlayerData> PerPlayerData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeVoxController::Get().RegisterTriggerCallbacks(this, n"EnablePlayerTrigger", n"DisablePlayerTrigger");
		if (!UHazeVoxController::Get().IsManagerActive())
			DisablePlayerTrigger(UHazeVoxController::Get());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UHazeVoxController::Get().UnregisterTriggerCallback(this);
	}

	UFUNCTION(Category = "Vox Player Trigger")
	void EnablePlayerTrigger(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			PlayerData.DisableInstigators.Remove(Instigator);
		}
		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Vox Player Trigger")
	void DisablePlayerTrigger(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			PlayerData.DisableInstigators.AddUnique(Instigator);
		}
		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Vox Player Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);
	}

	UFUNCTION(Category = "Vox Player Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
		UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Vox Player Trigger")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
		{
			if (!bTriggerForMio)
				return false;
		}
		else
		{
			if (!bTriggerForZoe)
				return false;
		}

		const auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.DisableInstigators.Num() != 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	private void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UpdateIsControlSide();
		if (bIsControlSideOnly)
		{
			if (!HasControl())
				return;
		}
		else
		{
			if (!Player.HasControl() && !bTriggerLocally)
				return;
		}

		if (!IsEnabledForPlayer(Player))
			return;

		const bool bPlayerInside = EnteredPlayers.Contains(Player);
		if (!bPlayerInside)
		{
			PlayerEnter(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	private void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UpdateIsControlSide();
		if (bIsControlSideOnly)
		{
			if (!HasControl())
				return;
		}
		else
		{
			if (!Player.HasControl() && !bTriggerLocally)
				return;
		}

		if (!IsEnabledForPlayer(Player))
			return;

		const bool bPlayerInside = EnteredPlayers.Contains(Player);
		if (bPlayerInside)
		{
			PlayerLeave(Player);
		}
	}

	// Manually update which players are inside
	private void UpdateAlreadyInsidePlayers()
	{
		UpdateIsControlSide();
		const bool bHasControl = HasControl();
		if (bIsControlSideOnly && !bHasControl)
			return;

		for (auto Player : Game::Players)
		{
			if (!bIsControlSideOnly && !Player.HasControl() && !bTriggerLocally)
				continue;

			bool bIsInside = false;
			if (IsEnabledForPlayer(Player))
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			const bool bPlayerInside = EnteredPlayers.Contains(Player);
			if (bPlayerInside && !bIsInside)
			{
				PlayerLeave(Player);
			}
			else if (!bPlayerInside && bIsInside)
			{
				PlayerEnter(Player);
			}
		}
	}

	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggerLocally || bIsControlSideOnly) // TODO: bIsControlSideOnly should not be here?
			LocalPlayerEnter(Player);
		else
			CrumbPlayerEnter(Player);
	}

	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		if (bTriggerLocally || bIsControlSideOnly) // TODO: bIsControlSideOnly should not be here?
			LocalPlayerLeave(Player);
		else
			CrumbPlayerLeave(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerEnter(AHazePlayerCharacter Player)
	{
		LocalPlayerEnter(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerLeave(AHazePlayerCharacter Player)
	{
		LocalPlayerLeave(Player);
	}

	private void LocalPlayerEnter(AHazePlayerCharacter Player)
	{
		VisitedPlayers.AddUnique(Player.Player);

		const bool bAdded = EnteredPlayers.AddUnique(Player);
		if (bAdded)
		{
			OnPlayerEnter.Broadcast(Player);
			EvaluateTriggerPlayerEnter();
		}
	}

	private void LocalPlayerLeave(AHazePlayerCharacter Player)
	{
		int RemovedIndex = EnteredPlayers.Remove(Player);
		if (RemovedIndex >= 0)
		{
			OnPlayerLeave.Broadcast(Player);
			EvaluateTriggerPlayerLeave();
		}
	}

	private void UpdateIsControlSide()
	{
		bIsControlSideOnly = EvaluateIsControlSideOnly();
	}

	private bool EvaluateIsControlSideOnly() const
	{
		if (bTriggerLocally)
			return false;

		if (TriggerCondition != EVoxPlayerAdvancedTriggerCondition::AnyPlayersInside)
			return true;

		if (VoxAdvancedTriggerComponent.TriggerType != EVoxAdvancedPlayerTriggerType::Immediate)
			return true;

		if (VoxAdvancedTriggerComponent.DistanceCheckMode != EVoxPlayerAdvancedDistanceCheckMode::None)
			return true;

		if (bTriggerForMio)
		{
			if (VoxAdvancedTriggerComponent.MioVoxAsset != nullptr)
				return true;

			if (VoxAdvancedTriggerComponent.MioAltVoxAsset != nullptr)
				return true;
		}

		if (bTriggerForZoe)
		{
			if (VoxAdvancedTriggerComponent.ZoeVoxAsset != nullptr)
				return true;

			if (VoxAdvancedTriggerComponent.ZoeAltVoxAsset != nullptr)
				return true;
		}

		return false;
	}

	private void TriggerContitionTrue()
	{
		AHazePlayerCharacter TriggeredBy;
		switch (WhoPlays)
		{
			case EVoxPlayerAdvancedTriggerWhoPlays::FirstInside:
			{
				if (TriggerCondition == EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers)
				{
					TriggeredBy = Game::GetPlayer(VisitedPlayers[0]);
				}
				else
				{
					TriggeredBy = EnteredPlayers[0];
				}
				break;
			}
			case EVoxPlayerAdvancedTriggerWhoPlays::LastInside:
			{
				if (TriggerCondition == EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers)
				{
					TriggeredBy = Game::GetPlayer(VisitedPlayers.Last());
				}
				else
				{
					TriggeredBy = EnteredPlayers.Last();
				}
				break;
			}
		}
		VoxAdvancedTriggerComponent.StartTrigger(TriggeredBy, bIsControlSideOnly);
	}

	private void TriggerContitionFalse()
	{
		VoxAdvancedTriggerComponent.StopTrigger();
	}

	private void EvaluateTriggerPlayerEnter()
	{
		switch (TriggerCondition)
		{
			case EVoxPlayerAdvancedTriggerCondition::AnyPlayersInside:
			{
				TriggerContitionTrue();
				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::BothPlayersInside:
			{
				if (EnteredPlayers.Num() == 2)
					TriggerContitionTrue();

				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::OnlyOnePlayerInside:
			{
				if (EnteredPlayers.Num() == 1)
					TriggerContitionTrue();
				else
					TriggerContitionFalse();

				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers:
			{
				if (VisitedPlayers.Num() == 2)
					TriggerContitionTrue();

				break;
			}
		}
	}

	private void EvaluateTriggerPlayerLeave()
	{
		switch (TriggerCondition)
		{
			case EVoxPlayerAdvancedTriggerCondition::AnyPlayersInside:
			{
				if (EnteredPlayers.Num() == 0)
					TriggerContitionFalse();

				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::BothPlayersInside:
			{
				TriggerContitionFalse();
				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::OnlyOnePlayerInside:
			{
				if (EnteredPlayers.Num() == 1)
					TriggerContitionTrue();
				else
					TriggerContitionFalse();

				break;
			}
			case EVoxPlayerAdvancedTriggerCondition::VisitedByBothPlayers:
			{
				// You can't unvisit a trigger
				break;
			}
		}
	}

}

struct FVoxAdvancedPlayerTriggerPerPlayerData
{
	TArray<FInstigator> DisableInstigators;
};

#if EDITOR

namespace FVoxValidationHelpers
{
	struct FValidationResult
	{
		FString TriggerName;
		TArray<FString> Infos;
		TArray<FString> Errors;
	}

	bool ValidateTrigger(AVoxAdvancedPlayerTrigger Trigger, FValidationResult&out Result)
	{
		if (!IsValid(Trigger))
			return false;

		if (!IsValid(Trigger.VoxAdvancedTriggerComponent))
			return false;

		Result.TriggerName = Trigger.ActorNameOrLabel;

		UVoxAdvancedPlayerTriggerComponent TriggerComponent = Trigger.VoxAdvancedTriggerComponent;

		if (!Trigger.bTriggerForMio && !Trigger.bTriggerForZoe)
			Result.Errors.Add("Not Triggering for any player");

		const bool bHasDefaultAsset = TriggerComponent.VoxAsset != nullptr;
		const bool bHasMioAsset = TriggerComponent.MioVoxAsset != nullptr;
		const bool bHasMioAltAsset = TriggerComponent.MioAltVoxAsset != nullptr;
		const bool bHasZoeAsset = TriggerComponent.ZoeVoxAsset != nullptr;
		const bool bHasZoeAltAsset = TriggerComponent.ZoeAltVoxAsset != nullptr;

		const bool bHasAnyAsset = bHasDefaultAsset || bHasMioAsset || bHasMioAltAsset || bHasZoeAsset || bHasZoeAltAsset;
		if (!bHasAnyAsset)
		{
			Result.Errors.Add("No VoxAssets");
		}

		if (bHasDefaultAsset)
		{
			if (bHasMioAsset || bHasZoeAsset)
			{
				Result.Errors.Add("Has both VoxAsset and MioVoxAsset/ZoeVoxAsset");
			}
		}
		else
		{
			if (TriggerComponent.DistanceCheckMode == EVoxPlayerAdvancedDistanceCheckMode::None)
			{
				if (Trigger.bTriggerForMio && !bHasMioAsset)
				{
					Result.Errors.Add("Triggering for Mio but has no VoxAsset or MioVoxAsset");
				}
				if (Trigger.bTriggerForZoe && !bHasZoeAsset)
				{
					Result.Errors.Add("Triggering for Zoe but has no VoxAsset or ZoeVoxAsset");
				}
			}
			else
			{
				if (Trigger.bTriggerForMio)
				{
					if (!bHasMioAsset && !bHasMioAltAsset)
					{
						Result.Errors.Add("Triggering for Mio but has no VoxAsset or MioVoxAsset or MioAltAsset");
					}
					else
					{
						if (!bHasMioAsset)
							Result.Infos.Add("No Asset if Mio is passes distance check");

						if (!bHasMioAltAsset)
							Result.Infos.Add("No Asset if Mio is fails distance check");
					}
				}

				if (Trigger.bTriggerForZoe)
				{
					if (!bHasZoeAsset && !bHasZoeAltAsset)
					{
						Result.Errors.Add("Triggering for Zoe but has no VoxAsset or ZoeVoxAsset or ZoeAltAsset");
					}
					else
					{
						if (!bHasZoeAsset)
							Result.Infos.Add("No Asset if Zoe is passes distance check");

						if (!bHasZoeAltAsset)
							Result.Infos.Add("No Asset if Zoe is fails distance check");
					}
				}
			}
		}

		if (!Trigger.bTriggerForMio)
		{
			if (bHasMioAsset)
				Result.Errors.Add("Has MioVoxAsset when not triggering for Mio");

			if (bHasMioAltAsset)
				Result.Errors.Add("Has MioAltVoxAsset when not triggering for Mio");
		}

		if (!Trigger.bTriggerForZoe)
		{
			if (bHasZoeAsset)
				Result.Errors.Add("Has ZoeVoxAsset when not triggering for Zoe");

			if (bHasZoeAltAsset)
				Result.Errors.Add("Has ZoeAltVoxAsset when not triggering for Zoe");
		}

		if (TriggerComponent.DistanceCheckMode == EVoxPlayerAdvancedDistanceCheckMode::FirstInsideToActor ||
			TriggerComponent.DistanceCheckMode == EVoxPlayerAdvancedDistanceCheckMode::OtherPlayerToActor)
		{
			if (TriggerComponent.DistanceActor == nullptr)
			{
				Result.Errors.Add("No DistanceActor to check distance against!");
			}
		}

		if (TriggerComponent.TriggerFireLimit == 0)
		{
			Result.Errors.Add("TriggerFireLimit is zero");
		}

		if (TriggerComponent.RepeatMode == EVoxAdvancedPlayerTriggerRepeat::WhileActive)
		{
			if (TriggerComponent.NumRepeats == 0)
			{
				Result.Errors.Add("NumRepeats is zero");
			}

			if (TriggerComponent.NumRepeats > -1 && TriggerComponent.TriggerFireLimit > -1)
			{
				if (TriggerComponent.NumRepeats > TriggerComponent.TriggerFireLimit)
				{
					Result.Errors.Add("NumRepeats is greater than TriggerFireLimit");
				}
			}
		}

		return true;
	}
}

class UVoxAdvancedPlayerTriggerCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AVoxAdvancedPlayerTrigger;

	UHazeImmediateDrawer Drawer;

	private const FLinearColor ErrorColor = FLinearColor::MakeFromHex(0xff8a4300);
	private const FLinearColor InfoColor = FLinearColor::MakeFromHex(0xff005885);
	private const FLinearColor SuccessColor = FLinearColor::MakeFromHex(0xff134e13);

	private TArray<FVoxValidationHelpers::FValidationResult> ValidationResults;

	private float NextValidationTimer = 0.0;
	private const float ValidationTime = 1.0 / 30.0;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"HazeVox Assets", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"HazeVox", CategoryType = EScriptDetailCategoryType::TypeSpecific);

		Drawer = AddImmediateRow(n"HazeVox Validation", "Validate", false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Drawer == nullptr)
			return;

		if (!Drawer.IsVisible())
			return;

		if (ObjectsBeingCustomized.IsEmpty())
			return;

		NextValidationTimer -= DeltaTime;
		if (NextValidationTimer <= 0.0)
		{
			NextValidationTimer = ValidationTime;

			ValidationResults.Reset();

			for (const UObject BeingCustomized : ObjectsBeingCustomized)
			{
				AVoxAdvancedPlayerTrigger Trigger = Cast<AVoxAdvancedPlayerTrigger>(BeingCustomized);
				if (!IsValid(Trigger))
					continue;

				FVoxValidationHelpers::FValidationResult ValidationResult;
				bool bOk = FVoxValidationHelpers::ValidateTrigger(Trigger, ValidationResult);
				if (bOk)
				{
					ValidationResults.Add(ValidationResult);
				}
			}
		}

		FHazeImmediateVerticalBoxHandle OuterBox = Drawer.BeginVerticalBox();

		if (ValidationResults.Num() == 1)
		{
			DrawValidationResult(OuterBox, ValidationResults[0], false);
		}
		else if (ValidationResults.Num() > 1)
		{
			for (auto Validation : ValidationResults)
			{
				DrawValidationResult(OuterBox, Validation, true);
			}
		}
		else
		{
			auto SuccessBox = OuterBox.BorderBox().BackgroundColor(FLinearColor::Black).VerticalBox();
			SuccessBox.Text("No Validations Issues");
		}
	}

	private void DrawValidationResult(FHazeImmediateVerticalBoxHandle& OuterBox, FVoxValidationHelpers::FValidationResult Validation, bool bIncludeName)
	{
		if (bIncludeName)
		{
			auto SuccessBox = OuterBox.BorderBox().BackgroundColor(FLinearColor::Black).VerticalBox();
			SuccessBox.Text(Validation.TriggerName);
		}

		if (Validation.Errors.IsEmpty() && Validation.Infos.IsEmpty())
		{
			auto SuccessBox = OuterBox.BorderBox().BackgroundColor(SuccessColor).VerticalBox();
			SuccessBox.Text("No Validation Issues");

			return;
		}

		if (Validation.Errors.Num() > 0)
		{
			auto ErrorVBox = OuterBox.BorderBox().BackgroundColor(ErrorColor).VerticalBox();
			for (FString ErrorText : Validation.Errors)
			{
				ErrorVBox.Text(ErrorText);
			}
		}

		if (Validation.Infos.Num() > 0)
		{
			auto InfoVBox = OuterBox.BorderBox().BackgroundColor(InfoColor).VerticalBox();
			for (FString InfoText : Validation.Infos)
			{
				InfoVBox.Text(InfoText);
			}
		}
	}
}
#endif
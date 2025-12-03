

enum EVoxDuoPlayerTriggerCondition
{
	AnyPlayersInside,
	BothPlayersInside,
	VisitedByBothPlayers
}

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class AVoxDuoPlayerTrigger : AVolume
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
	EVoxDuoPlayerTriggerCondition TriggerCondition = EVoxDuoPlayerTriggerCondition::AnyPlayersInside;

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
	UVoxDuoPlayerTriggerComponent VoxDuoPlayerTriggerComponent;

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

		const bool bPlayerInside = EnteredPlayers.Contains(Player);
		if (bPlayerInside)
		{
			PlayerLeave(Player);
		}
	}

	private void UpdateIsControlSide()
	{
		bIsControlSideOnly = EvaluateIsControlSideOnly();
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
			// OnPlayerEnter.Broadcast(Player);
			EvaluateTriggerPlayerEnter();
		}
	}

	private void LocalPlayerLeave(AHazePlayerCharacter Player)
	{
		int RemovedIndex = EnteredPlayers.Remove(Player);
		if (RemovedIndex >= 0)
		{
			// OnPlayerLeave.Broadcast(Player);
			EvaluateTriggerPlayerLeave();
		}
	}

	private bool EvaluateIsControlSideOnly() const
	{
		if (bTriggerLocally)
			return false;

		if (TriggerCondition != EVoxDuoPlayerTriggerCondition::AnyPlayersInside)
			return true;

		if (VoxDuoPlayerTriggerComponent.ChanceType != EVoxDuoPlayerChanceType::AlwaysBoth)
			return true;

		return false;
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
			if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
				bIsInside = true;

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

	private void EvaluateTriggerPlayerEnter()
	{
		switch (TriggerCondition)
		{
			case EVoxDuoPlayerTriggerCondition::AnyPlayersInside:
			{
				VoxDuoPlayerTriggerComponent.StartTrigger(bIsControlSideOnly);
				break;
			}
			case EVoxDuoPlayerTriggerCondition::BothPlayersInside:
			{
				if (EnteredPlayers.Num() == 2)
					VoxDuoPlayerTriggerComponent.StartTrigger(bIsControlSideOnly);

				break;
			}
			case EVoxDuoPlayerTriggerCondition::VisitedByBothPlayers:
			{
				if (VisitedPlayers.Num() == 2)
					VoxDuoPlayerTriggerComponent.StartTrigger(bIsControlSideOnly);

				break;
			}
		}
	}

	private void EvaluateTriggerPlayerLeave()
	{
		switch (TriggerCondition)
		{
			case EVoxDuoPlayerTriggerCondition::AnyPlayersInside:
			{
				if (EnteredPlayers.Num() == 0)
					VoxDuoPlayerTriggerComponent.StopTrigger();

				break;
			}
			case EVoxDuoPlayerTriggerCondition::BothPlayersInside:
			{
				VoxDuoPlayerTriggerComponent.StopTrigger();
				break;
			}
			case EVoxDuoPlayerTriggerCondition::VisitedByBothPlayers:
			{
				// You can't unvisit a trigger
				break;
			}
		}
	}
}

class UVoxDuoPlayerTriggerCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AVoxDuoPlayerTrigger;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		EditCategory(n"HazeVox Assets", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"HazeVox", CategoryType = EScriptDetailCategoryType::TypeSpecific);
	}
}
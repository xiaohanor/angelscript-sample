
enum EVoxPlayerTriggerType
{
	AnyPlayersInside,
	BothPlayersInside,
	OnlyOnePlayerInside,
	BothPlayersOnlyFirstInsidePlays,
	BothPlayersOnlyLastInsidePlays,
	VisitedByBothPlayersFirstInsidePlays,
	VisitedByBothPlayersLastInsidePlays,
}

// Soft deprecated, use AVoxAdvancedPlayerTrigger instead
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, NotPlaceable)
class AVoxPlayerTrigger : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.8, 1.0));
	default BrushComponent.LineThickness = 4.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default BrushColor = FLinearColor::Teal;

	UPROPERTY(EditAnywhere, DefaultComponent, ShowOnActor)
	UVoxTriggerComponent VoxTriggerComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "VoxSpeaker";
#endif

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	bool bTriggerForMio = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	bool bTriggerForZoe = true;

	// Whether the trigger should ignore networking and only trigger locally
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox", AdvancedDisplay)
	bool bTriggerLocally = false;

	UPROPERTY(Category = "HazeVox")
	FPlayerTriggerEvent OnPlayerEnter;

	UPROPERTY(Category = "HazeVox")
	FPlayerTriggerEvent OnPlayerLeave;

	UPROPERTY(Category = "HazeVox")
	FVoxTriggerEvent OnTriggered;

	private TPerPlayer<FVoxPlayerTriggerPerPlayerData> PerPlayerData;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	EVoxPlayerTriggerType TriggerType;

	private TArray<AHazePlayerCharacter> EnteredPlayers;
	private TArray<EHazePlayer> VisitedPlayers;
	private bool bIsControlSideOnly = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VoxTriggerComponent.OnVoxAssetTriggered.AddUFunction(this, n"OnComponentTriggered");

		UHazeVoxController::Get().RegisterTriggerCallbacks(this, n"EnablePlayerTrigger", n"DisablePlayerTrigger");
		if (!UHazeVoxController::Get().IsManagerActive())
			DisablePlayerTrigger(UHazeVoxController::Get());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UHazeVoxController::Get().UnregisterTriggerCallback(this);
	}

	UFUNCTION()
	void OnComponentTriggered(AHazeActor Player)
	{
		OnTriggered.Broadcast(Player);
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

	// Manually update which players are inside, we may have missed overlap events due to disable or streaming
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

	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggerLocally || bIsControlSideOnly)
			LocalPlayerEnter(Player);
		else
			CrumbPlayerEnter(Player);
	}

	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		if (bTriggerLocally || bIsControlSideOnly)
			LocalPlayerLeave(Player);
		else
			CrumbPlayerLeave(Player);
	}

	private void LocalPlayerEnter(AHazePlayerCharacter Player)
	{
		VisitedPlayers.AddUnique(Player.Player);

		const bool bAdded = EnteredPlayers.AddUnique(Player);
		if (bAdded)
		{
			HandleTriggerStart(Player);
			OnPlayerEnter.Broadcast(Player);
		}
	}

	private void LocalPlayerLeave(AHazePlayerCharacter Player)
	{
		int RemovedIndex = EnteredPlayers.Remove(Player);
		if (RemovedIndex >= 0)
		{
			HandleTriggerEnd();
			OnPlayerLeave.Broadcast(Player);
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

		if (TriggerType != EVoxPlayerTriggerType::AnyPlayersInside)
			return true;

		if (VoxTriggerComponent.TimeInTrigger > 0.0)
			return true;

		if (bTriggerForMio && VoxTriggerComponent.MioVoxAsset != nullptr)
			return true;

		if (bTriggerForZoe && VoxTriggerComponent.ZoeVoxAsset != nullptr)
			return true;

		return false;
	}

	private void HandleTriggerStart(AHazePlayerCharacter Player)
	{
		switch (TriggerType)
		{
			case EVoxPlayerTriggerType::AnyPlayersInside:
			{
				VoxTriggerComponent.OnStarted(Player, bIsControlSideOnly);
				break;
			}
			case EVoxPlayerTriggerType::BothPlayersInside:
			case EVoxPlayerTriggerType::BothPlayersOnlyFirstInsidePlays:
			{
				if (EnteredPlayers.Num() > 1)
					VoxTriggerComponent.OnStarted(EnteredPlayers[0], bIsControlSideOnly);

				break;
			}
			case EVoxPlayerTriggerType::BothPlayersOnlyLastInsidePlays:
			{
				if (EnteredPlayers.Num() > 1)
					VoxTriggerComponent.OnStarted(EnteredPlayers.Last(), bIsControlSideOnly);

				break;
			}
			case EVoxPlayerTriggerType::OnlyOnePlayerInside:
			{
				if (EnteredPlayers.Num() == 1)
				{
					VoxTriggerComponent.OnStarted(Player, bIsControlSideOnly);
				}
				else
					VoxTriggerComponent.OnEnded();

				break;
			}

			case EVoxPlayerTriggerType::VisitedByBothPlayersFirstInsidePlays:
			{
				if (VisitedPlayers.Num() > 1)
				{
					auto FistVisitedPlayer = Game::GetPlayer(VisitedPlayers[0]);
					VoxTriggerComponent.OnStarted(FistVisitedPlayer, bIsControlSideOnly);
				}
				break;
			}
			case EVoxPlayerTriggerType::VisitedByBothPlayersLastInsidePlays:
			{
				if (VisitedPlayers.Num() > 1)
				{
					VoxTriggerComponent.OnStarted(Player, bIsControlSideOnly);
				}
				break;
			}
		}
	}

	private void HandleTriggerEnd()
	{
		switch (TriggerType)
		{
			case EVoxPlayerTriggerType::AnyPlayersInside:
			{
				if (EnteredPlayers.Num() == 0)
					VoxTriggerComponent.OnEnded();

				break;
			}
			case EVoxPlayerTriggerType::BothPlayersInside:
			case EVoxPlayerTriggerType::BothPlayersOnlyFirstInsidePlays:
			case EVoxPlayerTriggerType::BothPlayersOnlyLastInsidePlays:
			{
				VoxTriggerComponent.OnEnded();

				break;
			}
			case EVoxPlayerTriggerType::OnlyOnePlayerInside:
			{
				if (EnteredPlayers.Num() == 1)
				{
					VoxTriggerComponent.OnStarted(EnteredPlayers[0], bIsControlSideOnly);
				}
				else
					VoxTriggerComponent.OnEnded();

				break;
			}
			case EVoxPlayerTriggerType::VisitedByBothPlayersFirstInsidePlays:
			case EVoxPlayerTriggerType::VisitedByBothPlayersLastInsidePlays:
			{
				if (VisitedPlayers.Num() > 1 && EnteredPlayers.Num() == 0)
					VoxTriggerComponent.OnEnded();

				break;
			}
		}
	}
}

struct FVoxPlayerTriggerPerPlayerData
{
	TArray<FInstigator> DisableInstigators;
};

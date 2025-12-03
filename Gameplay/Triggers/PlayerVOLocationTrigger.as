
event void FPlayerVOLocationTriggerEvent();

enum EPlayerVOLocationTriggerType
{
	AnyPlayersInside,
	BothPlayersInside,
	VisitedByBothPlayers,
	MioInside,
	ZoeInside,
	OnlyMioInside,
	OnlyZoeInside,
}

class APlayerVOLocationTrigger : AVolume
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.91, 0.00, 0.88));
	default BrushComponent.LineThickness = 5.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "VOTrigger")
	bool bTriggerOnce = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "VOTrigger")
	EPlayerVOLocationTriggerType TriggerType = EPlayerVOLocationTriggerType::AnyPlayersInside;

	UPROPERTY(Category = "VOTrigger")
	FPlayerTriggerEvent OnPlayerEnter;

	UPROPERTY(Category = "VOTrigger")
	FPlayerTriggerEvent OnPlayerLeave;

	UPROPERTY(Category = "VOTrigger")
	FPlayerVOLocationTriggerEvent OnTriggered;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "VOTrigger")
	bool bTriggerActive = false;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "VOTrigger")
	TArray<AHazePlayerCharacter> EnteredPlayers;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "VOTrigger")
	TArray<EHazePlayer> VisitedPlayers;

	private bool bTriggered = false;

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	AHazePlayerCharacter FirstPlayerInside() const
	{
		if (EnteredPlayers.Num() > 0)
			return EnteredPlayers[0];

		return nullptr;
	}

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	AHazePlayerCharacter LastPlayerInside() const
	{
		if (EnteredPlayers.Num() > 0)
			return EnteredPlayers.Last();

		return nullptr;
	}

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	int32 NumPlayersInside() const
	{
		return EnteredPlayers.Num();
	}

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	int32 NumVisitedPlayers() const
	{
		return VisitedPlayers.Num();
	}

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	bool IsMioInside() const
	{
		return EnteredPlayers.Contains(Game::GetMio());
	}

	UFUNCTION(BlueprintPure, Category = "VOTrigger")
	bool IsZoeInside() const
	{
		return EnteredPlayers.Contains(Game::GetZoe());
	}

	UFUNCTION(BlueprintOverride)
	private void ActorBeginOverlap(AActor OtherActor)
	{
		if (!HasControl())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		VisitedPlayers.AddUnique(Player.Player);

		const bool bPlayerInside = EnteredPlayers.Contains(Player);
		if (!bPlayerInside)
		{
			CrumbPlayerEnter(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	private void ActorEndOverlap(AActor OtherActor)
	{
		if (!HasControl())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		const bool bPlayerInside = EnteredPlayers.Contains(Player);
		if (bPlayerInside)
		{
			CrumbPlayerLeave(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerEnter(AHazePlayerCharacter Player)
	{
		VisitedPlayers.AddUnique(Player.Player);

		const bool bAdded = EnteredPlayers.AddUnique(Player);
		if (bAdded)
		{
			HandleTriggerStart();
			OnPlayerEnter.Broadcast(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerLeave(AHazePlayerCharacter Player)
	{
		int RemovedIndex = EnteredPlayers.Remove(Player);
		if (RemovedIndex >= 0)
		{
			HandleTriggerEnd();
			OnPlayerLeave.Broadcast(Player);
		}
	}

	private void TriggerStart()
	{
		bTriggerActive = true;
		bTriggered = true;
		OnTriggered.Broadcast();
	}

	private void TriggerEnd()
	{
		bTriggerActive = false;
	}

	private void HandleTriggerStart()
	{
		if (bTriggered && bTriggerOnce)
			return;

		if (!bTriggerActive)
		{
			switch (TriggerType)
			{
				case EPlayerVOLocationTriggerType::AnyPlayersInside:
				{
					TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::BothPlayersInside:
				{
					if (EnteredPlayers.Num() > 1)
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::VisitedByBothPlayers:
				{
					if (VisitedPlayers.Num() > 1)
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::MioInside:
				{
					if (EnteredPlayers.Contains(Game::GetMio()))
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::ZoeInside:
				{
					if (EnteredPlayers.Contains(Game::GetZoe()))
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyMioInside:
				{
					if (EnteredPlayers.Num() == 1 && EnteredPlayers.Contains(Game::GetMio()))
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyZoeInside:
				{
					if (EnteredPlayers.Num() == 1 && EnteredPlayers.Contains(Game::GetZoe()))
						TriggerStart();
					break;
				}
			}
		}
		else
		{
			// These can be stopped when the other player enters
			switch (TriggerType)
			{
				case EPlayerVOLocationTriggerType::OnlyMioInside:
				{
					if (EnteredPlayers.Num() > 1 || !EnteredPlayers.Contains(Game::GetMio()))
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyZoeInside:
				{
					if (EnteredPlayers.Num() > 1 || EnteredPlayers.Contains(Game::GetZoe()))
						TriggerEnd();
					break;
				}
				default:
				break;
			}
		}
	}

	private void HandleTriggerEnd()
	{
		if (bTriggered && bTriggerOnce)
			return;

		if (bTriggerActive)
		{
			switch (TriggerType)
			{
				case EPlayerVOLocationTriggerType::AnyPlayersInside:
				{
					if (EnteredPlayers.Num() == 0)
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::BothPlayersInside:
				{
					if (EnteredPlayers.Num() < 2)
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::VisitedByBothPlayers:
				{
					// Can't be stopped
					break;
				}
				case EPlayerVOLocationTriggerType::MioInside:
				{
					if (!EnteredPlayers.Contains(Game::GetMio()))
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::ZoeInside:
				{
					if (!EnteredPlayers.Contains(Game::GetZoe()))
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyMioInside:
				{
					if (EnteredPlayers.Num() != 1 || !EnteredPlayers.Contains(Game::GetMio()))
						TriggerEnd();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyZoeInside:
				{
					if (EnteredPlayers.Num() != 1 || EnteredPlayers.Contains(Game::GetZoe()))
						TriggerEnd();
					break;
				}
			}
		}
		else
		{
			// These can trigger when the other player leaves
			switch (TriggerType)
			{
				case EPlayerVOLocationTriggerType::OnlyMioInside:
				{
					if (EnteredPlayers.Num() == 1 && EnteredPlayers.Contains(Game::GetMio()))
						TriggerStart();
					break;
				}
				case EPlayerVOLocationTriggerType::OnlyZoeInside:
				{
					if (EnteredPlayers.Num() == 1 && EnteredPlayers.Contains(Game::GetZoe()))
						TriggerStart();
					break;
				}
				default:
				break;
			}
		}
	}
};


event void FPlayerTriggerEvent(AHazePlayerCharacter Player);

/**
 * Standard trigger volume that tracks whether players are inside it.
 */ 
UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement = "110", NoSourceLink))
class APlayerTrigger : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.8, 1.0));
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Trigger")
    bool bTriggerForMio = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Trigger")
    bool bTriggerForZoe = true;

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Trigger", AdvancedDisplay)
	bool bTriggerLocally = false;

	/* Whether to disable the interaction by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Player Trigger", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the interaction enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Player Trigger", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

    UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerEnter;

    UPROPERTY(Category = "Player Trigger")
    FPlayerTriggerEvent OnPlayerLeave;

    private TPerPlayer<FPlayerTriggerPerPlayerData> PerPlayerData;

    UFUNCTION(Category = "Player Trigger")
    void EnablePlayerTrigger(FInstigator Instigator) final
    {
		bool bUpdateContainment = false;
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			if (PlayerData.DisableInstigators.Contains(Instigator))
			{
				PlayerData.DisableInstigators.Remove(Instigator);
				bUpdateContainment = true;
			}
		}

		if (bUpdateContainment)
			UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Player Trigger")
    void DisablePlayerTrigger(FInstigator Instigator) final
    {
		bool bUpdateContainment = false;
		for (auto Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			if (!PlayerData.DisableInstigators.Contains(Instigator))
			{
				PlayerData.DisableInstigators.Add(Instigator);
				bUpdateContainment = true;
			}
		}

		if (bUpdateContainment)
			UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(Category = "Player Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) final
	{
		auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.DisableInstigators.Contains(Instigator))
		{
			PlayerData.DisableInstigators.Remove(Instigator);
			UpdateAlreadyInsidePlayers();
		}
	}

	UFUNCTION(Category = "Player Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) final
	{
		auto& PlayerData = PerPlayerData[Player];
		if (!PlayerData.DisableInstigators.Contains(Instigator))
		{
			PlayerData.DisableInstigators.Add(Instigator);
			UpdateAlreadyInsidePlayers();
		}
	}

	/**
	 * Enable the player trigger with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Player Trigger")
	void EnablePlayerTriggerAfterStartDisabled() final
	{
		if (bStartDisabled)
			EnablePlayerTrigger(StartDisabledInstigator);
	}

	UFUNCTION(BlueprintPure, Category = "Player Trigger")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const final
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
	void BeginPlay()
	{
		// Apply start disabled
		if (bStartDisabled)
			DisablePlayerTrigger(StartDisabledInstigator);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// Always leave the volume immediately on end play, we don't want to wait for
		// crumbs because we're probably getting destroyed.
		for (auto Player : Game::Players)
			ConditionalOnPlayerLeave(Player);
	}

	// Manually update which players are inside, we may have missed overlap events due to disable or streaming
	protected void UpdateAlreadyInsidePlayers()
	{
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl() && !bTriggerLocally)
				continue;

			auto& PlayerData = PerPlayerData[Player];
			bool bIsInside = false;
			if (IsEnabledForPlayer(Player))
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsInside = true;
			}

			if (PlayerData.bIsPlayerInside && !bIsInside)
			{
				if (!bTriggerLocally)
					CrumbPlayerLeave(Player);
				else
					ConditionalOnPlayerLeave(Player);
			}
			else if (!PlayerData.bIsPlayerInside && bIsInside)
			{
				if (!bTriggerLocally)
					CrumbPlayerEnter(Player);
				else
					ConditionalOnPlayerEnter(Player);
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;
        if (!IsEnabledForPlayer(Player))
            return;

		auto& PlayerData = PerPlayerData[Player];
		if (!PlayerData.bIsPlayerInside)
		{
			if (!bTriggerLocally)
				CrumbPlayerEnter(Player);
			else
				ConditionalOnPlayerEnter(Player);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;
        if (!IsEnabledForPlayer(Player))
            return;

		auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.bIsPlayerInside)
		{
			if (!bTriggerLocally)
				CrumbPlayerLeave(Player);
			else
				ConditionalOnPlayerLeave(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerEnter(AHazePlayerCharacter Player)
	{
		ConditionalOnPlayerEnter(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayerLeave(AHazePlayerCharacter Player)
	{
		ConditionalOnPlayerLeave(Player);
	}

	private void ConditionalOnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto& PlayerData = PerPlayerData[Player];
		if (!PlayerData.bIsPlayerInside)
		{
			PlayerData.bIsPlayerInside = true;
			TriggerOnPlayerEnter(Player);
		}
	}

	private void ConditionalOnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.bIsPlayerInside)
		{
			PlayerData.bIsPlayerInside = false;
			TriggerOnPlayerLeave(Player);
		}
	}

	// TODO: Remove this non-pure version of the function when we are no longer using it
	UFUNCTION(Category = "Player Trigger", Meta = (DeprecatedFunction, DeprecationMessage = "Use the pure version of Is Player Inside instead"))
	bool IsPlayerInside(AHazePlayerCharacter Player) const final
	{
		auto& PlayerData = PerPlayerData[Player];
		return PlayerData.bIsPlayerInside && IsEnabledForPlayer(Player);
	}

	UFUNCTION(BlueprintPure, Category = "Player Trigger", DisplayName = "Is Player Inside")
	bool BP_IsPlayerInsidePure(AHazePlayerCharacter Player) const final
	{
		auto& PlayerData = PerPlayerData[Player];
		return PlayerData.bIsPlayerInside && IsEnabledForPlayer(Player);
	}

	UFUNCTION(BlueprintPure, Category = "Player Trigger")
	bool IsAnyPlayerInside() const final
	{
		for (auto Player : Game::Players)
		{
			if (IsPlayerInside(Player))
				return true;
		}

		return false;
	}

	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player)
	{
		OnPlayerEnter.Broadcast(Player);
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player)
	{
		OnPlayerLeave.Broadcast(Player);
	}
}

struct FPlayerTriggerPerPlayerData
{
	bool bIsPlayerInside = false;
	TArray<FInstigator> DisableInstigators;
};
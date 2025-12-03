/**
 * Player trigger base class to support player triggers with a condition that is checked continuously while the players are inside.
 * 
 * To use it, inherit and override "IsPlayerConditionMet()"
 */ 
UCLASS(Abstract, HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class AConditionalPlayerTrigger : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.8, 1.0));
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default PrimaryActorTick.bStartWithTickEnabled = false;

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

    private TPerPlayer<FConditionalPlayerTriggerPerPlayerData> PerPlayerData;

	/**
	 * Override to specify when the player should be allowed to trigger this volume.
	 */
	protected bool IsPlayerConditionMet(AHazePlayerCharacter Player) const
	{
		return false;
	}

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
			UpdateContainment();
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
			UpdateContainment();
    }

	UFUNCTION(Category = "Player Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) final
	{
		auto& PlayerData = PerPlayerData[Player];
		if (PlayerData.DisableInstigators.Contains(Instigator))
		{
			PlayerData.DisableInstigators.Remove(Instigator);
			UpdateContainment();
		}
	}

	UFUNCTION(Category = "Player Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator) final
	{
		auto& PlayerData = PerPlayerData[Player];
		if (!PlayerData.DisableInstigators.Contains(Instigator))
		{
			PlayerData.DisableInstigators.Add(Instigator);
			UpdateContainment();
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
	private void UpdateContainment()
	{
		bool bAnyOverlapping = false;
		for (auto Player : Game::Players)
		{
			if (!Player.HasControl() && !bTriggerLocally)
				continue;

			auto& PlayerData = PerPlayerData[Player];
			bool bIsOverlapping = false;
			if (IsEnabledForPlayer(Player))
			{
				if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
					bIsOverlapping = true;
			}

			bool bShouldBeTriggered = false;
			if (bIsOverlapping && IsPlayerConditionMet(Player))
				bShouldBeTriggered = true;

			if (bIsOverlapping)
				bAnyOverlapping = true;

			if (PlayerData.bIsPlayerInside && !bShouldBeTriggered)
			{
				if (!bTriggerLocally)
					CrumbPlayerLeave(Player);
				else
					ConditionalOnPlayerLeave(Player);
			}
			else if (!PlayerData.bIsPlayerInside && bShouldBeTriggered)
			{
				if (!bTriggerLocally)
					CrumbPlayerEnter(Player);
				else
					TriggerOnPlayerEnter(Player);
			}
		}

		SetActorTickEnabled(bAnyOverlapping);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) final
	{
		UpdateContainment();
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

		UpdateContainment();
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

		UpdateContainment();
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

	bool IsPlayerInside(AHazePlayerCharacter Player) const final
	{
		auto& PlayerData = PerPlayerData[Player];
		return PlayerData.bIsPlayerInside && IsEnabledForPlayer(Player);
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

struct FConditionalPlayerTriggerPerPlayerData
{
	bool bIsPlayerInside = false;
	bool bEnterEventTriggered = false;
	TArray<FInstigator> DisableInstigators;
};
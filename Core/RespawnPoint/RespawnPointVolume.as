

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement))
class ARespawnPointVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default PrimaryActorTick.bStartWithTickEnabled = false;

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	URespawnPointVolumeVisualizerComponent VisualizerComp;
#endif

    /* These respawn point will be enabled while the player is in the indicated volume. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints")
    TArray<ARespawnPoint> EnabledRespawnPoints;

    /* Sticky respawn point volumes will stay active until the player enters a different sticky respawn point volume. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints")
    bool bSticky = true;

	/**
	 * If set, either player being inside the volume will enable
	 * the respawn point for both players.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", AdvancedDisplay)
    bool bSharedByBothPlayers = false;

	/**
	 * If set, this sticky respawn point volume can only be triggered once,
	 * and will no longer apply its respawn points after it has been triggered by a player once.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", AdvancedDisplay, Meta = (EditCondition = "bSticky && bSharedByBothPlayers", EditConditionHides))
    bool bOnlyTriggerOnce = true;

	/**
	 * Only trigger this respawn point volume when a player is both inside it and currently grounded.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", AdvancedDisplay, Meta = (EditCondition = "bSticky", EditConditionHides))
    bool bOnlyTriggerWhenPlayerGrounded = false;

	/**
	 * If set, this sticky respawn point volume can only be triggered once,
	 * and will no longer apply its respawn points after it has been triggered by a player once.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", DisplayName = "Only Trigger Once", AdvancedDisplay, Meta = (EditCondition = "bSticky && !bSharedByBothPlayers", EditConditionHides))
    bool bOnlyTriggerOnce_NonShared = false;

	/* Whether the respawn point volume should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", AdvancedDisplay)
    bool bTriggerForMio = true;

	/* Whether the respawn point volume should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", AdvancedDisplay)
    bool bTriggerForZoe = true;

	/* Whether to disable the respawn point volume by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "RespawnPoints", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the respawn point volume enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "RespawnPoints", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

    /**
	 * The first time the player enters this sticky respawn point volume,
	 * the specified respawn point volumes are permanently disabled. 
	 * 
	 * This way, even if the player backtracks, they will still respawn here.
	 */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "RespawnPoints", Meta = (EditCondition = "bSticky", EditConditionHides))
    TArray<ARespawnPointVolume> DisableBacktrackingToVolumes;

    private TPerPlayer<FRespawnPointVolumePerPlayerData> PerPlayerData;
	private bool bTriggerDisabled = false;

    default Shape::SetVolumeBrushColor(this, FLinearColor(0.0, 1.0, 0.8, 1.0));

    UFUNCTION(Category = "Respawn Point Volume")
    void EnableRespawnPointVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			EnableForPlayer(Player, Instigator);
    }

    UFUNCTION(Category = "Respawn Point Volume")
    void DisableRespawnPointVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			DisableForPlayer(Player, Instigator);
    }

	/**
	 * Enable the respawn point volume with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Death Volume")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			EnableRespawnPointVolume(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Respawn Point Volume")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Respawn Point Volume")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Respawn Point Volume")
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

	// Check if any respawn points referenced by this volume can ever be used by the indicated player
	bool HasRespawnPointsUsableBy(EHazePlayer Player) const
	{
		for (auto RespawnPoint : EnabledRespawnPoints)
		{
			if (RespawnPoint == nullptr)
				continue;

			if (Player == EHazePlayer::Mio)
			{
				if (RespawnPoint.bCanMioUse)
					return true;
			}
			else
			{
				if (RespawnPoint.bCanZoeUse)
					return true;
			}
		}

		return false;
	}

    void EnableRespawnPoints(AHazePlayerCharacter Player)
    {
        for (auto RespawnPoint : EnabledRespawnPoints)
		{
			if (RespawnPoint != nullptr)
				RespawnPoint.EnableForPlayer(Player, this);
		}
    }

    void DisableRespawnPoints(AHazePlayerCharacter Player)
    {
        for (auto RespawnPoint : EnabledRespawnPoints)
		{
			if (RespawnPoint != nullptr)
				RespawnPoint.DisableForPlayer(Player, this);
		}
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		// Apply start disabled
		if (bStartDisabled)
		{
			for (auto& PlayerData : PerPlayerData)
				PlayerData.DisableInstigators.AddUnique(StartDisabledInstigator);
		}
    }

    void UpdateAlreadyInsidePlayers()
    {
		// Disable respawn points for players that are inside but no longer enabled
        for (auto Player : Game::Players)
        {
			const auto& PlayerData = PerPlayerData[Player];
			bool bEnabledForPlayer = IsEnabledForPlayer(Player);
            if (!bEnabledForPlayer)
            {
				if (PlayerData.bIsPlayerInside)
                	ReceiveEndOverlap(Player);
					
                if (bSticky)
					ApplyRemoveRespawnPointVolumeSticky(Player, this);
            }
			else
			{
				if (!PlayerData.bIsPlayerInside)
				{
					if (Player.CapsuleComponent.TraceOverlappingComponent(BrushComponent))
						ReceiveBeginOverlap(Player);
				}
			}
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		ReceiveBeginOverlap(OtherActor);
    }

	protected bool ShouldPlayerStateAllowTrigger(AHazePlayerCharacter Player) const
	{
		if (bOnlyTriggerWhenPlayerGrounded && bSticky && !Player.IsOnWalkableGround())
			return false;
		return true;
	}

	protected void ReceiveBeginOverlap(AActor OtherActor)
	{
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;
		// Ignore volumes that don't have any usable respawn points for this player
		if (!HasRespawnPointsUsableBy(Player.Player))
			return;

		auto& PlayerData = PerPlayerData[Player];

        // Don't double trigger volume enters
        if (PlayerData.bIsPlayerInside)
            return;
		PlayerData.bIsPlayerInside = true;
		PlayerData.bPlayerTriggeredOverlap = false;

		if (bTriggerDisabled)
			return;
		if (!bSharedByBothPlayers && bOnlyTriggerOnce_NonShared && bSticky && PlayerData.bHasBeenTriggeredByPlayer)
			return;

		if (!ShouldPlayerStateAllowTrigger(Player))
		{
			SetActorTickEnabled(true);
			return;
		}

		PlayerData.bPlayerTriggeredOverlap = true;
		TriggerOverlapped(Player);
	}

	private void TriggerOverlapped(AHazePlayerCharacter Player)
	{
		TriggerEnter(Player);

		if (bSharedByBothPlayers)
		{
			TriggerEnter(Player.OtherPlayer);

			// Disable triggering this volume if in sticky single-trigger mode
			if (bSticky && bSharedByBothPlayers && bOnlyTriggerOnce)
				bTriggerDisabled = true;
		}
	}

	void TriggerEnter(AHazePlayerCharacter Player)
	{
        if (bSticky)
			ApplyEnterStickyRespawnPointVolume(Player, this);

		PerPlayerData[Player].bHasBeenTriggeredByPlayer = true;
        EnableRespawnPoints(Player);

		for (ARespawnPointVolume BacktrackVolume : DisableBacktrackingToVolumes)
		{
			if (IsValid(BacktrackVolume))
				BacktrackVolume.DisableForPlayer(Player, this);
		}
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void Tick(float DeltaSeconds)
	{
		bool bAnyPlayerInside = false;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto& PlayerData = PerPlayerData[Player];
			if (PlayerData.bIsPlayerInside && !PlayerData.bPlayerTriggeredOverlap)
			{
				bAnyPlayerInside = true;

				if (bTriggerDisabled)
					continue;
				if (!bSharedByBothPlayers && bOnlyTriggerOnce_NonShared && bSticky && PlayerData.bHasBeenTriggeredByPlayer)
					continue;
				if (!IsEnabledForPlayer(Player))
					continue;

				if (ShouldPlayerStateAllowTrigger(Player))
				{
					PlayerData.bPlayerTriggeredOverlap = true;
					TriggerOverlapped(Player);
				}
			}
		}

		if (!bAnyPlayerInside)
			SetActorTickEnabled(false);
	}

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		ReceiveEndOverlap(OtherActor);
    }

	protected void ReceiveEndOverlap(AActor OtherActor)
	{
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

		auto& PlayerData = PerPlayerData[Player];

        // Can't leave the volume if we were never in it
        if (!PlayerData.bIsPlayerInside)
            return;
		PlayerData.bIsPlayerInside = false;

		if (bSharedByBothPlayers)
		{
			if (!PerPlayerData[0].bIsPlayerInside && !PerPlayerData[1].bIsPlayerInside)
			{
				TriggerExit(Player);
				TriggerExit(Player.OtherPlayer);
			}
		}
		else
		{
			TriggerExit(Player);
		}
	}

	void TriggerExit(AHazePlayerCharacter Player)
	{
		if (!bSticky)
			DisableRespawnPoints(Player);
	}
};

// Dummy comp for the visualizer
class URespawnPointVolumeVisualizerComponent : UActorComponent {}

struct FRespawnPointVolumePerPlayerData
{
	bool bIsPlayerInside = false;
	bool bPlayerTriggeredOverlap = false;
	bool bHasBeenTriggeredByPlayer = false;
	TArray<FInstigator> DisableInstigators;
};
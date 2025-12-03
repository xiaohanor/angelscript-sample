
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement))
class AInverseDeathVolume : AVolume
{
	default BrushComponent.LineThickness = 2.0;

	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.0, 1.0));

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	/* Whether the death volume should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Inverse Death Volume", AdvancedDisplay)
    bool bKillsMio = true;

	/* Whether the death volume should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Inverse Death Volume", AdvancedDisplay)
    bool bKillsZoe = true;

	/* Whether to disable the death volume by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Inverse Death Volume", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the death volume enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Inverse Death Volume", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Inverse Death Volume")
	TSubclassOf<UDeathEffect> DeathEffect;

    private TPerPlayer<FDeathVolumePerPlayerData> PerPlayerData;

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		for(auto Player : Game::Players)
		{
			if (IsOverlappingActor(Player))
			{
				InverseDeathVolume::EnterVolume(this, Player);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(auto Player : Game::Players)
		{
			InverseDeathVolume::ExitVolume(this, Player, false);
		}
	}

    UFUNCTION(Category = "Inverse Death Volume")
    void EnableDeathVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
		{
			EnableForPlayer(Player, Instigator);
		}
    }

    UFUNCTION(Category = "Inverse Death Volume")
    void DisableDeathVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
		{
			DisableForPlayer(Player, Instigator);
		}
    }

	/**
	 * Enable the death volume with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Inverse Death Volume")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			EnableDeathVolume(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Inverse Death Volume")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabledForPlayer(Player);

		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);

		// If we become enabled for a player, and it is already inside, kill the player
		if (!bWasEnabled && IsEnabledForPlayer(Player))
		{
			if (IsOverlappingActor(Player))
			{
				InverseDeathVolume::EnterVolume(this, Player);
			}
		}
	}

	UFUNCTION(Category = "Inverse Death Volume")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
		InverseDeathVolume::ExitVolume(this, Player, false);
	}

	UFUNCTION(Category = "Inverse Death Volume")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
		{
			if (!bKillsMio)
				return false;
		}
		else
		{
			if (!bKillsZoe)
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
			DisableDeathVolume(StartDisabledInstigator);
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;

		InverseDeathVolume::EnterVolume(this, Player);
    }

	
	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;

		InverseDeathVolume::ExitVolume(this, Player, true);
	}
};

namespace InverseDeathVolume
{
	UInverseDeathVolumeManager GetManager()
	{
		return UInverseDeathVolumeManager::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintCallable)
	void ClearInverseDeathVolumes(AHazePlayerCharacter Player)
	{
		UInverseDeathVolumeManager Manager = InverseDeathVolume::GetManager();
		Manager.InverseDeathVolumes[Player].Set.Empty();
	}

	void EnterVolume(AInverseDeathVolume Volume, AHazePlayerCharacter Player)
	{
		UInverseDeathVolumeManager Manager = InverseDeathVolume::GetManager();
		Manager.InverseDeathVolumes[Player].Set.Add(Volume);
	}

	void ExitVolume(AInverseDeathVolume Volume, AHazePlayerCharacter Player, bool bCanKill)
	{
		UInverseDeathVolumeManager Manager = InverseDeathVolume::GetManager();
		if(!Manager.InverseDeathVolumes[Player].Set.Remove(Volume))
			return;
		
		if(bCanKill && Manager.InverseDeathVolumes[Player].Set.IsEmpty())
			Player.KillPlayer(DeathEffect = Volume.DeathEffect);
	}
}
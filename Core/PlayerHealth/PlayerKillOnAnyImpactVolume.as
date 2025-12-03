/**
 * If a player is inside this volume and impacts _anything_, they die.
 * 
 * Any impact whatsoever will trigger it, be it floors, walls, or ceilings.
 */
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class APlayerKillOnAnyImpactVolume : AVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default BrushComponent.LineThickness = 2.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.00, 0.49, 0.08));

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	/* Whether the death volume should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Volume", AdvancedDisplay)
    bool bKillsMio = true;

	/* Whether the death volume should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Volume", AdvancedDisplay)
    bool bKillsZoe = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Volume", AdvancedDisplay)
	bool bIsFallingDeath = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Settings")
	float ForceScale = 1.0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Settings")
	bool bApplyStaticCamera = false;

	UPROPERTY(EditAnywhere, EditAnywhere, Category = "Death Settings", Meta = (EditCondition = "!bApplyStaticCamera", EditConditionHides))
	float CameraStopDuration = FPlayerDeathDamageParams().CameraStopDuration;

	/* Whether to disable the death volume by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Volume", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the death volume enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Volume", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Volume")
	TSubclassOf<UDeathEffect> DeathEffect;

    private TPerPlayer<FDeathVolumePerPlayerData> PerPlayerData;

    UFUNCTION(Category = "Death Volume")
    void EnableDeathVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			EnableForPlayer(Player, Instigator);
    }

    UFUNCTION(Category = "Death Volume")
    void DisableDeathVolume(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			DisableForPlayer(Player, Instigator);
    }

	/**
	 * Enable the death volume with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Death Volume")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			EnableDeathVolume(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Death Volume")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabledForPlayer(Player);

		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);

		// If we become enabled for a player, and it is already inside, kill the player
		if (!bWasEnabled && IsEnabledForPlayer(Player))
		{
			if (IsOverlappingActor(Player))
				Player.KillPlayer(DeathEffect = DeathEffect);
		}
	}

	UFUNCTION(Category = "Death Volume")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION(Category = "Death Volume")
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
		
		SetActorTickEnabled(true);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bKeepTicking = false;
		for (auto Player : Game::Players)
		{
			if (IsEnabledForPlayer(Player) && Player.IsOverlappingActor(this))
			{
				bKeepTicking = true;

				auto MoveComp =UHazeMovementComponent::Get(Player);
				if (MoveComp.HasAnyValidBlockingImpacts())
				{
					FPlayerDeathDamageParams DeathParams;
					DeathParams.bIsFallingDeath = bIsFallingDeath;
					DeathParams.ForceScale = ForceScale;
					DeathParams.bApplyStaticCamera = bApplyStaticCamera;
					DeathParams.CameraStopDuration = CameraStopDuration;
					Player.KillPlayer(DeathParams, DeathEffect = DeathEffect);
				}
			}
		}

		if (!bKeepTicking)
			SetActorTickEnabled(false);
	}
};
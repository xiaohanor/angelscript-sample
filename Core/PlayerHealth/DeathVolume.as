
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement))
class ADeathVolume : AVolume
{
	default BrushComponent.LineThickness = 2.0;

	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
    default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.0, 0.0, 1.0));

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
		
		FPlayerDeathDamageParams DeathParams;
		DeathParams.bIsFallingDeath = bIsFallingDeath;
		float CustomMultiplier = 1.0;

		if (!bIsFallingDeath)
		{
			FVector CenterLoc = Player.ActorCenterLocation;
			FVector CollisionPoint;
			float Distance = BrushComponent.GetClosestPointOnCollision(CenterLoc, CollisionPoint);
			FVector DirectionToImpact = (CollisionPoint - CenterLoc).GetSafeNormal();
			
			if (Distance <= 0.0)
			{
				CenterLoc -= Player.ActorVelocity.GetSafeNormal() * 250.0; 
				Distance = BrushComponent.GetClosestPointOnCollision(CenterLoc, CollisionPoint);
				DeathParams.ImpactDirection = DirectionToImpact;
			}
			if (Distance > 0.0)
			{
				DeathParams.ImpactDirection = -DirectionToImpact;
			}

			CustomMultiplier = 3.0;
		}
		else
		{
			DeathParams.ImpactDirection = Player.ActorVelocity.GetSafeNormal();
		}

		DeathParams.ForceScale = ForceScale * CustomMultiplier;
		DeathParams.bApplyStaticCamera = bApplyStaticCamera;
		DeathParams.CameraStopDuration = CameraStopDuration;
		Player.KillPlayer(DeathParams, DeathEffect = DeathEffect);
    }
};

struct FDeathVolumePerPlayerData
{
	TArray<FInstigator> DisableInstigators;
};
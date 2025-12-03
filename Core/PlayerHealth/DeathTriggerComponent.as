class UDeathTriggerComponent : UHazeMovablePlayerTriggerComponent
{
#if EDITOR
	default ShapeColor = FLinearColor::Red;
#endif

	/* Whether the death trigger should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger", AdvancedDisplay)
    bool bKillsMio = true;

	/* Whether the death trigger should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger", AdvancedDisplay)
    bool bKillsZoe = true;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger")
	float ForceScale = 5.0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger")
	float CameraStopDuration = FPlayerDeathDamageParams().CameraStopDuration;

	/* Whether to disable the death trigger by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Trigger", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Instigator to disable with if the death trigger enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Trigger", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Trigger")
	TSubclassOf<UDeathEffect> DeathEffect;

    private TPerPlayer<FDeathTriggerPerPlayerData> PerPlayerData;

    UFUNCTION(Category = "Death Trigger")
    void EnableDeathTrigger(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			EnableForPlayer(Player, Instigator);
    }

    UFUNCTION(Category = "Death Trigger")
    void DisableDeathTrigger(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			DisableForPlayer(Player, Instigator);
    }

	/**
	 * Enable the death trigger with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Death Trigger")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			EnableDeathTrigger(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Death Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabledForPlayer(Player);

		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);

		// If we become enabled for a player, and it is already inside, kill the player
		if (!bWasEnabled && IsEnabledForPlayer(Player))
		{
			if (PerPlayerData[Player].bIsPlayerInside)
				Player.KillPlayer(DeathEffect = DeathEffect);
		}
	}

	UFUNCTION(Category = "Death Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION(Category = "Death Trigger")
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
			DisableDeathTrigger(StartDisabledInstigator);
    }

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		PerPlayerData[Player].bIsPlayerInside = true;
        
		if (IsEnabledForPlayer(Player))
		{
			FPlayerDeathDamageParams DeathParams;
			DeathParams.CameraStopDuration = CameraStopDuration;

			FVector CenterLoc = Player.ActorCenterLocation;
			FVector CollisionPoint = Shape.GetClosestPointToPoint(WorldTransform, CenterLoc);
			float Distance = CollisionPoint.Distance(CenterLoc);
			FVector DirectionToImpact = (CollisionPoint - CenterLoc).GetSafeNormal();
			
			if (Distance <= 0.0)
			{
				CenterLoc -= Player.ActorVelocity.GetSafeNormal() * 250.0; 
				CollisionPoint = Shape.GetClosestPointToPoint(WorldTransform, CenterLoc);
				Distance = CollisionPoint.Distance(CenterLoc);
				DeathParams.ImpactDirection = DirectionToImpact;
			}
			if (Distance > 0.0)
			{
				DeathParams.ImpactDirection = -DirectionToImpact;
			}
			
			DeathParams.ForceScale = ForceScale;
			Player.KillPlayer(DeathParams, DeathEffect = DeathEffect);
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		PerPlayerData[Player].bIsPlayerInside = false;
	}
}

struct FDeathTriggerPerPlayerData
{
	TArray<FInstigator> DisableInstigators;
	bool bIsPlayerInside = false;
};
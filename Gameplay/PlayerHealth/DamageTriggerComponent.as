event void FOnPlayerDamagedByTrigger(AHazePlayerCharacter Player);

class UDamageTriggerComponent : UHazeMovablePlayerTriggerComponent
{
#if EDITOR
	default ShapeColor = FLinearColor::Red;
#endif

	// How much damage should be dealt to players that enter the damage trigger
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Trigger")
    float DamageAmount = 0.5;

	// How long between damage hits while the player is inside the damage trigger
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Trigger", AdvancedDisplay)
    float DamageInterval = 1.0;

	/* Whether the damage trigger should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Trigger", AdvancedDisplay)
    bool bDamagesMio = true;

	/* Whether the damage trigger should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Damage Trigger", AdvancedDisplay)
    bool bDamagesZoe = true;

	/* Whether to disable the damage trigger by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Damage Trigger", Meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Whether to apply the damage as batched Damage over Time */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Damage Trigger", AdvancedDisplay)
	bool bApplyAsDamageOverTime = false;

	/* Instigator to disable with if the damage trigger enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Damage Trigger", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	/* Damage effect to play when this damages a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Damage Trigger")
	TSubclassOf<UDamageEffect> DamageEffect;

	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Damage Trigger")
	TSubclassOf<UDeathEffect> DeathEffect;

	/* Whether to apply a knockback impulse to the player when hit by the trigger */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse")
	bool bApplyKnockbackImpulse = false;

	/* How strong the horizontal knockback impulse is */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse", Meta = (EditCondition = "bApplyKnockbackImpulse", EditConditionHides))
	float HorizontalKnockbackStrength = 900.0;

	/* How strong the vertical knockback impulse is */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse", Meta = (EditCondition = "bApplyKnockbackImpulse", EditConditionHides))
	float VerticalKnockbackStrength = 1200.0;

	/**
	 * Blend the knockback direction.
	 * At value 0.0, the knockback direction sends the player directly away from the trigger.
	 * At value 1.0, the knockback direction sends the player in the forward vector of the trigger.
	 * At values inbetween, the direction blends.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse", Meta = (EditCondition = "bApplyKnockbackImpulse", EditConditionHides))
	float KnockbackForwardDirectionBlend = 0.0;

	/** Whether to weaken the player's air control temporarily after the knockback. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse", Meta = (EditCondition = "bApplyKnockbackImpulse", EditConditionHides))
	bool bWeakenAirControlAfterKnockback = true;

	/** Duration to weaken the player's air control for after knockback */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockback Impulse", Meta = (EditCondition = "bApplyKnockbackImpulse && bWeakenAirControlAfterKnockback", EditConditionHides))
	float WeakenAirControlDuration = 0.6;

	/* Whether to apply a knockdown to the player when hit */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockdown")
	bool bApplyKnockdown = false;

	/** Strength of the knockdown */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockdown", Meta = (EditCondition = "bApplyKnockdown", EditConditionHides))
	float KnockdownStrength = 100.0;

	/** Duration of the knockdown */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Knockdown", Meta = (EditCondition = "bApplyKnockdown", EditConditionHides))
	float KnockdownDuration = 1.0;

	/* Whether to apply a stumble to the player when hit */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Stumble")
	bool bApplyStumble = false;

	/** Strength of the stumble */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Stumble", Meta = (EditCondition = "bApplyStumble", EditConditionHides))
	float StumbleStrength = 100.0;

	/** Duration of the stumble */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Stumble", Meta = (EditCondition = "bApplyStumble", EditConditionHides))
	float StumbleDuration = 0.5;

	UPROPERTY()
	FOnPlayerDamagedByTrigger OnPlayerDamagedByTrigger;

    private TPerPlayer<FDamageTriggerPerPlayerData> PerPlayerData;

    UFUNCTION(Category = "Damage Trigger")
    void EnableDamageTrigger(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			EnableForPlayer(Player, Instigator);
    }

    UFUNCTION(Category = "Damage Trigger")
    void DisableDamageTrigger(FInstigator Instigator)
    {
		for (auto Player : Game::Players)
			DisableForPlayer(Player, Instigator);
    }

	/**
	 * Enable the damage trigger with the instigator set as the start disabled instigator.
	 */
	UFUNCTION(Category = "Damage Trigger")
	void EnableAfterStartDisabled()
	{
		if (bStartDisabled)
			EnableDamageTrigger(StartDisabledInstigator);
	}

	UFUNCTION(Category = "Damage Trigger")
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		bool bWasEnabled = IsEnabledForPlayer(Player);

		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.Remove(Instigator);

		// If we become enabled for a player, and it is already inside, kill the player
		if (!bWasEnabled && IsEnabledForPlayer(Player))
		{
			if (PerPlayerData[Player].bIsPlayerInside)
				CheckDealDamage(Player);
		}
	}

	UFUNCTION(Category = "Damage Trigger")
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto& PlayerData = PerPlayerData[Player];
		PlayerData.DisableInstigators.AddUnique(Instigator);
	}

	UFUNCTION(Category = "Damage Trigger")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player.IsMio())
		{
			if (!bDamagesMio)
				return false;
		}
		else
		{
			if (!bDamagesZoe)
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
			DisableDamageTrigger(StartDisabledInstigator);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PerPlayerData[Player].bIsPlayerInside)
				CheckDealDamage(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		PerPlayerData[Player].bIsPlayerInside = true;
		CheckDealDamage(Player);

		SetComponentTickEnabled(true);
	}

	private void CheckDealDamage(AHazePlayerCharacter Player)
	{
        if (IsEnabledForPlayer(Player))
		{
			if (Time::GetGameTimeSince(PerPlayerData[Player].LastDamageTime) >= DamageInterval)
			{
				PerPlayerData[Player].LastDamageTime = Time::GameTimeSeconds;
				OnPlayerDamagedByTrigger.Broadcast(Player);

				if (bApplyAsDamageOverTime)
					Player.DealBatchedDamageOverTime(DamageAmount, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
				else
					Player.DamagePlayerHealth(DamageAmount, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);

				FVector WorldUp = Player.MovementWorldUp;
				FVector AwayDirection = (Player.ActorLocation - WorldLocation).ConstrainToPlane(WorldUp).GetNormalizedWithFallback(-Player.ActorForwardVector);
				FVector ForwardDirection = ForwardVector.ConstrainToPlane(WorldUp).GetSafeNormal();

				if (bApplyKnockbackImpulse)
				{
					FVector KnockDirection = Math::Lerp(AwayDirection, ForwardDirection, KnockbackForwardDirectionBlend);
					Player.AddKnockbackImpulse(
						KnockDirection, HorizontalKnockbackStrength, VerticalKnockbackStrength,
						bWeakenAirControlAfterKnockback ? WeakenAirControlDuration : 0.0,
					);
				}

				if (bApplyKnockdown)
				{
					Player.ApplyKnockdown(AwayDirection * KnockdownStrength, KnockdownDuration);
				}

				if (bApplyStumble)
				{
					Player.ApplyStumble(AwayDirection * StumbleStrength, StumbleDuration);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		PerPlayerData[Player].bIsPlayerInside = false;
		if (!PerPlayerData[Player.OtherPlayer].bIsPlayerInside)
			SetComponentTickEnabled(false);
	}
}

struct FDamageTriggerPerPlayerData
{
	TArray<FInstigator> DisableInstigators;
	float LastDamageTime = -1e10;
	bool bIsPlayerInside = false;
};
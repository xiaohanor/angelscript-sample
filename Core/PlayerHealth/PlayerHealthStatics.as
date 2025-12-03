
UFUNCTION(Category = "Player Health", meta=(DeprecatedFunction, DeprecationMessage="This will be removed once we have buttonmash respawn functionallity"))
mixin float GetTimeBetweenRespawnStartedAndFinished(AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);

	if(HealthComp == nullptr)
		return 0.0;

	if(HealthComp.HealthSettings == nullptr)
		return 0.0;

	return 	HealthComp.HealthSettings.RespawnBlackScreenDuration +
			// HealthComp.HealthSettings.RespawnFadeInDuration +
			HealthComp.HealthSettings.RespawnFadeOutDuration;
}

/**
 * Immediately kill the player and force them to respawn.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DeathEffect"))
mixin void KillPlayer(AHazePlayerCharacter Player, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams(), TSubclassOf<UDeathEffect> DeathEffect = nullptr)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.KillPlayer(DeathParams, DeathEffect);

#if EDITOR
	UObject InstigatorObject = nullptr;
	for(int i = 0; i < 10; i++)
	{
		InstigatorObject = Debug::EditorGetAngelscriptStackFrameObject(i);

		if(InstigatorObject == nullptr)
			continue;

		if(InstigatorObject == HealthComp)
			continue;

		break;
	}

	if(InstigatorObject != nullptr)
	{
		UActorComponent Component = Cast<UActorComponent>(InstigatorObject);
		if(Component != nullptr)
		{
			TEMPORAL_LOG(HealthComp).Value(f"Kill Instigator", f"Component: {Component.ToString()}\nActor: {Component.Owner}");
		}
		else
		{
			TEMPORAL_LOG(HealthComp).Value(f"Kill Instigator", f"{InstigatorObject.ToString()}");
		}
	}
#endif
}

/**
 * Whether the player is currently dead and awaiting respawn.
 * Note that the player might not be dead while respawning.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DeathEffect"))
mixin bool IsPlayerDead(const AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	return HealthComp.bIsDead;
}

/**
 * Whether the player is currently respawning.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DeathEffect"))
mixin bool IsPlayerRespawning(const AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	return HealthComp.bIsRespawning;
}

/**
 * Whether the player is currently dead or respawning.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DeathEffect"))
mixin bool IsPlayerDeadOrRespawning(const AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	return HealthComp.bIsDead || HealthComp.bIsRespawning;
}

/**
 * Deal damage to the player. Can kill the player if the player's health runs out.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DamageEffect, DeathEffect"))
mixin void DamagePlayerHealth(AHazePlayerCharacter Player, float Damage, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams(),TSubclassOf<UDamageEffect> DamageEffect = nullptr, TSubclassOf<UDeathEffect> DeathEffect = nullptr, bool bApplyInvulnerability = true)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.DamagePlayer(Damage, DamageEffect, DeathEffect, bApplyInvulnerability, DeathParams);
}

/**
 * Heal the player for a set amount of health.
 */
UFUNCTION(Category = "Player Health")
mixin void HealPlayerHealth(AHazePlayerCharacter Player, float HealAmount)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.HealPlayer(HealAmount);
}

/**
 * Add a damage invulnerability to the player.
 * This prevents the player from taking damage, but they will still die when KillPlayer is called!
 * 
 * If MaximumDuration is larger than 0 the invulnerability will automatically expire when the maximum duration is reached.
 */
UFUNCTION(Category = "Player Health", DisplayName = "Add Player Damage Invulnerability")
mixin void AddDamageInvulnerability(AHazePlayerCharacter Player, FInstigator Instigator, float MaxDuration = -1.0)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.AddDamageInvulnerability(Instigator, MaxDuration, false);
}

/**
 * Remove a previously instigated damage invulnerability from the player.
 */
UFUNCTION(Category = "Player Health", DisplayName = "Remove Player Damage Invulnerability")
mixin void RemoveDamageInvulnerability(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.RemoveDamageInvulnerability(Instigator);
}

/**
 * Whether the player is currently invulnerable and won't take damage when hit.
 */
UFUNCTION(Category = "Player Health")
mixin bool IsPlayerInvulnerable(AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	return !HealthComp.CanTakeDamage();
}

/**
 * Get the current god mode status for the player.
 */
UFUNCTION(Category = "Player Health", DisplayName = "Get Player God Mode")
mixin EGodMode GetGodMode(AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	return HealthComp.GodMode;
}

/**
 * Deal damage to the player that gets applied over time.
 * This allows for damage to be done on tick without spamming network messages.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DamageEffect, DeathEffect", DisplayName = "Player Deal Batched Damage Over Time"))
mixin void DealBatchedDamageOverTime(AHazePlayerCharacter Player, float Damage, FPlayerDeathDamageParams DeathParams, TSubclassOf<UDamageEffect> DamageEffect = nullptr, TSubclassOf<UDeathEffect> DeathEffect = nullptr)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.DealBatchedDamage(Damage, DeathParams, DamageEffect, DeathEffect);
}

namespace PlayerHealth
{

bool AreAllPlayersDead()
{
	for (AHazePlayerCharacter Player : Game::Players)
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
		if ((HealthComp != nullptr) && !HealthComp.bIsDead)
			return false;
	}
	return true;
}

/**
 * Trigger the player to respawn now, without waiting for the normal respawn timer.
 * This will still go through the normal respawn effect and fades.
 * The player will respawn at the nearest respawn point that they would normally respawn at.
 * 
 * Has no effect if the player is not dead.
 * Has no effect if respawn timers are not enabled.
 */
UFUNCTION(Category = "Player Health")
void RespawnPlayerSkipTimer(AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.TriggerRespawn(false);
}

/**
* Trigger the player to respawn instantly, skipping and interrupting any death effects,
* respawn effects, fade ins and fade outs.
* 
* The player will snap ressurect in place exactly where it died!
* Should only be used when taking control of the player, for example teleporting it or putting
* it in a cutscene.
* 
* Has no effect if the player is not dead.
*/
UFUNCTION(Category = "Player Health")
void ForceRespawnPlayerInstantly(AHazePlayerCharacter Player)
{
	auto HealthComp = UPlayerHealthComponent::Get(Player);
	HealthComp.TriggerRespawn(true);
}

/**
 * Kill any players that are currently in the specified radius.
 */
UFUNCTION(Category = "Player Health")
void KillPlayersInRadius(FVector Location, float Radius, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams(), TSubclassOf<UDeathEffect> DeathEffect = nullptr)
{
	for (AHazePlayerCharacter Player : Game::Players)
	{
		if (Overlap::QueryShapeOverlap(
			Player.CapsuleComponent.GetCollisionShape(),
			Player.CapsuleComponent.WorldTransform,
			FCollisionShape::MakeSphere(Radius),
			FTransform(Location),
		))
		{
			Player.KillPlayer(DeathParams, DeathEffect);
		}
	}
}

/**
 * Damage any players that are currently in the specified radius.
 */
UFUNCTION(Category = "Player Health")
void DamagePlayersInRadius(FVector Location, float Radius, float DamageAmount, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams(), TSubclassOf<UDamageEffect> DamageEffect = nullptr, TSubclassOf<UDeathEffect> DeathEffect = nullptr)
{
	for (AHazePlayerCharacter Player : Game::Players)
	{
		if (Overlap::QueryShapeOverlap(
			Player.CapsuleComponent.GetCollisionShape(),
			Player.CapsuleComponent.WorldTransform,
			FCollisionShape::MakeSphere(Radius),
			FTransform(Location),
		))
		{
			Player.DamagePlayerHealth(DamageAmount, DeathParams, DamageEffect, DeathEffect);
		}
	}
}

/**
 * Immediately trigger a game over state, which will restart the game from the latest save after playing the fade out.
 */
UFUNCTION(Category = "Player Health", Meta = (AdvancedDisplay = "DeathEffect"))
void TriggerGameOver()
{
	if (!Network::HasWorldControl())
		return;

	auto HealthComp = UPlayerHealthComponent::Get(Game::FirstLocalPlayer);
	HealthComp.TriggerGameOver();
}

/**
 * Check whether the player are currently in a game over state waiting to restart.
 */
UFUNCTION(BlueprintPure, Category = "Player Health")
bool ArePlayersGameOver()
{
	auto HealthComp = UPlayerHealthComponent::Get(Game::Mio);
	return HealthComp.bIsGameOver;
}

}

class UPlayerHealthSettings : UHazeComposableSettings
{
	// Whether to display the player's health on screen
	UPROPERTY(Category = "Health")
	bool bDisplayHealth = false;

	// How long for the player to be invulnerable after taking damage.
	UPROPERTY(Category = "Health")
	float InvulnerabilityDurationAfterTakingDamage = 1.2;

	// Player will get a single grace period for this long when they would otherwise have been killed by damage. If 0, they die immediately. Damage ignoring invulnerability also ignores this.
	UPROPERTY(Category = "Health")
	float SecondChanceWhenKilledDuration = 0.0;

	// Whether to display the health bar when the player is currently full health (requires bDisplayHealth to be true)
	UPROPERTY(Category = "Health", AdvancedDisplay)
	bool bDisplayHealthWhenFullHealth = true;

	// Whether to regenerate the player's health when they haven't taken damage for a while
	UPROPERTY(Category = "Regeneration")
	bool bRegenerateHealth = true;

	// Delay until regeneration kicks in
	UPROPERTY(Category = "Regeneration")
	float RegenerationDelay = 5.0;

	// Whether to trigger a game over when both players are dead
	UPROPERTY(Category = "Game Over")
	bool bGameOverWhenBothPlayersDead = false;

	// Amount of time spent fading out the screen during respawn
	UPROPERTY(Category = "Effects")
	TSubclassOf<UDeathEffect> DefaultDeathEffect;

	// Amount of time spent fading out the screen during respawn
	UPROPERTY(Category = "Effects")
	TSubclassOf<UDamageEffect> DefaultDamageEffect;

	// Enable the respawn timer delay after the player dies
	UPROPERTY(Category = "Respawn")
	bool bEnableRespawnTimer = false;

	// How long the player must wait when dead before respawning
	UPROPERTY(Category = "Respawn")
	float RespawnTimer = 10.0;

	// Allow the player to speed up the respawn by button mashing
	UPROPERTY(Category = "Respawn")
	bool bRespawnTimerButtonMash = true;

	// How long for the player to be invulnerable after respawning
	UPROPERTY(Category = "Respawn")
	float InvulnerabilityDurationAfterRespawning = 2.0;

	// How many times pre second we should mash to reach the fastest respawn rate
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	float RespawnMashRequiredMashRate = 7.0;

	// When mashing the required amount during respawn, speed up the respawn timer by this multiplier
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	float RespawnMashMaxSpeedMultiplier = 4.0;

	// Amount of time spent fading out the screen during respawn
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	float RespawnFadeOutDuration = 0.5;

	// Amount of time spent faded out during respawn
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	float RespawnBlackScreenDuration = 0.5;

	// Amount of time fading in the screen after respawn
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	float RespawnFadeInDuration = 0.25;

	// Block the player from respawning when no respawn points are available
	UPROPERTY(Category = "Respawn")
	bool bBlockRespawnWhenNoRespawnPointsEnabled = false;

	// Fade the screen out and back in during respawn even when the game is currently in fullscreen
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	bool bFadeOutEvenInFullscreen = false;

	// Make the view size smaller for the player that died while they are waiting for the respawn timer
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	bool bReduceViewSizeForDeadPlayer = true;

	// Show the respawn timers at the top of the screen when dying in fullscreen
	UPROPERTY(Category = "Respawn", AdvancedDisplay)
	bool bShowRespawnTimerAtTheTopInFullscreen = true;
};
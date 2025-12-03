
class UBasicAITeleporterSettings : UHazeComposableSettings
{
	// To within which range do we try to teleport?
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChaseMinRange = 200.0;

	// How much time we spend telegraphing teleport before disappearing
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChaseTelegraphDuration = 0.5;

	// Duration between vanishing and reappearing at teleport destination
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChaseReappearDuration = 0.5;

	// Duration after reappearing where we just play out reappear animation before lower priority behaviour can take over
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChasePostAppearanceDuration = 0.5;

	// Maximum scatter in degrees from ideal direction where we try to appear.
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChaseScatter = 30.0;

	// How often we're allowed to teleport when chasing 
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportChaseCooldown = 3.0;

	// To what range from target do we try to teleport?
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportRetreatRange = 800.0;

	// How much time we spend telegraphing teleport before disappearing
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportRetreatTelegraphDuration = 0.0;

	// Duration between vanishing and reappearing at teleport destination
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportRetreatReappearDuration = 0.5;

	// Maximum scatter in degrees from ideal direction where we try to appear.
	UPROPERTY(Category = "Combat|TeleportChase")
	float TeleportRetreatScatter = 60.0;
}

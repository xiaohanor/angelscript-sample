class UStoneBeastPlayerRespawnSettings : UHazeComposableSettings
{
	// Positive value == spawn ahead of other player, negative value == spawn behind
	UPROPERTY()
	float RespawnDistance = 400;
}
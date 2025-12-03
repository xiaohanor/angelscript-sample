class UIslandArenaRespawnPointsDevTogglesCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandArenaRespawnPointsManagerDevToggles::ArenaRespawnPointsManagerCategory.MakeVisible();

		IslandArenaRespawnPointsManagerDevToggles::EnableDebugDrawing.MakeVisible();
	}
};
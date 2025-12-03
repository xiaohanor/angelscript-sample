class ASplitBonanzaRespawnPoint : ARespawnPoint
{
	default RespawnPriority = ERespawnPointPriority::High;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnableForPlayer(Game::Mio, this);
		EnableForPlayer(Game::Zoe, this);
	}
	
	bool IsValidToRespawn(AHazePlayerCharacter Player) const override
	{
		auto Manager = ASplitBonanzaManager::Get();
		return Manager.IsLevelVisibleAtPosition(Level, ActorLocation);
	}
}
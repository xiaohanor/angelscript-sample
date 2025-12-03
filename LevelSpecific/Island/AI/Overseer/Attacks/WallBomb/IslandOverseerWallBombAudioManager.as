namespace IslandOverseerWallBomb
{
	UIslandOverseerWallBombAudioManager GetAudioManager()
	{
		return UIslandOverseerWallBombAudioManager::GetOrCreate(TListedActors<AAIIslandOverseer>().GetSingle());
	}
}

class UIslandOverseerWallBombAudioManager : UActorComponent
{
	access PrivateWithWallBomb = private, AIslandOverseerWallBomb;

	private TArray<AIslandOverseerWallBomb> DeployedWallBombs;

	bool HasActiveWallBombs() const { return !DeployedWallBombs.IsEmpty(); }
	TArray<AIslandOverseerWallBomb> GetWallBombs() const { return DeployedWallBombs; }

	access:PrivateWithWallBomb void RegisterWallBomb(AIslandOverseerWallBomb WallBomb)
	{
		DeployedWallBombs.Add(WallBomb);
	}

	access:PrivateWithWallBomb void UnRegisterWallBomb(AIslandOverseerWallBomb WallBomb)
	{
		DeployedWallBombs.RemoveSingleSwap(WallBomb);
	}
}
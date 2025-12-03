class UDragonSwordPinnableGroundComponent : UActorComponent
{
	private TPerPlayer<bool> AttachedPlayers;

	void AttachPlayer(AHazePlayerCharacter Player)
	{
		AttachedPlayers[Player] = true;
	}

	void DetachPlayer(AHazePlayerCharacter Player)
	{
		AttachedPlayers[Player] = false;
	}

	bool CheckBothPlayersAttached()
	{
		return AttachedPlayers[Game::Mio] && AttachedPlayers[Game::Zoe];
	}
};
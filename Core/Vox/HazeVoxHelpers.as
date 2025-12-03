
namespace VoxHelpers
{
	bool InGame()
	{
		if (Game::IsInLoadingScreen())
		{
			return false;
		}

		const UHazeLobby Lobby = Lobby::GetLobby();
		if (Lobby == nullptr || !Lobby.HasGameStarted())
		{
			return false;
		}

		return true;
	}

	// Based on TArray::Suffle but using random stream
	void ShuffleIndexArray(TArray<int>& IndexArray, FRandomStream& RandStream)
	{
		const int LastIndex = IndexArray.Num() - 1;
		for (int Index = 0; Index <= LastIndex; ++Index)
		{
			const int OtherIndex = RandStream.RandRange(Index, LastIndex);
			if (OtherIndex != Index)
			{
				IndexArray.Swap(Index, OtherIndex);
			}
		}
	}
}

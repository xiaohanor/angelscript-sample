class ASplitTraversalAudioLevelScriptActor : AAudioLevelScriptActor
{
	UFUNCTION(BlueprintPure)
	ASplitTraversalPlayerCopy GetPlayerCopyForPlayer(AHazePlayerCharacter Player)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if(Manager == nullptr)
			return nullptr;
		
		return Manager.PlayerCopies[Player];
	}
}
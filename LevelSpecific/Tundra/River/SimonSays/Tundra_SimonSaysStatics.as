namespace TundraSimonSays
{
	const FName SimonSaysPerchJump = n"SimonSaysPerchJump";

	UFUNCTION()
	void TundraStartMonkeySimonSays(bool bSnapPlatforms = true)
	{
		ATundra_SimonSaysManager Manager = GetManager();
		if (IsValid(Manager))
			Manager.Activate(bSnapPlatforms);
	}

	UFUNCTION()
	void TundraStopMonkeySimonSays(bool bSnapPlatforms = true)
	{
		ATundra_SimonSaysManager Manager = GetManager();
		if (IsValid(Manager))
			Manager.Deactivate(bSnapPlatforms);
	}

	UFUNCTION()
	int TundraGetCurrentSimonSaysStage()
	{
		ATundra_SimonSaysManager Manager = GetManager();
		if (!IsValid(Manager))
			return -1;
		return Manager.GetCurrentDanceStageIndex();
	}

	ATundra_SimonSaysManager GetManager()
	{
		TListedActors<ATundra_SimonSaysManager> ListedManagers;
		return ListedManagers.Single;
	}

	ETundra_SimonSaysEffectTileType PointIndexToEffectTileType(int PointIndex)
	{
		return ETundra_SimonSaysEffectTileType(PointIndex);
	}
}
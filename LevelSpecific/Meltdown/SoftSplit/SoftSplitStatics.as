namespace SoftSplit
{

	/**
	 * Get the name of the soft split that is being rendered at the world location specified.
	 */
	UFUNCTION(BlueprintPure, Category = "Meltdown | Soft Split")
	EHazeWorldLinkLevel GetVisibleSoftSplitAtLocation(FVector Location)
	{
		auto Manager = ASoftSplitManager::GetSoftSplitManger();
		if (Manager == nullptr)
			return EHazeWorldLinkLevel::SciFi;
		return Manager.GetVisibleSoftSplitAtLocation(Location);
	}

}
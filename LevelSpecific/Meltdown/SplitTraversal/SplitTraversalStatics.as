namespace SplitTraversal
{

	/**
	 * Returns either 'scifi' or 'fantasy' depending on what is actually visible for that location at the moment.
	 */
	UFUNCTION(Category = "Meltdown | Split Traversal")
	FName GetTraversalSplitActiveAtLocation(FVector Location)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (Manager == nullptr)
			return NAME_None;
		return Manager.GetVisibleWorldAtLocation(Location);
	}

}
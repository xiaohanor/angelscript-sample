namespace Sort
{
	void SortByDistanceToLocation(FVector Location, TArray<AHazeActor>& InOutActors)
	{
		TArray<FHazeComponentSortElement> List;
		List.SetNum(InOutActors.Num());
		for (int i = 0; i < InOutActors.Num(); i++)
		{
			List[i].Component = InOutActors[i].RootComponent;
		}

		Sort::SortByDistanceToPoint(List, Location);

		for (int i = 0; i < InOutActors.Num(); i++)
		{
			InOutActors[i] = (List[i].Component != nullptr) ? Cast<AHazeActor>(List[i].Component.Owner) : nullptr;
		}
	}	
}

namespace SkylineBoss
{
	struct FSkylineBossDijkstraNode
	{
		ASkylineBossSplineHub Hub;
		float ShortestPath = MAX_flt;
		ASkylineBossSplineHub FromHub;
	}


	TArray<ASkylineBossSplineHub> GetPathToTarget(ASkylineBossSplineHub AFromHub, ASkylineBossSplineHub AToHub)
	{
		TMap<ASkylineBossSplineHub, FSkylineBossDijkstraNode> Nodes;
		TArray<FSkylineBossDijkstraNode> Visited;
		TArray<FSkylineBossDijkstraNode> Unvisited;

		for(auto Hub : TListedActors<ASkylineBossSplineHub>().Array)
		{
			FSkylineBossDijkstraNode NewNode;
			NewNode.Hub = Hub;
			Nodes.Add(Hub, NewNode);
		}

		Nodes[AFromHub].ShortestPath = 0;
		Unvisited.Add(Nodes[AFromHub]);

		while(!Unvisited.IsEmpty())
		{
			SearchConnectedHubs(Unvisited[0], Nodes, Visited, Unvisited);
			Visited.Add(Unvisited[0]);
			Unvisited.RemoveAt(0);
		}

		TArray<ASkylineBossSplineHub> Path;
		Path.Add(AToHub);
		ASkylineBossSplineHub Previous = Nodes[AToHub].FromHub;
		while(Previous != nullptr)
		{
			Path.Add(Previous);
			Previous = Nodes[Previous].FromHub;
		}

		TArray<ASkylineBossSplineHub> ReversedPath;
		for(int i = Path.Num() - 1; i >= 0; i--)
		{
			ReversedPath.Add(Path[i]);
		}

		return ReversedPath;
	}

	void SearchConnectedHubs(FSkylineBossDijkstraNode& Node, TMap<ASkylineBossSplineHub, FSkylineBossDijkstraNode>& Nodes, TArray<FSkylineBossDijkstraNode> VisitedList, TArray<FSkylineBossDijkstraNode>& UnvisitedList)
	{
		TArray<FSkylineBossDijkstraNode> UnvisitedTemp;

		for(auto ConnectedHub : Node.Hub.ConnectedHubs)
		{
			if(VisitedList.Contains(Nodes[ConnectedHub]))
				continue;

			float Distance = Node.ShortestPath + Node.Hub.GetDistanceTo(ConnectedHub);
			if(Distance < Nodes[ConnectedHub].ShortestPath)
			{
				Nodes[ConnectedHub].ShortestPath = Distance;
				Nodes[ConnectedHub].FromHub = Node.Hub;
			}

			UnvisitedTemp.Add(Nodes[ConnectedHub]);
		}

		for(auto Unvisited : UnvisitedTemp)
			UnvisitedList.Add(Unvisited);
	}
}
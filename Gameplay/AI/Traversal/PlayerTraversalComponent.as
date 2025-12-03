class UPlayerTraversalComponent : UActorComponent
{
	private ATraversalAreaActor AreaActor = nullptr;
	private ATraversalAreaActor PreviousAreaActor = nullptr;
	private ATraversalAreaActor NearbyAreaActor = nullptr;
	private UTraversalScenepointComponent NearbyScenepoint = nullptr;

	void SetCurrentArea(AActor Area)
	{
		if (AreaActor != Area)
			PreviousAreaActor = AreaActor;
		AreaActor = Cast<ATraversalAreaActor>(Area);
	}

	ATraversalAreaActor GetCurrentArea() property
	{
		return AreaActor;
	}

	ATraversalAreaActor GetPreviousArea() property
	{
		return PreviousAreaActor;
	}

	void SetNearbyTraversalpoint(UTraversalScenepointComponent Point)
	{
		NearbyScenepoint = Point;	
		NearbyAreaActor = Cast<ATraversalAreaActor>(Point.Owner);
	}

	UTraversalScenepointComponent GetNearbyPoint() property
	{
		return NearbyScenepoint;
	}

	ATraversalAreaActor GetNearbyArea() property
	{
		if (AreaActor != nullptr)
			return AreaActor;
		return NearbyAreaActor;
	}

	ATraversalAreaActor GetAnyArea() property
	{
		// Fix for player respawning state without respawn points. TODO: Should check if player is in respawning state instead.
		if(Owner.ActorLocation == FVector::ZeroVector)
			return nullptr;

		if(CurrentArea != nullptr)
			return CurrentArea;

		if(PreviousArea != nullptr)
			return PreviousArea;

		if(NearbyArea != nullptr)
			return NearbyArea;

		return nullptr;
	}
}

asset PlayerTraversalSheet of UHazeCapabilitySheet
{
	Components.Add(UPlayerTraversalComponent);
	Capabilities.Add(UPlayerFindTraversalAreaCapability);
}
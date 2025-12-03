class USummitCritterSwarmComponent : UActorComponent
{
	ASummitCritterSwarmAreaActor Area;

	FVector InitialLocation;

	TArray<USummitSwarmingCritterComponent> Critters;
	TArray<USummitSwarmingCritterComponent> UnspawnedCritters;
	float BoundsRadius;

	float AggroTime;

	bool IsAllowedLocation(FVector Location) const
	{
		if (Area == nullptr)
			return true;
		return Area.IsWithin(Location);
	}

	FVector ProjectToArea(FVector Location) const
	{
		if (IsAllowedLocation(Location))
			return Location;
		return Area.ProjectToArea(Location);
	}

	int GetNumberOfGrabbingCritters()
	{
		int NumGrabbers = 0;
		for (USummitSwarmingCritterComponent Critter : Critters)
		{
			if (Critter.ShouldGrabExternalTarget())
				NumGrabbers++;
		}
		return NumGrabbers;
	}
}

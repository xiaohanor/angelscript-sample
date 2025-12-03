class USkylineEnforcerBoundsComponent : UActorComponent
{
	ASkylineEnforcerBoundsVolume CurrentBounds;

	bool LocationIsWithinBounds(FVector Location)
	{
		if(CurrentBounds == nullptr)
			return false;

		// TODO: EncompassesPoint is expensive, possibly replace
		if(CurrentBounds.EncompassesPoint(Location))
			return true;

		return false;
	}

	bool LocationIsWithinBounds(FVector Location, float Radius)
	{
		if(CurrentBounds == nullptr)
			return false;

		// TODO: EncompassesPoint is expensive, possibly replace
		if(CurrentBounds.EncompassesPoint(Location, Radius))
			return true;

		return false;
	}
}
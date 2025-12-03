enum EAIResource
{
	NavigationTrace,
}

class UBasicAIResourceManager : UObject
{
	private TMap<EAIResource, uint> LastUsages;

	bool CanUse(EAIResource Resource) const 
	{
		if (!LastUsages.Contains(Resource))
			return true;

		// We're allowed to use each resource once per frame, extend as necessary
		if (Time::FrameNumber > LastUsages[Resource])
			return true;

		return false;
 	}

	void Use(EAIResource Resource)
	{
		LastUsages.Add(Resource, Time::FrameNumber);
	}
}


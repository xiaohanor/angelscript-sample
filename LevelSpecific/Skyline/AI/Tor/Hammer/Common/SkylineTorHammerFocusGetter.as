class USkylineTorHammerFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		ASkylineTorHammer Hammer = TListedActors<ASkylineTorHammer>().GetSingle();
		if(Hammer == nullptr)
			return FVector::ZeroVector;
		return Hammer.ActorLocation;
	}
};
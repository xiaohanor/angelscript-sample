class USkylineBossFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		ASkylineBoss Boss = ASkylineBoss::Get();
		if(Boss == nullptr)
			return FVector::ZeroVector;
		return Boss.CoreCollision.WorldLocation;
	}
};
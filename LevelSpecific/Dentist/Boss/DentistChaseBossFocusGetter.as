class UDentistChaseBossFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		// auto ChaseBoss = TListedActors<ADentistChaseBoss>().Single;
		// if(ChaseBoss == nullptr)
		// 	return nullptr;

		// return ChaseBoss.SkelMesh;
	
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		auto ChaseBoss = TListedActors<ADentistChaseBoss>().Single;
		if(ChaseBoss == nullptr)
			return FVector::ZeroVector;

		return ChaseBoss.SkelMesh.GetSocketLocation(n"Spine6") + ChaseBoss.SkelMesh.ForwardVector * 2000;
	}
}
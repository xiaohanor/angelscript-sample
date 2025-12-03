class UDentistBossDrillFinisherFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		auto Dentist = TListedActors<ADentistBoss>().Single;
		if(Dentist == nullptr)
			return FVector::ZeroVector;

		return Dentist.SkelMesh.GetSocketLocation(n"TeethAttach");
	}
}
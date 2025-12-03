class UAnimNotifyGrappleFishResurfaceBreach : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		auto GrappleFishComp = UDesertGrappleFishComponent::Get(MeshComp.Owner);
		if (GrappleFishComp == nullptr)
			return false;

		GrappleFishComp.OnAnimResurfaceBreach();
		return true;
	}
}

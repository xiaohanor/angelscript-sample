class UAnimNotifyGrappleFishEndJumpDetach : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		auto PlayerComp = UDesertGrappleFishPlayerComponent::Get(MeshComp.Owner);
		if (PlayerComp == nullptr)
			return false;

		PlayerComp.TriggerEndJumpDetach();
		return true;
	}
}
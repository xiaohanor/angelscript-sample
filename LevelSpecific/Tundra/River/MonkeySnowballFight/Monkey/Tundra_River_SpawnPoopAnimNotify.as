class UTundra_River_SpawnPoopAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		ATundra_River_ThrowPoopMonkey PoopMonkey = Cast<ATundra_River_ThrowPoopMonkey>(MeshComp.Owner);
		if(PoopMonkey == nullptr)
			return false;

		PoopMonkey.SpawnPoop();
		return true;
	}
}
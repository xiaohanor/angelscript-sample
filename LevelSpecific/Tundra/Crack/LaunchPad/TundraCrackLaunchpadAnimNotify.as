class UTundraCrackLaunchPadAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		Cast<ATundraCrackLaunchpad>(MeshComp.Owner).Launch();
		return true;
	}
}
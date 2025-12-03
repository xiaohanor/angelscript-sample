class USkylineTorWhirlwindAttackSwingAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(50, 180, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Swing";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		USkylineTorWhirlwindAttackComponent::GetOrCreate(MeshComp.Owner).Swing();
		return true;
	}
}
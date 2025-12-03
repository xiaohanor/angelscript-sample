class UAnimNotifyGameShowHatchAttach : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GameShowHatchAttach";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto PlayerHatchComp = UGameShowArenaHatchPlayerComponent::Get(MeshComp.Owner);
		if (PlayerHatchComp != nullptr)
			PlayerHatchComp.AttachHatchToPlayer();
		
		return true;
	}
}
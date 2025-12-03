class UAnimNotifyGameShowHatchBombDunk : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GameShowHatchBombDunk";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto PlayerHatchComp = UGameShowArenaHatchPlayerComponent::Get(MeshComp.Owner);
		if (PlayerHatchComp != nullptr)
			PlayerHatchComp.TriggerBombDunk();
		
		return true;
	}
}
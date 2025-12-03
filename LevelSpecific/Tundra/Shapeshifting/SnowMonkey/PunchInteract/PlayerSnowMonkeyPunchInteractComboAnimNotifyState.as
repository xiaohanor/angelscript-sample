class UTundraPlayerSnowMonkeyPunchInteractComboAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowMonkeyPunchInteractComboWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp == nullptr)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner.AttachParentActor);
		if(Player == nullptr)
			return false;

		auto MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MonkeyComp.bInPunchInteractComboWindow = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp == nullptr)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner.AttachParentActor);
		if(Player == nullptr)
			return false;

		auto MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MonkeyComp.bInPunchInteractComboWindow = false;
		return true;
	}
}
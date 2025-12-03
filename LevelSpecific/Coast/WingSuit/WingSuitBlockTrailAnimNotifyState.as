class UWingSuitBlockTrailAnimNotifyState : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "WingSuitBlockTrail";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto WingSuit = Cast<AWingSuit>(MeshComp.Owner);
		auto PotentialPlayer = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(WingSuit == nullptr && PotentialPlayer != nullptr)
			WingSuit = GetWingSuitFromPlayer(PotentialPlayer);

		if(WingSuit == nullptr)
			return false;

		if(WingSuit.PlayerOwner == nullptr)
			return false;

		auto WingSuitComp = UWingSuitPlayerComponent::Get(WingSuit.PlayerOwner);
		if(WingSuitComp == nullptr)
			return false;

		WingSuitComp.AddWingSuitTrailBlocker(n"WingSuitBlockTrailAnimNotifyState");
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto WingSuit = Cast<AWingSuit>(MeshComp.Owner);
		if(WingSuit == nullptr)
			WingSuit = GetWingSuitFromPlayer(MeshComp.Owner);

		if(WingSuit == nullptr)
			return false;

		if(WingSuit.PlayerOwner == nullptr)
			return false;

		auto WingSuitComp = UWingSuitPlayerComponent::Get(WingSuit.PlayerOwner);
		if(WingSuitComp == nullptr)
			return false;
		
		WingSuitComp.RemoveWingSuitTrailBlocker(n"WingSuitBlockTrailAnimNotifyState");
		return true;
	}
}
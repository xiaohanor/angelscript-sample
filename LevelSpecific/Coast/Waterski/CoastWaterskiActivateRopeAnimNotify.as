class UCoastWaterskiActivateRopeAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "WaterskiActivateRope";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp == nullptr)
			return false;

		if(MeshComp.Owner == nullptr)
			return false;

		auto Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
		if(Player == nullptr)
			return false;

		auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		if(WaterskiComp == nullptr)
			return false;

		WaterskiComp.WaterskiManager.ClearWaterskiRopeBlocker(Player, WaterskiComp);
		return true;
	}
}
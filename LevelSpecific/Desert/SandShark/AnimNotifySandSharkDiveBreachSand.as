class UAnimNotifySandSharkDiveBreachSand : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SandSharkDiveBreachSand";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto AnimComp = USandSharkAnimationComponent::Get(MeshComp.Owner);
		if(AnimComp == nullptr)
			return false;

		AnimComp.OnAnimSandDiveBreach();
		return true;
	}
}
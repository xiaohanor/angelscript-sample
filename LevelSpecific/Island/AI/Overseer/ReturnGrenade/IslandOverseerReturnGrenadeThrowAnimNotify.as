class UIslandOverseerReturnGrenadeThrowAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(150, 50, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Throw";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerReturnGrenadePlayerComponent::GetOrCreate(MeshComp.Owner).Throw();
		return true;
	}
}
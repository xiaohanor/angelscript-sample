class UIslandOverseerPeekAttackAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(50, 180, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "PeekAttack";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerPeekBombLauncherComponent::GetOrCreate(MeshComp.Owner).OnAttack.Broadcast();
		return true;
	}
}
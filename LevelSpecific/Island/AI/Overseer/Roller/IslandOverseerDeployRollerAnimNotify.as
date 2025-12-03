class UIslandOverseerDeployRollerAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(50, 180, 40);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DeployRoller";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDeployRollerManagerComponent::GetOrCreate(MeshComp.Owner).OnDeploy.Broadcast();
		return true;
	}
}
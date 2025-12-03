class USnapFlowerOpenAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraSnapFlowerOpen";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		auto SnapFlower = Cast<ASnapFlower>(MeshComp.Owner);
		if(SnapFlower == nullptr)
			return false;

		USnapFlowerEffectHandler::Trigger_OnOpen(SnapFlower);
		return true;
	}
}

UCLASS(Abstract)
class USnapFlowerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnapClose() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReactToFloatingPole() {}
}
UFUNCTION(BlueprintCallable)
mixin void ApplyCameraAssistType(
	AHazePlayerCharacter Player,
	UCameraAssistType Type,
	FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Low
)
{
	auto CameraAssistComp = UCameraAssistComponent::Get(Player);
	if(CameraAssistComp == nullptr)
		return;

	CameraAssistComp.ApplyAssistType(Type, Instigator, Priority);
}

UFUNCTION(BlueprintCallable)
mixin void ClearCameraAssistType(
	AHazePlayerCharacter Player,
	FInstigator Instigator
)
{
	auto CameraAssistComp = UCameraAssistComponent::Get(Player);
	if(CameraAssistComp == nullptr)
		return;

	CameraAssistComp.ClearAssistType(Instigator);
}
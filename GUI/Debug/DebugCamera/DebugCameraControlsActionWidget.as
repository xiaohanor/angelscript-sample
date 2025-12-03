UCLASS(Abstract)
class UDebugCameraControlsActionWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	FText Label;

	UFUNCTION(BlueprintCallable, BlueprintEvent)
	void SetActionName(const FName& ActionName) { }
}
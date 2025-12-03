
UCLASS(Abstract)
class UDebugCameraControlsWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UVerticalBox VerticalStack;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDebugCameraControlsActionWidget> ActionWidgetClass;

	UFUNCTION(BlueprintCallable)
	void ClearActions()
	{
		for (auto Widget : VerticalStack.AllChildren)
			RemoveWidget(Widget);
	}

	UFUNCTION(BlueprintCallable)
	UDebugCameraControlsActionWidget AddAction(const FName& ActionName, const FString& ActionLabel)
	{
		if (!devEnsure(ActionWidgetClass != nullptr && VerticalStack != nullptr))
			return nullptr;

		auto Action = Cast<UDebugCameraControlsActionWidget>(
			Widget::CreateWidget(this, ActionWidgetClass)
		);
		Action.Label = FText::FromString(ActionLabel);
		Action.SetActionName(ActionName);
		Action.OverrideWidgetPlayer(Player);

		VerticalStack.AddChild(Action);

		return Action;
	}
}
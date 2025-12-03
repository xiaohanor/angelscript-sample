USoundDefPreviewDataWidget CreatePreviewWidget(UPanelWidget ParentWidget, TSubclassOf<USoundDefPreviewDataWidget> WidgetType)
{
	return Cast<USoundDefPreviewDataWidget>(Widget::CreateWidget(ParentWidget, WidgetType));
}

UCLASS(Blueprintable)
class USoundDefPreviewDataWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	USoundDefPreviewWidgetBase PreviewWidget;

	UPROPERTY()
	UObject OuterOwner;

	UPROPERTY(BlueprintReadOnly)
	FText WidgetText;

	UPROPERTY(BlueprintReadWrite)
	UWidget ValueWidget;

	UFUNCTION(BlueprintEvent)
	void BP_SetValueWidget() {};

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		PreviewWidget = Cast<USoundDefPreviewWidgetBase>(GetParentWidgetOfClass(USoundDefPreviewWidgetBase));
		OuterOwner = PreviewWidget.SoundDefInstance;

		BP_SetValueWidget();
	}

	UFUNCTION(BlueprintCallable)
	void SetValueFromWidget(const FName PropertyName, UWidget Widget)
	{
		if (Widget == nullptr)
		{
			// SetPropertyValueFromWidget will early out if the widget is nullptr
			Error(f"Failed to find widget for {PropertyName} in {GetName()}");
		}

		PreviewWidget.SetPropertyValueFromWidget(PropertyName, OuterOwner, Widget);
	}
}

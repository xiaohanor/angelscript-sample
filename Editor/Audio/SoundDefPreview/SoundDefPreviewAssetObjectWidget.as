
event void FOnSetupAssetObjectWidget(UTriggerNodeParamWidgetData WidgetData, USoundDefPreviewWidget_AssetObject AssetWidget);

class USoundDefPreviewAssetObjectWidget : USoundDefPreviewDataWidget
{
	UFUNCTION(BlueprintEvent)
	void GetAssetObjectWidget(USoundDefPreviewWidget_AssetObject& OutAssetObject) {};

	UFUNCTION(BlueprintEvent)
	void SetupAssetObjectWidget(UTriggerNodeParamWidgetData WidgetData) {};

	UFUNCTION(BlueprintEvent)
	void SetAllowedClass(UClass InAllowedClass) {};

	UPROPERTY()
	FOnSetupAssetObjectWidget OnSetupAssetObjectWidget;

	UFUNCTION(BlueprintOverride)
	void Construct() override
	{
		Super::Construct();

		OnSetupAssetObjectWidget.AddUFunction(this, n"InternalSetupAssetObjectWidget");
	}

	UFUNCTION()
	private void InternalSetupAssetObjectWidget(UTriggerNodeParamWidgetData WidgetData, USoundDefPreviewWidget_AssetObject AssetWidget)
	{
		PreviewWidget.SetupAssetObjectWidget(WidgetData.PropertyName, WidgetData.StructOwner, AssetWidget);	
	}
}
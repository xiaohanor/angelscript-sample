
class USoundDefPreviewTriggerNodeWidget : USoundDefPreviewDataWidget
{	
	USoundDefPreviewWidget DerivedPreviewWidget;	

	UFUNCTION(BlueprintEvent)
	void BP_SetIsExpanded(bool bExpanded) {};

	UFUNCTION(BlueprintOverride)
	void Construct() override
	{
		Super::Construct();
		DerivedPreviewWidget = Cast<USoundDefPreviewWidget>(PreviewWidget);

		// This is so freaking ugly, but it works and seemed easy at the time...
		if(Parent.Name == "BuiltInsBox")
		{
			BP_SetIsExpanded(false);
		}
	}

	private void FillParamWidget(UPanelWidget ParentWidget, UTriggerNodeParamWidgetData WidgetData, TArray<UWidget>& OutValueWidgets)
	{
		USoundDefPreviewDataWidget CreatedWidget = CreatePreviewWidget(ParentWidget, WidgetData.ValueWidgetClass);
		CreatedWidget.WidgetText = FText::FromName(WidgetData.PropertyName);				
		CreatedWidget.BP_SetValueWidget();	

		FTriggerNodeStructParamData ParamData;
		ParamData.PropertyName = WidgetData.PropertyName;
		ParamData.StructOwner = WidgetData.StructOwner;
		ParamData.bIsNestedParam = WidgetData.bIsNestedParam;

		if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.FloatRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::FloatType;
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.BoolRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::BoolType;
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.StringRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::StringType;
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.EnumRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::EnumType;

			USoundDefPreviewEnumWidget EnumWidget = Cast<USoundDefPreviewEnumWidget>(CreatedWidget);
			EnumWidget.FillEnums(WidgetData.Enums);

		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.PlayerCharacterRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::ObjectType;				
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.ObjectRowWidget.Get())			
		{
			ParamData.ParamType = ETriggerNodeStructParamType::ObjectType;				
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.AssetObjectRowWidget.Get())
		{
			ParamData.ParamType = ETriggerNodeStructParamType::ObjectType;

			USoundDefPreviewAssetObjectWidget AssetObjectWidget = Cast<USoundDefPreviewAssetObjectWidget>(CreatedWidget);	
			AssetObjectWidget.SetAllowedClass(WidgetData.AssetObjectClass);	
			AssetObjectWidget.SetupAssetObjectWidget(WidgetData);					
		}
		else if(WidgetData.ValueWidgetClass == DerivedPreviewWidget.StructRowWidget.Get())
		{
			// Struct inside a struct, run function recursively
			for(UTriggerNodeParamWidgetData& ChildWidgetData : WidgetData.ChildWidgetDatas)
			{
				USoundDefPreviewStructWidget StructWidget = Cast<USoundDefPreviewStructWidget>(CreatedWidget);
				StructWidget.SetStructParamsBox();

				FillParamWidget(StructWidget.BPStructParamsBox, ChildWidgetData, OutValueWidgets);
			}
		}

		if(WidgetData.ValueWidgetClass != DerivedPreviewWidget.StructRowWidget.Get())
		{
			PreviewWidget.RegisterTriggerNodeParamWidget(CreatedWidget.ValueWidget, ParamData);
			OutValueWidgets.Add(CreatedWidget.ValueWidget);	
		}

		ParentWidget.AddChild(CreatedWidget);	
	}

	UFUNCTION(BlueprintCallable)
	TArray<UWidget> FillParamList_Internal(UPanelWidget ParamListParent, UPanelWidget ScrollListBox, TArray<UTriggerNodeParamWidgetData> ParamWidgetDatas)
	{
		TArray<UWidget> ValueWidgets;

		if(ParamWidgetDatas.Num() > 0)
		{
			ParamListParent.RemoveChildAt(0);
		}

		for(UTriggerNodeParamWidgetData WidgetData : ParamWidgetDatas)
		{
			FillParamWidget(ScrollListBox, WidgetData, ValueWidgets);
		}

		return ValueWidgets;
	}	
}
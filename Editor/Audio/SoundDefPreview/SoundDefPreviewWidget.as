
event void FOnEnvironmentTypeChanged(int SelectedIndex);
event void FOnSetGlobalRtpcValue(FString RtpcString, float Value, float InterpolationTimeMs);
event void FOnSetRtpcValue(UHazeAudioEmitter Emitter, FString RtpcString, float Value, float InterpolationTimeMs);
event void FOnSetAudioComponentDistance(UHazeAudioEmitter Emitter, float Distance);

class USoundDefPreviewWidget : USoundDefPreviewWidgetBase
{	
	TArray<FBPVariableDescription> VariableDescs;
	TArray<FBPVariableDescription> AudioEventDescs;
	TArray<FBPVariableDescription> AudioComponentDescs;

	UPROPERTY()
	FOnEnvironmentTypeChanged OnEnvironmentChanged;

	UPROPERTY()
	FOnSetRtpcValue OnSetRtpc;

	UPROPERTY()
	FOnSetGlobalRtpcValue OnSetGlobalRtpc;

	UPROPERTY()
	FOnSetAudioComponentDistance OnSetAudioCompDistance;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> FloatRowWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> BoolRowWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> StringRowWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> EnumRowWidget;
	
	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> ObjectRowWidget;
		
	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> StructRowWidget;
		
	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> AssetObjectRowWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> PlayerCharacterRowWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> AudioComponentWidget;
	
	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> AudioEventWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> RtpcWidget;

	UPROPERTY()
	TSubclassOf<USoundDefPreviewDataWidget> TriggerNodeWidget;

	UPROPERTY(BlueprintReadOnly)
	UObject DefaultFontObject;

	UFUNCTION(BlueprintEvent)
	void BP_ConvertFloatWidgetToInt(USoundDefPreviewDataWidget FloatWidget) {};

	UFUNCTION(BlueprintEvent)
	void BP_SetAudioCompInWidget(USoundDefPreviewDataWidget AudioCompWidget, UHazeAudioEmitter Emitter) {};

	UFUNCTION(BlueprintEvent)
	void BP_FillTriggerNodeParamList(USoundDefPreviewDataWidget InTriggerNodeWidget, TArray<UTriggerNodeParamWidgetData> ParamData) {};

	UPanelWidget VariablesScrollBox;
	UPanelWidget AudioComponentsScrollBox;
	UPanelWidget FunctionsScrollBox;
	UPanelWidget BuiltInFunctionsPanel;

	TMap<FString, USoundDefPreviewWidget_MemberVariableCategory> VariableCategoryAreas;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{		
		OnEnvironmentChanged.AddUFunction(this, n"OnEnvironmentTypeChanged");
		OnSetAudioCompDistance.AddUFunction(this, n"OnSetAudioComponentDistance");
		OnSetRtpc.AddUFunction(this, n"SetRtpc");
		//OnSetGlobalRtpc.AddUFunction(this, n"SetGlobalRtpc");

		GetVariablesParentWidget(VariablesScrollBox);	
		GetAudioComponentsParentWidget(AudioComponentsScrollBox);
		GetTriggerNodesParentWidget(FunctionsScrollBox);
		GetBuiltInFunctionsParentWidget(BuiltInFunctionsPanel);
	}

	UFUNCTION(BlueprintOverride)
	void PopulateVariablesLayouts()
	{
		TArray<USoundDefPreviewWidget_MemberVariableCategory> RootWidgets;


		for(FString Category : ParsedVariableCategories)
		{	
			USoundDefPreviewWidget_MemberVariableCategory LastParent = nullptr;
			TArray<FString> ParsedCategories;

			Category.ParseIntoArray(ParsedCategories, "|");

			for(int i = 0; i < ParsedCategories.Num(); ++i)
			{
				FString ParsedCat = ParsedCategories[i];

				if(ParsedCat == "Default")
					continue;

				USoundDefPreviewWidget_MemberVariableCategory VariableArea;

				if(VariableCategoryAreas.Find(ParsedCat, VariableArea))
				{
					LastParent = VariableArea;
					continue;
				}
				
				VariableArea = NewObject(this, USoundDefPreviewWidget_MemberVariableCategory);
				VariableArea.SetHeaderText(ParsedCat);

				VariableCategoryAreas.Add(ParsedCat, VariableArea);

				if(i == 0)
				{
					RootWidgets.Add(VariableArea);
					LastParent = VariableArea;
				}
				else
				{
					FMargin AreaMargin = LastParent.AreaPadding;
					AreaMargin.Left = LastParent.AreaPadding.Left + 10;

					VariableArea.SetHeaderMargin(AreaMargin);
					LastParent.AddToBody(VariableArea);
					LastParent = VariableArea;
				}
			}			
		}	

		TArray<UTriggerNodeParamWidgetData> FloatDatas = GetSortedFloatDatas();
		TArray<UTriggerNodeParamWidgetData> BoolDatas = GetSortedBoolDatas();
		TArray<UTriggerNodeParamWidgetData> StringDatas = GetSortedStringDatas();
		TArray<UTriggerNodeParamWidgetData> ObjectDatas = GetSortedObjectDatas();	
		TArray<UTriggerNodeParamWidgetData> StructDatas; // = GetSortedStructDatas();	

		for(UTriggerNodeParamWidgetData& WidgetData : FloatDatas)
		{
			USoundDefPreviewDataWidget CreatedWidget = CreateVariableWidgetRow(VariablesScrollBox, FloatRowWidget, WidgetData);
			
			if(WidgetData.bFloatNeedsTruncate)
			{
				BP_ConvertFloatWidgetToInt(CreatedWidget);
			}		

			RegisterVariableParamWidget(CreatedWidget.ValueWidget, WidgetData.PropertyName);	
		}

		for(UTriggerNodeParamWidgetData& WidgetData : BoolDatas)
		{
			USoundDefPreviewDataWidget CreatedWidget = CreateVariableWidgetRow(VariablesScrollBox, BoolRowWidget, WidgetData);
			RegisterVariableParamWidget(CreatedWidget.ValueWidget, WidgetData.PropertyName);
		}		

		for(UTriggerNodeParamWidgetData& WidgetData : StringDatas)
		{
			USoundDefPreviewDataWidget CreatedWidget = CreateVariableWidgetRow(VariablesScrollBox, StringRowWidget, WidgetData);
			RegisterVariableParamWidget(CreatedWidget.ValueWidget, WidgetData.PropertyName);
		}

		for(UTriggerNodeParamWidgetData& WidgetData : ObjectDatas)
		{
			UClass ObjectClass = WidgetData.AssetObjectClass;
			if(ObjectClass.IsChildOf(AActor)
			|| ObjectClass.IsChildOf(UActorComponent))
			{
				USoundDefPreviewDataWidget ObjectWidget = CreateVariableWidgetRow(VariablesScrollBox, ObjectRowWidget, WidgetData);
			
				FString ObjectWidgetName = WidgetData.PropertyName.ToString() + "(" + ObjectClass.GetName().ToString() + ")";
				ObjectWidget.WidgetText = FText::FromString(ObjectWidgetName);

				InstantiateObject(WidgetData.PropertyName, SoundDefInstance, ObjectClass);
			}
			else
			{
				CreateAssetObjectWidgetRow(VariablesScrollBox, WidgetData.PropertyName, ObjectClass);
			}
		}

		for(UTriggerNodeParamWidgetData& WidgetData : StructDatas)
		{
			USoundDefPreviewStructWidget StructWidget = Cast<USoundDefPreviewStructWidget>(CreateVariableWidgetRow(VariablesScrollBox, StructRowWidget, WidgetData));
			StructWidget.SetStructParamsBox();
			
			for(UTriggerNodeParamWidgetData& NestedWidgetData : WidgetData.ChildWidgetDatas)
			{				
				if(NestedWidgetData.ValueWidgetClass == FloatRowWidget.Get())
				{
					USoundDefPreviewDataWidget CreatedWidget = CreateVariableWidgetRow(StructWidget.BPStructParamsBox, NestedWidgetData.ValueWidgetClass, NestedWidgetData);					
					CreatedWidget.OuterOwner = WidgetData.StructOwner;

					if(NestedWidgetData.bFloatNeedsTruncate)
					{
						BP_ConvertFloatWidgetToInt(CreatedWidget);
					}
				}
				else if(NestedWidgetData.ValueWidgetClass == BoolRowWidget.Get())
				{
					USoundDefPreviewDataWidget CreatedWidget = CreateVariableWidgetRow(StructWidget.BPStructParamsBox, NestedWidgetData.ValueWidgetClass, NestedWidgetData);
					CreatedWidget.OuterOwner = WidgetData.StructOwner;
				}
				else if(NestedWidgetData.ObjectType == ESoundDefVariableObjectType::Object)
				{					
					USoundDefPreviewDataWidget ObjectWidget = CreateVariableWidgetRow(StructWidget.BPStructParamsBox, NestedWidgetData.ValueWidgetClass, NestedWidgetData);
					ObjectWidget.OuterOwner = WidgetData.StructOwner;

					FString ObjectWidgetName = NestedWidgetData.PropertyName.ToString() + "(" + NestedWidgetData.AssetObjectClass.GetName() + ")";
					ObjectWidget.WidgetText = FText::FromString(ObjectWidgetName);

					InstantiateObject(NestedWidgetData.PropertyName, SoundDefInstance, NestedWidgetData.AssetObjectClass);
				}	
				else if(NestedWidgetData.ObjectType == ESoundDefVariableObjectType::Asset)
				{
					CreateAssetObjectWidgetRow(StructWidget.BPStructParamsBox, NestedWidgetData.PropertyName, NestedWidgetData.AssetObjectClass);
				}					
				else if(NestedWidgetData.ObjectType == ESoundDefVariableObjectType::Struct)
				{
					USoundDefPreviewStructWidget NestedStructWidget = Cast<USoundDefPreviewStructWidget>(CreateVariableWidgetRow(StructWidget.BPStructParamsBox, NestedWidgetData.ValueWidgetClass, NestedWidgetData));
					NestedStructWidget.SetStructParamsBox();						

					FString ObjectWidgetName = NestedWidgetData.PropertyName.ToString() + "(" + NestedWidgetData.AssetObjectClass.GetName().ToString() + ")";
					NestedStructWidget.WidgetText = FText::FromString(ObjectWidgetName);
				}
							
			}
		}	

		// All variable-widgets added under their respective category, now add the root widgets
		for(USoundDefPreviewWidget_MemberVariableCategory Widget : RootWidgets)
		{
			VariablesScrollBox.AddChild(Widget);
		}
	}

	void CreateAssetObjectWidgetRow(UPanelWidget ParentWidget, FName PropertyName, UClass ObjectClass)
	{
		UTextBlock TextBlockWidget = NewObject(this, UTextBlock);

		FSlateFontInfo FontInfo;
		FontInfo.FontObject = DefaultFontObject;
		FontInfo.Size = 12.0;	
	
		TextBlockWidget.SetFont(FontInfo);
		TextBlockWidget.SetText(FText::FromName(PropertyName));

		UScrollBoxSlot TextSlot = Cast<UScrollBoxSlot>(ParentWidget.AddChild(TextBlockWidget));

		USoundDefPreviewWidget_AssetObject AssetWidget = NewObject(this, USoundDefPreviewWidget_AssetObject);
		AssetWidget.SetAllowedClass(ObjectClass);	

		UScrollBoxSlot AssetObjectSlot = Cast<UScrollBoxSlot>(ParentWidget.AddChild(AssetWidget));

		FMargin Margin;
		Margin.Left = 10.0;

		TextSlot.SetPadding(Margin);
		AssetObjectSlot.SetPadding(Margin);

		SetupAssetObjectWidget(PropertyName, SoundDefInstance, AssetWidget);	
	}

	private USoundDefPreviewDataWidget CreateVariableWidgetRow(UPanelWidget& ParentWidget, TSubclassOf<USoundDefPreviewDataWidget> WidgetType, const UTriggerNodeParamWidgetData& ParamWidgetData)
	{
		USoundDefPreviewDataWidget NewWidget = CreatePreviewWidget(VariablesScrollBox, WidgetType);
		NewWidget.WidgetText = FText::FromName(ParamWidgetData.PropertyName);	
		NewWidget.BP_SetValueWidget();

		if(ParamWidgetData.HasMemberCategory())
		{
			FString Right;
			FString Left;

			FString WantedCategory;

			if(ParamWidgetData.PropertyCategory.ToString().Split("|", Left, Right, SearchDir = ESearchDir::FromEnd))
			{
				WantedCategory = Right;
			}
			else
			{
				WantedCategory = ParamWidgetData.PropertyCategory.ToString();
			}

			USoundDefPreviewWidget_MemberVariableCategory CategoryArea;
			if(VariableCategoryAreas.Find(WantedCategory, CategoryArea))
			{
				FMargin WidgetPadding = CategoryArea.HeaderPadding;
				WidgetPadding.Left = WidgetPadding.Left + 10.0;

				NewWidget.Padding = WidgetPadding;
				CategoryArea.AddToBody(NewWidget);
			}
		}	
		else
		{

			ParentWidget.AddChild(NewWidget);
		}

		return NewWidget;
	}

	UFUNCTION(BlueprintOverride)
	void CreateAudioComponentWidget(FName EmitterName)
	{
		USoundDefPreviewDataWidget AudioCompWidget = CreatePreviewWidget(AudioComponentsScrollBox, AudioComponentWidget);
		UHazeAudioEmitter Emitter = GetEmitterByName(EmitterName);
		AudioCompWidget.WidgetText = FText::FromName(EmitterName);

		AudioComponentsScrollBox.AddChild(AudioCompWidget);

		BP_SetAudioCompInWidget(AudioCompWidget, Emitter);
	}

	UFUNCTION(BlueprintOverride)
	void CreateTriggerNodeWidget(FTriggerNodeWidgetData WidgetData, UHazeUserWidget& OutCreatedWidget)
	{
		USoundDefPreviewDataWidget NewTriggerNodeWidget = CreatePreviewWidget(FunctionsScrollBox, TriggerNodeWidget);
		NewTriggerNodeWidget.WidgetText = FText::FromName(WidgetData.NodeName);

		if(!WidgetData.bIsBuiltIn)
		{
			FunctionsScrollBox.AddChild(NewTriggerNodeWidget);
		}
		else
		{
			BuiltInFunctionsPanel.AddChild(NewTriggerNodeWidget);
		}

		BP_FillTriggerNodeParamList(NewTriggerNodeWidget, WidgetData.ParamData);
		OutCreatedWidget = NewTriggerNodeWidget;
	}

	UFUNCTION()
	void OnEnvironmentTypeChanged(int SelectedIndex)
	{
		SetDebugOverlappingEnvironment(SelectedIndex);
	}	

	UFUNCTION()
	void OnSetAudioComponentDistance(UHazeAudioEmitter Emitter, float Distance)
	{
		UHazeAudioComponent AudioComp = Emitter.GetAudioComponent();

		AudioComp.SetWorldLocation(FVector(0, 0, Distance));
		UpdateSoundPosition(AudioComp);
	}

	
	UFUNCTION(BlueprintCallable)
	void SetRtpc(UHazeAudioEmitter Emitter, FString RtpcString, float Value, float InterpolationTimeMS = 0)
	{
		if(Emitter == nullptr)
			return;

		Emitter.SetRTPC(FHazeAudioID(RtpcString), Value, int(InterpolationTimeMS));
	}

	UFUNCTION(BlueprintCallable)
	void SetGlobalRTPC(FString RtpcString, float Value, float InterpolationTimeMS = 0)
	{	
		AudioComponent::SetGlobalRTPC(FHazeAudioID(RtpcString), Value, int(InterpolationTimeMS));
	}

	UFUNCTION(BlueprintCallable)
	FHazeAudioID GetAudioIDFromString(const FString& InString)
	{
		return FHazeAudioID(InString);
	}
	
	private UHazeAudioEmitter GetEmitterByName(const FName& InName)
	{
		for(UHazeAudioEmitter Emitter : SoundDefInstance.Emitters)
		{
			FString Index;
			FString CleanedName;
			// We can't support having "." in the names, so we need to clean up the name some other way.
			// Emitter.Name.ToString().Split(".", Left, CleanedName);
			auto EmitterName = Emitter.Name.ToString();
			EmitterName.RemoveFromStart(SoundDefInstance.GetName().ToString()+"_");
			// This name will still contain a indexer "SomeEmitterName_INDEX"
			EmitterName.Split("_", CleanedName, Index);
			
			if(CleanedName == InName)
				return Emitter;
		}

		return nullptr;
	}
}
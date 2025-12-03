class UGameShowArenaPlatformManagerEditorComponent : UActorComponent
{
#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Preview", meta = (GetOptions = "GetStoredPlatformLayoutNames"))
	FString PreviewPlatformLayout;

	UPROPERTY(EditInstanceOnly, Category = "Paint Mode")
	EBombTossPlatformPosition PaintPlatformPosition;

	UPROPERTY(EditInstanceOnly, Category = "Paint Mode")
	FKey PlatformPaintKey = EKeys::P;

	// Only for in editor script. Sets the values based on layout in level
	void SaveNewPlatformPositionValues(EBombTossPlatformPosition PlatformPosition, FBombTossPlatformPositionValues NewPlatformPositionValues)
	{
		auto PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		int LastIndex = int(EBombTossPlatformPosition::HalfRaised);

		if (PlatformManager.PlatformPositionValuesDataAsset.PositionValues.Num() != LastIndex + 1)
			PlatformManager.PlatformPositionValuesDataAsset.PositionValues.SetNum(LastIndex + 1);

		PlatformManager.PlatformPositionValuesDataAsset.PositionValues[PlatformPosition] = NewPlatformPositionValues;
	}

	// UFUNCTION(CallInEditor)
	// void MapAllLayoutPositionDataToLayoutMoveData()
	// {
	// 	auto PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
	// 	for (auto Layout : PlatformManager.PlatformLayoutsDataAsset.Layouts)
	// 	{
	// 		Layout.Value.MapPositionDataToMoveData();
	// 	}
	// 	PlatformManager.PlatformLayoutsDataAsset.MarkPackageDirty();
	// }

	UFUNCTION(CallInEditor)
	void SavePlatformLayout(FString LayoutName)
	{
		auto PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		// auto AllPlatforms = PlatformManager.GetPlatformsSortedY();

		// Create new entry
		FBombTossPlatformPositionLayouts NewLayout;
		for (auto Arm : TListedActors<AGameShowArenaPlatformArm>().Array)
		{
			// NewLayout.MoveDataByGuid.Add(Platform.PlatformGuid, Platform.LayoutMoveData);
			// if (Platform.LinkedArm != nullptr)
			// {
			// }
			NewLayout.ArmMoveDataByGuid.Add(Arm.ArmGuid, Arm.LayoutMoveData);
		}

		PlatformManager.PlatformLayoutsDataAsset.Layouts.Add(LayoutName, NewLayout);

		PlatformManager.PlatformLayoutsDataAsset.MarkPackageDirty();
		EditorAsset::SaveAsset(PlatformManager.PlatformLayoutsDataAsset.GetPathName(), true);
	}

	// void SetAllPlatformsToPosition(EBombTossPlatformPosition Position)
	// {
	// 	TListedActors<ABombToss_Platform> Platforms;
	// 	for (auto Platform : Platforms)
	// 		Platform.EditorSetPreviewLocation(Position);
	// }

	private void LoadPlatformLayout()
	{
		auto PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		auto Layout = PlatformManager.PlatformLayoutsDataAsset.Layouts[PreviewPlatformLayout];
		auto ArmsByGuid = PlatformManager.GetArmsByGuid();
		for (auto Entry : Layout.ArmMoveDataByGuid)
		{
			if (!ArmsByGuid.Contains(Entry.Key))
			{
				continue;
			}
			ArmsByGuid[Entry.Key].EditorSnapToMoveData(Entry.Value);
		}
	}

	void LoadPlatformLayoutFromName(FName LayoutName)
	{
		PreviewPlatformLayout = LayoutName.ToString();
		LoadPlatformLayout();
	}

	UFUNCTION()
	TArray<FString> GetStoredPlatformLayoutNames() const
	{
		auto PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();
		return PlatformManager.GetStoredPlatformLayoutNames();
	}

#endif
};

#if EDITOR
class UGameShowArenaPlatformManagerEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGameShowArenaPlatformManagerEditorComponent;

	float TimeWhenLastChangedColor = 0;
	int LayoutIndex;

	TArray<FLinearColor> DebugColors;
	default DebugColors.SetNum(6);
	default DebugColors[0] = FLinearColor::Yellow;
	default DebugColors[1] = FLinearColor::Blue;
	default DebugColors[2] = FLinearColor::LucBlue;
	default DebugColors[3] = FLinearColor(0.83, 0.09, 0.85);
	default DebugColors[4] = FLinearColor::Green;
	default DebugColors[5] = FLinearColor::White;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UGameShowArenaPlatformManagerEditorComponent>(Component);
		if (Comp == nullptr)
			return;

		AGameShowArenaPlatformManager Manager = Cast<AGameShowArenaPlatformManager>(Component.Owner);
		if (Manager == nullptr)
			return;

		Editor::ActivateVisualizer(Comp);
	}

	void HandleLayoutPaint(ABombToss_Platform BombTossPlatform, UGameShowArenaPlatformManagerEditorComponent EditorComp, FKey Key)
	{
		if (Key == EditorComp.PlatformPaintKey)
		{
			Editor::BeginTransaction("Changed Platform Preview", BombTossPlatform);
			BombTossPlatform.Modify();
			BombTossPlatform.EditorSetPreviewLocation(FGameShowArenaPlatformMoveData(EditorComp.PaintPlatformPosition));
			Editor::EndTransaction();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		UGameShowArenaPlatformManagerEditorComponent EditorComp = Cast<UGameShowArenaPlatformManagerEditorComponent>(EditingComponent);
		if (EditorComp == nullptr)
			return false;

		auto Manager = Cast<AGameShowArenaPlatformManager>(EditorComp.Owner);
		if (Manager == nullptr)
			return false;

		if (Event == EInputEvent::IE_Released)
			return false;

		FVector MouseOrigin, TraceDirection;
		Editor::GetEditorCursorRay(MouseOrigin, TraceDirection);
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();

		auto HitResult = Trace.QueryTraceSingle(MouseOrigin, MouseOrigin + (TraceDirection * 50000));
		if (!HitResult.IsValidBlockingHit())
			return false;

		auto BombTossPlatform = Cast<ABombToss_Platform>(HitResult.Actor);

		if (BombTossPlatform == nullptr)
			return false;

		return false;
	}
}

class UGameShowArenaPlatformManagerEditorComponentDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UGameShowArenaPlatformManagerEditorComponent;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideCategory(n"Debug");
		HideCategory(n"Cooking");
		HideCategory(n"Tags");
		HideCategory(n"Activation");
		HideCategory(n"Navigation");
	}
}
#endif
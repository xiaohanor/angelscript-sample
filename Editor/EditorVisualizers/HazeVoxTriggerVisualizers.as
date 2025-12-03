
struct FHazeVoxVisualizerData
{
	TWeakObjectPtr<AActor> TriggerActor;
	FName ComponentName;
}

class UVoxVisualizerTextRenderComponent : UTextRenderComponent
{
#if EDITOR
	default bTickInEditor = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default bSelectable = false;

	FVector OffsetLocation = FVector(0, 0, 50);
	FVector TriggerLocation;
	FRotator TriggerRotation;

	bool bUseEditorCamera = true;
	bool bRotateTowardsCamera = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRotateTowardsCamera)
		{
			FVector Forward;
			FVector Up;
			if (bUseEditorCamera)
			{
				FRotator EditorCamRotation = Editor::GetEditorViewRotation();

				Forward = EditorCamRotation.GetForwardVector() * -1.0;
				Up = EditorCamRotation.GetUpVector();
			}
			else
			{
				AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(TriggerLocation + OffsetLocation);
				if (ClosestPlayer != nullptr)
				{
					Forward = ClosestPlayer.ViewRotation.ForwardVector * -1.0;
					Up = ClosestPlayer.ViewRotation.UpVector;
				}
			}
			SetWorldRotation(FRotator::MakeFromXZ(Forward, Up));
		}
		else
		{
			SetWorldRotation(TriggerRotation);
		}

		SetWorldLocation(TriggerLocation + OffsetLocation);
	}
#endif
}

class AVoxEditorVisualizerActor : AHazeActor
{
#if EDITOR
	private TArray<FHazeVoxVisualizerData> VisualizerComponents;
	private int32 NextComponentId = 0;

	bool bUseEditorWorld = false;
	bool bRotateVisualizersTowardsCamera = false;

	void UpdateVisualizers()
	{
		for (int i = VisualizerComponents.Num() - 1; i >= 0; --i)
		{
			if (!VisualizerComponents[i].TriggerActor.IsValid())
			{
				RemoveTriggerVisualizer(VisualizerComponents[i].ComponentName);
				VisualizerComponents.RemoveAtSwap(i);
			}
			else
			{
				UpdateTriggerVisualizer(VisualizerComponents[i]);
			}
		}

		TArray<AActor> PlayerTriggers;
		if (bUseEditorWorld)
		{
			PlayerTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxPlayerTrigger));
			PlayerTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxAdvancedPlayerTrigger));
			PlayerTriggers.Append(Editor::GetAllEditorWorldActorsOfClass(AVoxDuoPlayerTrigger));
		}
		else
		{
			// Returns both trigger types
			VoxEditor::GetAllVoxTriggersInWorld(PlayerTriggers);
		}

		for (AActor PlayerTrigger : PlayerTriggers)
		{
			bool bAlreadyAdded = false;
			for (const FHazeVoxVisualizerData& VisData : VisualizerComponents)
			{
				if (VisData.TriggerActor.Get() == PlayerTrigger)
				{
					bAlreadyAdded = true;
					break;
				}
			}

			if (!bAlreadyAdded)
			{
				const FName ComponentName = CreateTriggerVisualizer(PlayerTrigger);
				if (!ComponentName.IsNone())
				{
					FHazeVoxVisualizerData NewVisualizer;
					NewVisualizer.ComponentName = ComponentName;
					NewVisualizer.TriggerActor = PlayerTrigger;
					VisualizerComponents.Add(NewVisualizer);
				}
			}
		}
	}

	private FString BuildOldTriggerDebugText(UVoxTriggerComponent VoxTriggerComponent) const
	{
		FString DisplayText;
		if (VoxTriggerComponent.VoxAsset != nullptr)
		{
			DisplayText += VoxTriggerComponent.VoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.MioVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Mio: ";
			DisplayText += VoxTriggerComponent.MioVoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.ZoeVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Zoe: ";
			DisplayText += VoxTriggerComponent.ZoeVoxAsset.Name.ToString();
		}
		return DisplayText;
	}

	private FString BuildAdvancedTriggerDebugText(UVoxAdvancedPlayerTriggerComponent VoxTriggerComponent) const
	{
		FString DisplayText = "ADVANCED";
		if (VoxTriggerComponent.VoxAsset != nullptr)
		{
			DisplayText += "\n";
			DisplayText += VoxTriggerComponent.VoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.MioVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Mio: ";
			DisplayText += VoxTriggerComponent.MioVoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.ZoeVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Zoe: ";
			DisplayText += VoxTriggerComponent.ZoeVoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.MioAltVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Mio Alt: ";
			DisplayText += VoxTriggerComponent.MioAltVoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.ZoeAltVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Zoe Alt: ";
			DisplayText += VoxTriggerComponent.ZoeAltVoxAsset.Name.ToString();
		}
		return DisplayText;
	}

	private FString BuildDuoTriggerDebugText(UVoxDuoPlayerTriggerComponent VoxTriggerComponent)
	{
		FString DisplayText = "DUO";
		if (VoxTriggerComponent.MioVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Mio: ";
			DisplayText += VoxTriggerComponent.MioVoxAsset.Name.ToString();
		}
		if (VoxTriggerComponent.ZoeVoxAsset != nullptr)
		{
			if (DisplayText.Len() > 0)
				DisplayText += "\n";

			DisplayText += "Zoe: ";
			DisplayText += VoxTriggerComponent.ZoeVoxAsset.Name.ToString();
		}
		return DisplayText;
	}

	private void UpdateTriggerVisualizer(FHazeVoxVisualizerData VisualizerData)
	{
		UVoxVisualizerTextRenderComponent Comp = GetComponent(UVoxVisualizerTextRenderComponent, VisualizerData.ComponentName);
		if (Comp == nullptr)
			return;

		AActor TriggerActor = VisualizerData.TriggerActor.Get();

		FString DebugText;
		UVoxTriggerComponent TriggerCompnent = UVoxTriggerComponent::Get(TriggerActor);
		if (TriggerCompnent != nullptr)
			DebugText = BuildOldTriggerDebugText(TriggerCompnent);

		UVoxAdvancedPlayerTriggerComponent AdvancedTriggerCompnent = UVoxAdvancedPlayerTriggerComponent::Get(TriggerActor);
		if (AdvancedTriggerCompnent != nullptr)
			DebugText = BuildAdvancedTriggerDebugText(AdvancedTriggerCompnent);

		UVoxDuoPlayerTriggerComponent DuoTriggerCompnent = UVoxDuoPlayerTriggerComponent::Get(TriggerActor);
		if (DuoTriggerCompnent != nullptr)
			DebugText = BuildDuoTriggerDebugText(DuoTriggerCompnent);

		Comp.SetText(FText::FromString(DebugText));
		Comp.bRotateTowardsCamera = bRotateVisualizersTowardsCamera;

		Comp.TriggerLocation = TriggerActor.GetActorLocation();
		Comp.TriggerRotation = TriggerActor.GetActorRotation();
	}

	private FName CreateTriggerVisualizer(AActor TriggerActor)
	{
		FString ComponentNameStr = f"Visualizer_{TriggerActor.Name}_{NextComponentId}";
		NextComponentId++;
		FName ComponentName = FName(ComponentNameStr);

		FString DebugText;
		UVoxTriggerComponent TriggerCompnent = UVoxTriggerComponent::Get(TriggerActor);
		if (TriggerCompnent != nullptr)
			DebugText = BuildOldTriggerDebugText(TriggerCompnent);

		UVoxAdvancedPlayerTriggerComponent AdvancedTriggerCompnent = UVoxAdvancedPlayerTriggerComponent::Get(TriggerActor);
		if (AdvancedTriggerCompnent != nullptr)
			DebugText = BuildAdvancedTriggerDebugText(AdvancedTriggerCompnent);

		UVoxDuoPlayerTriggerComponent DuoTriggerCompnent = UVoxDuoPlayerTriggerComponent::Get(TriggerActor);
		if (DuoTriggerCompnent != nullptr)
			DebugText = BuildDuoTriggerDebugText(DuoTriggerCompnent);

		if (DebugText.IsEmpty())
			return NAME_None;

		UVoxVisualizerTextRenderComponent DebugNameDisplay = CreateComponent(UVoxVisualizerTextRenderComponent, ComponentName);
		DebugNameDisplay.bUseEditorCamera = bUseEditorWorld;
		DebugNameDisplay.bRotateTowardsCamera = bRotateVisualizersTowardsCamera;

		DebugNameDisplay.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
		DebugNameDisplay.SetVisibility(true);
		DebugNameDisplay.SetHiddenInGame(false);
		DebugNameDisplay.SetText(FText::FromString(DebugText));

		// Remove scale from transform
		FTransform FixedTransform = TriggerActor.ActorTransform;
		FixedTransform.Scale3D = FVector(1.0);
		DebugNameDisplay.SetWorldTransform(FixedTransform);

		return ComponentName;
	}

	private void RemoveTriggerVisualizer(FName ComponentName)
	{
		UVoxVisualizerTextRenderComponent Comp = GetComponent(UVoxVisualizerTextRenderComponent, ComponentName);
		if (Comp != nullptr)
		{
			Comp.DestroyComponent(this);
		}
	}

#endif
}

class UHazeVoxEditorVisualizer : UHazeEditorSubsystem
{
#if EDITOR
	TWeakObjectPtr<AVoxEditorVisualizerActor> EditorActor;
	TWeakObjectPtr<AVoxEditorVisualizerActor> InGamePrimaryActor;
	TWeakObjectPtr<AVoxEditorVisualizerActor> InGameSecondaryActor;

	TWeakObjectPtr<UHazeVoxDebugConfig> VoxDebugConfig;

	bool bShowingVisualizers = false;

	private bool UpdateInGameActors()
	{
		bool bHadAnyWorld = false;
		if (Editor::HasPrimaryGameWorld())
		{
			bHadAnyWorld = true;
			FScopeDebugPrimaryWorld WorldContext;
			UpdateInGameActor(InGamePrimaryActor);
		}

		if (Editor::HasSecondaryGameWorld())
		{
			bHadAnyWorld = true;
			FScopeDebugSecondaryWorld WorldContext;
			UpdateInGameActor(InGameSecondaryActor);
		}

		return bHadAnyWorld;
	}

	private void UpdateInGameActor(TWeakObjectPtr<AVoxEditorVisualizerActor>& InOutActor) const
	{
		if (!InOutActor.IsValid())
		{
			InOutActor = SpawnActor(AVoxEditorVisualizerActor);
		}

		if (InOutActor.IsValid())
		{
			InOutActor.Get().bUseEditorWorld = false;
			InOutActor.Get().bRotateVisualizersTowardsCamera = VoxDebugConfig.Get().bRotateTriggerVisualizers;
			InOutActor.Get().UpdateVisualizers();
		}
	}

	private void UpdateLevelEditorActor()
	{
		if (!EditorActor.IsValid())
		{
			EditorActor = Cast<AVoxEditorVisualizerActor>(SpawnTemporaryEditorActor(AVoxEditorVisualizerActor));
		}

		if (EditorActor.IsValid())
		{
			EditorActor.Get().bUseEditorWorld = true;
			EditorActor.Get().bRotateVisualizersTowardsCamera = VoxDebugConfig.Get().bRotateTriggerVisualizers;
			EditorActor.Get().UpdateVisualizers();
		}
	}

#endif

	UFUNCTION(BlueprintOverride)
	private void Tick(float DeltaTime)
	{
#if EDITOR
		if (!VoxDebugConfig.IsValid())
		{
			VoxDebugConfig = UHazeVoxDebugConfig.DefaultObject;
		}

		if (!VoxDebugConfig.IsValid())
			return;

		bool bShowTriggerAssets = VoxDebugConfig.Get().bShowTriggerVisualizers;
		if (bShowTriggerAssets)
		{
			bShowingVisualizers = true;
			bool bHadWorld = UpdateInGameActors();
			if (!bHadWorld)
			{
				UpdateLevelEditorActor();
			}
		}
		else if (bShowingVisualizers)
		{
			if (InGamePrimaryActor.IsValid())
			{
				InGamePrimaryActor.Get().DestroyActor();
				InGamePrimaryActor = nullptr;
			}

			if (InGameSecondaryActor.IsValid())
			{
				InGameSecondaryActor.Get().DestroyActor();
				InGameSecondaryActor = nullptr;
			}

			if (EditorActor.IsValid())
			{
				EditorActor.Get().DestroyActor();
				EditorActor = nullptr;
			}

			bShowingVisualizers = false;
		}
#endif
	}
}

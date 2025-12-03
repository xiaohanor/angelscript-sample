#if EDITOR
class UPassbyishTriggerEditorComponent : USceneComponent
{
	UPROPERTY()
	bool bSetInitialPosition = false;
}

class UPassbyishTriggerEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPassbyishTriggerEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		APassbyishTriggerVolume PassbyVolume = Cast<APassbyishTriggerVolume>(Component.GetOwner());
		UPassbyishTriggerEditorComponent Comp = Cast<UPassbyishTriggerEditorComponent>(Component);

        if (PassbyVolume == nullptr || Comp == nullptr)
            return;

		if(!Comp.bSetInitialPosition)
		{
			PassbyVolume.SoundPosition.SetLocation(PassbyVolume.GetActorLocation());
			Comp.bSetInitialPosition = true;
		}

		SetRenderForeground(true);

		SetHitProxy(n"SelectSoundPosition", EVisualizerCursor::CardinalCross);
		DrawWireSphere(PassbyVolume.SoundPosition.GetLocation(), 300.0, Color = FLinearColor::Yellow, Thickness = 10);

		const FVector ClosestPointToCamera = PassbyVolume.FindClosestPoint(EditorViewLocation);
		const float DistToVolumeFromCameraPerspective = ClosestPointToCamera.Distance(PassbyVolume.SoundPosition.Location);
		DrawDashedLine(PassbyVolume.SoundPosition.GetLocation(), ClosestPointToCamera, FLinearColor::Yellow);
		DrawPoint(ClosestPointToCamera, FLinearColor::Yellow, Size = 30);

		DrawWorldString(f"{DistToVolumeFromCameraPerspective :.1}", PassbyVolume.GetActorLocation(), Color = FLinearColor::Yellow);
		ClearHitProxy();

		SetHitProxy(n"PassbyishVolume", EVisualizerCursor::CardinalCross);
		DrawWireBox(PassbyVolume.BrushComponent.BoundsOrigin, PassbyVolume.BrushComponent.GetBoundingBoxExtents(), PassbyVolume.BrushComponent.RelativeRotation.Quaternion(), Thickness = 1.0);
		ClearHitProxy();

		PassbyVolume.bHasSoundDefAsset = PassbyVolume.AudioAsset.GetSoundAssetType() == EHazeSpotSoundAssetType::SoundDef;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		UPassbyishTriggerEditorComponent Comp = Cast<UPassbyishTriggerEditorComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		if(HitProxy.IsEqual(n"SelectSoundPosition"))
		{
			Editor::SelectComponent(Comp, bActivateVisualizer = true);
			return true;
		}
		else if(HitProxy.IsEqual(n"PassbyishVolume"))
		{
			Editor::SelectActor(Comp.GetOwner());
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		UPassbyishTriggerEditorComponent Comp = Cast<UPassbyishTriggerEditorComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		APassbyishTriggerVolume PassbyVolume = Cast<APassbyishTriggerVolume>(Comp.GetOwner());
		OutLocation = PassbyVolume.SoundPosition.GetLocation();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		UPassbyishTriggerEditorComponent Comp = Cast<UPassbyishTriggerEditorComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		APassbyishTriggerVolume PassbyVolume = Cast<APassbyishTriggerVolume>(Comp.GetOwner());

		PassbyVolume.Modify();
		FTransform DeltaTransform = FTransform(DeltaRotate, DeltaTranslate, DeltaScale);

		PassbyVolume.SoundPosition.Accumulate(DeltaTransform);
		PassbyVolume.PassbyTransform.Location = PassbyVolume.GetActorTransform().InverseTransformPosition(PassbyVolume.SoundPosition.Location);

		return true;
	}

	void MoveActorToCursor(AActor ActorToMove)
	{
		FVector Location;
		FQuat Rotation;
		if (LevelEditor::GetActorPlacementPositionAtCursor(Location, Rotation))
		{
			APassbyishTriggerVolume PassbyVolume = Cast<APassbyishTriggerVolume>(ActorToMove);

			Editor::BeginTransaction("Moving Passbyish to cursor location", PassbyVolume);
			PassbyVolume.Modify();
			PassbyVolume.SetActorLocation(Location);
			PassbyVolume.SoundPosition = FTransform(
					PassbyVolume.PassbyTransform.Rotation,
					PassbyVolume.ActorTransform.TransformPosition(PassbyVolume.PassbyTransform.Location),
					PassbyVolume.PassbyTransform.Scale3D);

			Editor::EndTransaction();
			Editor::RedrawAllViewports();

			Editor::SelectActor(ActorToMove, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputKey(FKey Key, EInputEvent Event)
	{
		UPassbyishTriggerEditorComponent Comp = Cast<UPassbyishTriggerEditorComponent>(EditingComponent);
        if (Comp == nullptr)
            return false;

		if (Key == EKeys::V && IsShiftPressed())
		{
			MoveActorToCursor(Comp.Owner);
		}

		if (Event != EInputEvent::IE_Pressed)
			return false;

		if (Key == EKeys::C && IsControlPressed())
		{
			TArray<AActor> Actors;
			Actors.Add(Comp.Owner);
			Editor::CopyToClipBoard(Editor::CopyActorsIntoString(Actors));

			return true;
		}
		else if (Key == EKeys::V && IsControlPressed())
		{
			TArray<AActor> Actors;
			Actors.Add(Comp.Owner);

			FString ClipBoardCopy;
			Editor::PasteFromClipBoard(ClipBoardCopy);

			auto NewActors = Editor::PasteActorsFromString(Comp.Owner.Level, ClipBoardCopy);
			for (auto Actor: NewActors)
				MoveActorToCursor(Actor);
			return true;
		}


		return false;
	}
}

#endif

class UPropLineDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = APropLine;

	UPropLinePreset PrevPreset = nullptr;
	UHazeImmediateDrawer PresetDrawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		APropLine PropLine = Cast<APropLine>(GetCustomizedObject());

		HideCategory(n"LOD");
		HideCategory(n"RayTracing");
		HideCategory(n"TextureStreaming");
		HideCategory(n"Prop Line Preset");
		HideCategory(n"Prop Line Internals");

		// Hide prop line settings if a preset is selected
		PrevPreset = PropLine.Preset;
		if (PropLine.Preset != nullptr)
		{
			HideCategory(n"Prop Line");
			HideCategory(n"Prop Line Dividers");
		}

		AddDefaultProperty(n"Prop Line Assets", n"Preset");

		// Don't show the merged mesh unless we have one
		if (PropLine.MergedMeshes.Num() != 0)
		{
			AddDefaultProperty(n"Prop Line Assets", n"MergedMeshes");
		}

		// If we don't have a preset, give the option to save settings
		PresetDrawer = AddImmediateRow(n"Prop Line Assets", "Preset", false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		APropLine PropLine = Cast<APropLine>(GetCustomizedObject());
		if (PropLine == nullptr)
			return;

		// Refresh details if our preset changes
		if (PropLine.Preset != PrevPreset)
		{
			PrevPreset = PropLine.Preset;
			ForceRefresh();
			return;
		}

		// Draw button in the preset view
		if (PresetDrawer != nullptr && PresetDrawer.IsVisible())
		{
			auto VertBox = PresetDrawer.BeginVerticalBox();

			if (PropLine.Preset == nullptr)
			{
				if (PropLine.MergedMeshes.Num() != 0)
				{
					VertBox.Spacer(10);
					VertBox
						.SlotHAlign(EHorizontalAlignment::HAlign_Center)
						.Text("Prop Line has been merged, edits won't be visible until merged meshes are refreshed.")
						.AutoWrapText()
						.Color(FLinearColor(1.00, 0.60, 0.00))
					;
				}

				{
					auto ButtonBox = VertBox
						.SlotHAlign(EHorizontalAlignment::HAlign_Center)
						.WrapBox()
						.WrapSize(VertBox.GetWidgetGeometrySize().X)
						.SlotHAlign(EHorizontalAlignment::HAlign_Center)
					;
					if (PropLine.MergedMeshes.Num() == 0)
					{
						if (ButtonBox
							.BorderBox()
								.MinDesiredWidth(120)
							.Button("🛠️ Merge Mesh")
							.Padding(10, 8)
							.Tooltip("Merge all meshes in this prop line into a single replacement mesh.")
						)
						{
							MergeMesh();
							return;
						}
					}
					else
					{
						if (ButtonBox
							.BorderBox()
								.MinDesiredWidth(150)
							.Button("🛠️ Refresh Merged Mesh")
							.Padding(10, 8)
							.Tooltip("Refresh the merged replacement mesh for this prop line.")
						)
						{
							MergeMesh();
							return;
						}
					}

					if (ButtonBox
						.BorderBox()
							.MinDesiredWidth(120)
						.Button("🎛️ Save Preset")
						.Padding(10, 8)
						.Tooltip("Save the current settings on this actor as a preset that can be used on other prop lines.")
					)
					{
						SavePreset();
					}

					if (ButtonBox
						.BorderBox()
							.MinDesiredWidth(120)
						.Button("✏️ Draw Spline")
						.Padding(10, 8)
						.Tooltip("Open the Draw Spline editor tool to draw the spline onto the surrounding geometry.")
					)
					{
						OpenDrawTool();
					}
				}
			}

			// Display errors for the prop line if we have any
			{
				for (FPropLineMesh Mesh : PropLine.Settings.Meshes)
				{
					if (Mesh.Mesh.StaticMesh == nullptr)
						continue;
					float MeshSize = Mesh.CalculateMeshSizeInSegment(PropLine.Settings.bPlaceMeshesOnPivot && PropLine.GetSegmentType(0) != EPropLineSegmentType::SplineMesh);
					if (MeshSize <= 0.001)
					{
						VertBox.Spacer(10);
						VertBox
							.Text(f"Error: Mesh {Mesh.Mesh.StaticMesh.Name} will not be generated, because it has an invalid Origin fully at the front of the mesh, or has a bounds size of 0.")
							.AutoWrapText()
							.Color(FLinearColor::Red)
							.Scale(1.2)
						;
					}
				}
			}
		}

		// Set a nice actor label 
		FString PropLineLabelTag;
		if (PropLine.Preset != nullptr)
			PropLineLabelTag = PropLine.Preset.Name.PlainNameString;
		else if (PropLine.Settings.Meshes.Num() == 1 && PropLine.Settings.Meshes[0].Mesh.StaticMesh != nullptr)
			PropLineLabelTag = PropLine.Settings.Meshes[0].Mesh.StaticMesh.Name.PlainNameString;

		if (!PropLineLabelTag.IsEmpty())
		{
			bool bChangeLabel = false;
			FString Label = PropLine.GetActorLabel();
			if (Label.StartsWith("PropLine "))
			{
				bChangeLabel = true;
			}
			else if (Label.StartsWith("PropLine"))
			{
				FString Number = Label.Mid(8);
				if (Number.IsEmpty() || Number.IsNumeric())
					bChangeLabel = true;
			}

			if (bChangeLabel)
			{
				FString NewLabel = f"PropLine {PropLineLabelTag}";
				if (!Label.StartsWith(NewLabel))
					Editor::SetActorLabelUnique(PropLine, NewLabel+" 1");
			}
		}
	}

	void OpenDrawTool()
	{
		GetGlobalSplineSelection().bSplineDrawWasTemporary = true;
		Blutility::ActivateEditorTool(UHazeSplineDrawTool);
	}

	void SavePreset()
	{
		APropLine PropLine = Cast<APropLine>(GetCustomizedObject());
		if (PropLine == nullptr)
			return;

		UPropLinePreset TransientPreset = UPropLinePreset();
		TransientPreset.Settings = PropLine.Settings;

		UObject SavedAsset = Editor::SaveAssetAsNewPath(TransientPreset);
		if (SavedAsset == nullptr)
			return;

		{
			FScopedTransaction Transaction("Save Prop Line Settings as Preset");
			PropLine.Modify();
			PropLine.Preset = Cast<UPropLinePreset>(SavedAsset);
			NotifyPropertyModified(PropLine, n"Preset");
			PropLine.UpdatePropLine();
			PropLine.RerunConstructionScripts();
		}

		Editor::RedrawAllViewports();
		ForceRefresh();
	}

	void MergeMesh()
	{
		APropLine PropLine = Cast<APropLine>(GetCustomizedObject());
		if (PropLine == nullptr)
			return;

		FScopedTransaction Transaction("Generate Prop Line Merged Mesh");
		PropLine.Modify();

		PropLine.MergedMeshes.Reset();
		PropLine.UpdatePropLine();
		PropLine.RerunConstructionScripts();

		TArray<FVector> SegmentOrigins;
		TArray<int> SegmentCounts;

		TArray<int> SegmentIndices;

		TArray<UPrimitiveComponent> ComponentsToMerge;
		PropLine.GetComponentsByClass(ComponentsToMerge);

		// Create segment origins for each component that needs one
		{
			FAngelscriptExcludeScopeFromLoopTimeout ExcludeTimeout;
			for (UPrimitiveComponent Mesh : ComponentsToMerge)
			{
				// Check if any segment can contain this
				bool bFoundSegment = false;
				for (int SegmentIndex = 0, SegmentCount = SegmentOrigins.Num(); SegmentIndex < SegmentCount; ++SegmentIndex)
				{
					float MeshSize = Mesh.BoundsRadius;
					if (SegmentCounts[SegmentIndex] >= PropLine.MaximumSegmentsPerMergedMesh)
						continue;

					if (SegmentOrigins[SegmentIndex].Distance(Mesh.WorldLocation) + MeshSize < PropLine.MaximumMergedMeshSize)
					{
						SegmentCounts[SegmentIndex] += 1;
						bFoundSegment = true;
						break;
					}
				}

				// Might need to create a new segment
				if (!bFoundSegment)
				{
					SegmentOrigins.Add(Mesh.WorldLocation);
					SegmentCounts.Add(1);
				}
			}

			for (int SegmentIndex = 0, SegmentCount = SegmentOrigins.Num(); SegmentIndex < SegmentCount; ++SegmentIndex)
				SegmentCounts[SegmentIndex] = 0;

			// Divide components into the segments
			for (int CompIndex = 0, CompCount = ComponentsToMerge.Num(); CompIndex < CompCount; ++CompIndex)
			{
				int ClosestSegmentIndex = 0;
				float ClosestSegmentDistance = MAX_flt;

				for (int SegmentIndex = 0, SegmentCount = SegmentOrigins.Num(); SegmentIndex < SegmentCount; ++SegmentIndex)
				{
					if (SegmentCounts[SegmentIndex] >= PropLine.MaximumSegmentsPerMergedMesh)
						continue;
					float Distance = SegmentOrigins[SegmentIndex].Distance(ComponentsToMerge[CompIndex].WorldLocation);
					if (Distance < ClosestSegmentDistance)
					{
						ClosestSegmentIndex = SegmentIndex;
						ClosestSegmentDistance = Distance;
					}
				}

				SegmentIndices.Add(ClosestSegmentIndex);
				SegmentCounts[ClosestSegmentIndex] += 1;
			}
		}

		FString LevelName = FPaths::GetBaseFilename(PropLine.Level.Outermost.Name.ToString());
		FString FirstMeshName = "Unknown";
		if (PropLine.Settings.Meshes.Num() != 0 && PropLine.Settings.Meshes[0].Mesh.StaticMesh != nullptr)
			FirstMeshName = PropLine.Settings.Meshes[0].Mesh.StaticMesh.Name.ToString();

		// Create a merged mesh for each segment
		for (int SegmentIndex = 0, SegmentCount = SegmentOrigins.Num(); SegmentIndex < SegmentCount; ++SegmentIndex)
		{
			FAngelscriptExcludeScopeFromLoopTimeout ExcludeTimeout;

			TArray<UPrimitiveComponent> ComponentsInSegment;
			for (int CompIndex = 0, CompCount = ComponentsToMerge.Num(); CompIndex < CompCount; ++CompIndex)
			{
				if (SegmentIndices[CompIndex] == SegmentIndex)
					ComponentsInSegment.Add(ComponentsToMerge[CompIndex]);
			}

			FMeshMergingSettings Settings;
			Settings.LODSelectionType = EMeshLODSelectionType::AllLODs;
			Settings.bMergePhysicsData = true;
			Settings.bBakeVertexDataToMesh = true;

			FVector MergedLocation;
			FString AssetPath = f"/Game/Environment/Generated/MergedPropLines/{LevelName}/{PropLine.Name}_{FirstMeshName}_{SegmentIndex}";

			TArray<UObject> AssetsToSync;
			Editor::MergeComponentsToStaticMesh(
				ComponentsInSegment,
				PropLine.GetWorld(),
				Settings,
				AssetPath,
				AssetsToSync,
				MergedLocation
			);

			for (UObject CreatedAsset : AssetsToSync)
			{
				// Make the Content Browser aware of our newly created assets,				
				AssetRegistry::AssetCreated(CreatedAsset);
			}

			if (AssetsToSync.Num() != 0)
			{
				auto MergedMesh = Cast<UStaticMesh>(AssetsToSync[0]);
				MergedMesh.Modify();

				FPropLineMergedMeshData MergedData;
				MergedData.RelativeTransform = FTransform(
					PropLine.ActorQuat.Inverse(),
					PropLine.ActorTransform.InverseTransformPosition(MergedLocation),
					FVector::OneVector / PropLine.ActorScale3D,
				);
				MergedData.StaticMesh = MergedMesh;
				PropLine.MergedMeshes.Add(MergedData);
			}
		}

		PropLine.UpdatePropLine();
		PropLine.RerunConstructionScripts();

		ForceRefresh();
	}
}
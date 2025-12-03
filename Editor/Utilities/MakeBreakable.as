class UMakeBreakable : UScriptAssetMenuExtension {
	default SupportedClasses.Add(UStaticMesh);

	UFUNCTION(CallInEditor, Category = "Breakable")
	void ClearVertexColor()
	{
		// Just like breakable but we use the bounds bottom instead of bounds relative center.z

		// Get the first selected mesh asset,
		UStaticMesh Mesh;
		for (UObject Asset : EditorUtility::GetSelectedAssets() ) {
			Mesh = Cast<UStaticMesh>(Asset);
			if (Mesh != nullptr)
				break;
		}

		UDynamicMeshPool DynamicMeshPool = GeometryScript_SceneUtils::CreateDynamicMeshPool();

		UDynamicMesh DynamicMesh = DynamicMeshPool.RequestMesh();

		FGeometryScriptCopyMeshFromAssetOptions Options;
		FGeometryScriptMeshReadLOD RequestedLOD;
		EGeometryScriptOutcomePins Result = EGeometryScriptOutcomePins::Failure; // Init as failed,
		GeometryScript_AssetUtils::CopyMeshFromStaticMesh(Mesh, DynamicMesh, Options, RequestedLOD, Result);

		if(Result == EGeometryScriptOutcomePins::Failure) {
			Log("Failed to create dynamic mesh from static mesh");
			return;
		}

		// Split the mesh into all separate components,
		TArray<UDynamicMesh> Components;
		GeometryScript_MeshDecomposition::SplitMeshByComponents(DynamicMesh, Components, DynamicMeshPool);

		UDynamicMesh IntermediaryMesh = DynamicMeshPool.RequestMesh();

		for (UDynamicMesh Component : Components) {
			FBox ComponentBounds = GeometryScript_MeshQueries::GetMeshBoundingBox(Component);
			
			GeometryScript_VertexColors::SetMeshConstantVertexColor( Component, FLinearColor(1,1,1,1), FGeometryScriptColorFlags());

			GeometryScript_MeshEdits::AppendMesh(IntermediaryMesh, Component, FTransform(), false, FGeometryScriptAppendMeshOptions());
		}

		// Merge the split components into an intermediary dynamic mesh, then copy the mesh to the original static mesh asset.
		GeometryScript_AssetUtils::CopyMeshToStaticMesh(IntermediaryMesh, Mesh, FGeometryScriptCopyMeshToAssetOptions(), FGeometryScriptMeshWriteLOD(), Result);

		DynamicMeshPool.FreeAllMeshes();
	}
	UFUNCTION(CallInEditor, Category = "Breakable")
	void GrassPivots() {
		// Just like breakable but we use the bounds bottom instead of bounds relative center.z

		// Get the first selected mesh asset,
		UStaticMesh Mesh;
		for (UObject Asset : EditorUtility::GetSelectedAssets() ) {
			Mesh = Cast<UStaticMesh>(Asset);
			if (Mesh != nullptr)
				break;
		}

		UDynamicMeshPool DynamicMeshPool = GeometryScript_SceneUtils::CreateDynamicMeshPool();

		UDynamicMesh DynamicMesh = DynamicMeshPool.RequestMesh();

		FGeometryScriptCopyMeshFromAssetOptions Options;
		FGeometryScriptMeshReadLOD RequestedLOD;
		EGeometryScriptOutcomePins Result = EGeometryScriptOutcomePins::Failure; // Init as failed,
		GeometryScript_AssetUtils::CopyMeshFromStaticMesh(
			Mesh, 
			DynamicMesh,
			Options,
			RequestedLOD,
			Result
		);

		if(Result == EGeometryScriptOutcomePins::Failure) {
			Log("Failed to create dynamic mesh from static mesh");
			return;
		}

		// Split the mesh into all separate components,
		TArray<UDynamicMesh> Components;
		GeometryScript_MeshDecomposition::SplitMeshByComponents(DynamicMesh, Components, DynamicMeshPool);

		UDynamicMesh IntermediaryMesh = DynamicMeshPool.RequestMesh();

		for (UDynamicMesh Component : Components) {
			FBox ComponentBounds = GeometryScript_MeshQueries::GetMeshBoundingBox(Component);
			
			// Get the current component center relative to the bounding box,
			FVector BoundsRelativeCenter = (ComponentBounds.Center / 500.0) * FVector(0.5) + FVector(0.5);

			GeometryScript_VertexColors::SetMeshConstantVertexColor(
				Component, 
				FLinearColor(
					BoundsRelativeCenter.X, 
					BoundsRelativeCenter.Y, 
					(Mesh.BoundingBox.Min.Z / 500.0) * 0.5 + 0.5, 
					Math::RandRange(Min=0.0, Max=1.0)), // Color, but mapped Y-up right handed...
				FGeometryScriptColorFlags()
			);

			GeometryScript_MeshEdits::AppendMesh(IntermediaryMesh, Component, FTransform(), false, FGeometryScriptAppendMeshOptions());
		}

		// Merge the split components into an intermediary dynamic mesh, then copy the mesh to the original static mesh asset.
		GeometryScript_AssetUtils::CopyMeshToStaticMesh(
			IntermediaryMesh,
			Mesh,
			FGeometryScriptCopyMeshToAssetOptions(),
			FGeometryScriptMeshWriteLOD(),
			Result
		);

		DynamicMeshPool.FreeAllMeshes();
	}

	UFUNCTION(CallInEditor, Category = "Breakable")
	void MakeBreakable() {

		// Get the first selected mesh asset,
		UStaticMesh Mesh;
		for (UObject Asset : EditorUtility::GetSelectedAssets() ) {
			Mesh = Cast<UStaticMesh>(Asset);
			if (Mesh != nullptr)
				break;
		}

		UDynamicMeshPool DynamicMeshPool = GeometryScript_SceneUtils::CreateDynamicMeshPool();

		UDynamicMesh DynamicMesh = DynamicMeshPool.RequestMesh();

		FGeometryScriptCopyMeshFromAssetOptions Options;
		FGeometryScriptMeshReadLOD RequestedLOD;
		EGeometryScriptOutcomePins Result = EGeometryScriptOutcomePins::Failure; // Init as failed,
		GeometryScript_AssetUtils::CopyMeshFromStaticMesh(
			Mesh, 
			DynamicMesh,
			Options,
			RequestedLOD,
			Result
		);

		if(Result == EGeometryScriptOutcomePins::Failure) {
			Log("Failed to create dynamic mesh from static mesh");
			return;
		}

		// Split the mesh into all separate components,
		TArray<UDynamicMesh> Components;
		GeometryScript_MeshDecomposition::SplitMeshByComponents(DynamicMesh, Components, DynamicMeshPool);

		UDynamicMesh IntermediaryMesh = DynamicMeshPool.RequestMesh();

		for (UDynamicMesh Component : Components) {
			FBox ComponentBounds = GeometryScript_MeshQueries::GetMeshBoundingBox(Component);
			
			// Get the current component center relative to the bounding box,
			FVector BoundsRelativeCenter = FVector(0.5, 0.5, 0.5) * (FVector(1.0, 1.0, 1.0) + (ComponentBounds.Center - Mesh.BoundingBox.Center) / (Mesh.BoundingBox.Max - Mesh.BoundingBox.Min));

			GeometryScript_VertexColors::SetMeshConstantVertexColor(
				Component, 
				FLinearColor(1.0 - BoundsRelativeCenter.Y, BoundsRelativeCenter.Z, BoundsRelativeCenter.X, Math::RandRange(Min=0.0, Max=1.0)), // Color, but mapped Y-up right handed...
				FGeometryScriptColorFlags()
			);

			GeometryScript_MeshEdits::AppendMesh(IntermediaryMesh, Component, FTransform(), false, FGeometryScriptAppendMeshOptions());
		}

		// Merge the split components into an intermediary dynamic mesh, then copy the mesh to the original static mesh asset.
		GeometryScript_AssetUtils::CopyMeshToStaticMesh(
			IntermediaryMesh,
			Mesh,
			FGeometryScriptCopyMeshToAssetOptions(),
			FGeometryScriptMeshWriteLOD(),
			Result
		);

		DynamicMeshPool.FreeAllMeshes();
	}

	UFUNCTION(CallInEditor, Category = "Breakable")
	void MergeStaticMeshes() 
	{
		UDynamicMeshPool DynamicMeshPool = GeometryScript_SceneUtils::CreateDynamicMeshPool();
		UDynamicMesh DynamicMesh = DynamicMeshPool.RequestMesh();
		UDynamicMesh DynamicMesh_2 = DynamicMeshPool.RequestMesh();

		EGeometryScriptOutcomePins Result = EGeometryScriptOutcomePins::Failure; // Init as failed,

		// Get the first selected mesh asset,
		UStaticMesh Mesh;
		auto Majs = EditorUtility::GetSelectedAssets();
		for (UObject Asset : Majs ) 
		{
			Mesh = Cast<UStaticMesh>(Asset);
			// if (Mesh != nullptr)
			// 	break;

			FGeometryScriptCopyMeshFromAssetOptions Options;
			FGeometryScriptMeshReadLOD RequestedLOD;
			GeometryScript_AssetUtils::CopyMeshFromStaticMesh(
				Mesh, 
				DynamicMesh,
				Options,
				RequestedLOD,
				Result
			);

			GeometryScript_MeshEdits::AppendMesh(DynamicMesh_2, DynamicMesh, FTransform(), false, FGeometryScriptAppendMeshOptions());
		}


		// Merge the split components into an intermediary dynamic mesh, then copy the mesh to the original static mesh asset.
		GeometryScript_AssetUtils::CopyMeshToStaticMesh(
			DynamicMesh_2,
			Mesh,
			FGeometryScriptCopyMeshToAssetOptions(),
			FGeometryScriptMeshWriteLOD(),
			Result
		);

		DynamicMeshPool.FreeAllMeshes();
	}

}

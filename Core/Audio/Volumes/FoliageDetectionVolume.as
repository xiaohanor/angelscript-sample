enum EFoliageDetectionType
{
	Grass,
	Bush,
	Plant,
};

struct FFoliageDetectionInfo
{
	UPROPERTY()
	TSoftObjectPtr<UStaticMesh> Mesh;
	UPROPERTY()
	EFoliageDetectionType Type;
	UPROPERTY()
	float AddedBoundsRadius;
};

class UFoliageDetectionPreset : UDataAsset
{
	UPROPERTY(EditAnywhere, Category = "Foliage")
	TArray<FFoliageDetectionInfo> FoliageTypes;
}

UCLASS(HideCategories = "EditorRendering Navigation Collision BrushSettings Rendering Actor Cooking")
class AFoliageDetectionVolume : AVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

#if EDITORONLY_DATA
	UPROPERTY(EditAnywhere, Category = "Foliage")
	UFoliageDetectionPreset Preset;

	UPROPERTY(EditAnywhere, Category = "Foliage", Meta = (EditCondition = "Preset == nullptr", EditConditionHides))
	TArray<FFoliageDetectionInfo> FoliageTypes;

	UPROPERTY(EditAnywhere, Category = "Foliage", Meta = (EditCondition = "false", EditConditionHides))
	access:Internal TArray<TSoftObjectPtr<UStaticMesh>> MeshesToVisualizeInEditor;
	UPROPERTY(EditAnywhere, Category = "Foliage", Meta = (EditCondition = "false", EditConditionHides))
	access:Internal bool bVisualizeBasedOnMeshInEditor = false;
#endif

	access Internal = private, UFoliageDetectionVolumeDetailCustomization;

	UPROPERTY(VisibleAnywhere, Category = "Internal Data", Meta = (EditCondition = "false", EditConditionHides))
	access:Internal FStaticSparseSphereGrid SparseGrid;
	private TPerPlayer<FPlayerFoliageDetectionState> PerPlayerOverlapState;


	UPROPERTY(EditInstanceOnly, Category = "Foliage", EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EFoliageDetectionType"))
	TArray<UPhysicalMaterialAudioAsset> MaterialOverridesPerType;
	default MaterialOverridesPerType.SetNum(int(EFoliageDetectionType::Plant) + 1);

	/**
	 * Called when the player overlaps foliage of a specific density.
	 * Will be called multiple times if the density changes.
	 */
	void OnPlayerOverlapFoliageChange(AHazePlayerCharacter Player, bool bIsOverlappingFoliage, EFoliageDetectionType Type)
	{
#if EDITOR
		if (bHazeEditorOnlyDebugBool)
		{
			if (bIsOverlappingFoliage)
				Print(f"{Player.Name} is inside foliage with type {Type :n}");
			else
				Print(f"{Player.Name} is no longer inside foliage");
		}
#endif
		auto Data = FFoliageDetectionData();
		Data.bIsOverlappingFoliage = bIsOverlappingFoliage;
		Data.Type = Type;
		if (bIsOverlappingFoliage)
			Data.MaterialOverride = MaterialOverridesPerType[int(Type)];
		
		UFoliageDetectionEventHandler::Trigger_FoliageOverlapEvent(Player, Data);
	}

	/**
	 * Find the kind of foliage that is overlapping the player.
	 */
	bool FindOverlappingFoliage(AHazePlayerCharacter Player, EFoliageDetectionType& OutType) const
	{
		int InstanceData = 0;
		FVector4f InstanceBounds;

		bool bHasOverlap = SparseGrid.GetOverlappingSphere(
			ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation),
			Player.CapsuleComponent.ScaledCapsuleRadius,
			InstanceData, InstanceBounds,
			true
		);

		if (bHasOverlap)
		{
			OutType = EFoliageDetectionType(InstanceData & 0xff);
			return true;
		}
		else
		{
			return false;
		}
	}

	/**
	 * Find the kind of foliage that is overlapping a sphere in the world.
	 */
	bool FindOverlappingFoliage(FVector SphereOrigin, float SphereRadius, EFoliageDetectionType& OutType) const
	{
		int InstanceData = 0;
		FVector4f InstanceBounds;

		bool bHasOverlap = SparseGrid.GetOverlappingSphere(
			ActorTransform.InverseTransformPositionNoScale(SphereOrigin),
			SphereRadius,
			InstanceData, InstanceBounds,
			true
		);

		if (bHasOverlap)
		{
			OutType = EFoliageDetectionType(InstanceData & 0xff);
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			PerPlayerOverlapState[Player].bOverlappingVolume = true;
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			PerPlayerOverlapState[Player].bOverlappingVolume = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Determine which type of foliage each player is in
		bool bAnyPlayerInVolume = false;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FPlayerFoliageDetectionState& State = PerPlayerOverlapState[Player];
			if (!State.bOverlappingVolume)
			{
				if (State.bOverlappingFoliage)
				{
					// Remove the overlap once we've left the volume
					OnPlayerOverlapFoliageChange(Player, false, EFoliageDetectionType::Grass);
					State.bOverlappingFoliage = false;
					State.ActiveType = EFoliageDetectionType::Grass;
				}
			}
			else
			{
				EFoliageDetectionType NewType = EFoliageDetectionType::Grass;
				bool bNewOverlap = FindOverlappingFoliage(Player, NewType);
				if (bNewOverlap != State.bOverlappingFoliage || NewType != State.ActiveType)
				{
					State.bOverlappingFoliage = bNewOverlap;
					State.ActiveType= NewType;
					OnPlayerOverlapFoliageChange(Player, bNewOverlap, NewType);
				}

				bAnyPlayerInVolume = true;
			}
		}

		// Stop ticking once both players are outside the volume
		if (!bAnyPlayerInVolume)
			SetActorTickEnabled(false);

#if EDITOR
		if (bHazeEditorOnlyDebugBool)
			DebugDrawOverlappingFoliage();
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Preset != nullptr)
			FoliageTypes = Preset.FoliageTypes;
	}

	// Can take a loooong time!
	UFUNCTION(CallInEditor, Category = "Editor")
	void RebuildAllFoliageVolumes()
	{
		// An easier way to update a whole level.
		TArray<AFoliageDetectionVolume> AllFoliageActors = Editor::GetAllEditorWorldActorsOfClass(AFoliageDetectionVolume);

		FString LogReport = "";
		for (auto FoliageActor: AllFoliageActors)
		{
			int PreviousInstanceCount = FoliageActor.SparseGrid.InstanceData.Num();
			FoliageActor.BuildFoliageVolume();
			LogReport += (f"{FoliageActor.ActorNameOrLabel} - Count; Previous {PreviousInstanceCount}, New {FoliageActor.SparseGrid.InstanceData.Num()} \n");
		}

		Log(f"Foliage rebuild; \n {LogReport}");
	}

	UFUNCTION(CallInEditor, Category = "Editor")
	void BuildFoliageVolume()
	{
		FAngelscriptExcludeScopeFromLoopTimeout ExcludeScope;

		if (Preset != nullptr)
			FoliageTypes = Preset.FoliageTypes;

		TSet<UStaticMesh> FoliageMeshes;
		for (auto FoliageType : FoliageTypes)
			FoliageMeshes.Add(Cast<UStaticMesh>(LoadObject(nullptr, FoliageType.Mesh.ToString())));

		FTransform VolumeTransform = ActorTransform;

		TArray<FSparseSphereInstance> Instances;

		// Find all instances of this mesh that are Static Mesh Components
		TArray<AActor> AllActors = Editor::GetAllEditorWorldActorsOfClass(AActor);
		for (AActor Actor : AllActors)
		{
			TArray<UStaticMeshComponent> Components;
			Actor.GetComponentsByClass(Components);

			for (UStaticMeshComponent MeshComp : Components)
			{
				if (MeshComp.StaticMesh == nullptr)
					continue;
				if (!FoliageMeshes.Contains(MeshComp.StaticMesh))
					continue;

				float BoundsRadius = MeshComp.StaticMesh.Bounds.SphereRadius;
				if (!EncompassesPoint(MeshComp.WorldLocation, BoundsRadius))
					continue;

				for (int TypeIndex = 0, TypeCount = FoliageTypes.Num(); TypeIndex < TypeCount; ++TypeIndex)
				{
					if (FoliageTypes[TypeIndex].Mesh == MeshComp.StaticMesh)
					{
						FSparseSphereInstance Instance;
						Instance.Origin = FVector3f(VolumeTransform.InverseTransformPositionNoScale(MeshComp.WorldLocation));
						Instance.Radius = float32((BoundsRadius + FoliageTypes[TypeIndex].AddedBoundsRadius) * MeshComp.WorldScale.AbsMax);
						Instance.InstanceData = (TypeIndex << 8) | int32(FoliageTypes[TypeIndex].Type);

						Instances.Add(Instance);
						break;
					}
				}
			}
		}

		// Find all instances of this mesh that are Instanced Foliage
		FBox VolumeBounds = GetBounds().Box;
		TArray<FTransform> InstanceTransforms;

		for (int TypeIndex = 0, TypeCount = FoliageTypes.Num(); TypeIndex < TypeCount; ++TypeIndex)
		{
			const FFoliageDetectionInfo& FoliageType = FoliageTypes[TypeIndex];
			if (FoliageType.Mesh == nullptr)
				continue;
			InstanceTransforms.Reset();
			UFoliageStatistics::FoliageOverlappingBoxTransforms(
				FoliageType.Mesh.Get(), VolumeBounds, InstanceTransforms
			);

			float BoundsRadius = FoliageType.Mesh.Get().Bounds.SphereRadius;
			for (FTransform Transform : InstanceTransforms)
			{
				if (!EncompassesPoint(Transform.Location, BoundsRadius))
					continue;

				FSparseSphereInstance Instance;
				Instance.Origin = FVector3f(VolumeTransform.InverseTransformPositionNoScale(Transform.Location));
				Instance.Radius = float32((BoundsRadius + FoliageType.AddedBoundsRadius) * Transform.Scale3D.AbsMax);
				Instance.InstanceData = (TypeIndex << 8) | int32(FoliageType.Type);

				Instances.Add(Instance);
			}
		}

		SparseGrid = FStaticSparseSphereGrid::Generate(Instances);
	}

	private void DebugDrawOverlappingFoliage()
	{
		PrintToScreenScaled(f"Foliage Detection Memory Size: {SparseGrid.GetAllocatedSize() / 1024.0 :.1} KiB");

		for (auto Player : Game::Players)
		{
			int InstanceData = 0;
			FVector4f InstanceBounds;

			float StartTime = Time::PlatformTimeSeconds;
			bool bHasOverlap = SparseGrid.GetOverlappingSphere(
				ActorTransform.InverseTransformPositionNoScale(Player.ActorLocation),
				Player.CapsuleComponent.ScaledCapsuleRadius,
				InstanceData, InstanceBounds,
				true
			);
			float EndTime = Time::PlatformTimeSeconds;

			PrintToScreenScaled(f"{Player.Name} Foliage Lookup Took {(EndTime - StartTime) * 1000.0 :0.3} ms");

			if (bHasOverlap)
			{
				PrintToScreenScaled(f"{Player.Name} Overlapping Foliage With Type {EFoliageDetectionType(InstanceData)}");

				Debug::DrawDebugSphere(
					ActorTransform.TransformPositionNoScale(FVector(InstanceBounds.X, InstanceBounds.Y, InstanceBounds.Z)),
					InstanceBounds.W, LineColor = FLinearColor::Blue
				);
			}
		}
	}
#endif
}

struct FPlayerFoliageDetectionState
{
	bool bOverlappingVolume = false;
	bool bOverlappingFoliage = false;
	EFoliageDetectionType ActiveType = EFoliageDetectionType::Grass;
}

#if EDITOR
class UFoliageDetectionVolumeDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AFoliageDetectionVolume;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Drawer = AddImmediateRow(n"Foliage Detection Volume");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AFoliageDetectionVolume Volume = Cast<AFoliageDetectionVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		if (Drawer == nullptr || !Drawer.IsVisible())
			return;

		auto Root = Drawer.Begin();

		auto Section = Root.Section("Visualize Detected Foliage");

		bool bIsDrawingAll = true;
		for (auto FoliageType : Volume.FoliageTypes)
		{
			if (!Volume.MeshesToVisualizeInEditor.Contains(FoliageType.Mesh))
				bIsDrawingAll = false;
		}

		TMap<int, int> InstanceCounts;
		FTransform ActorTransform = Volume.ActorTransform;
		for (int InstanceIndex = 0, InstanceCount = Volume.SparseGrid.InstanceData.Num(); InstanceIndex < InstanceCount; ++InstanceIndex)
		{
			int InstanceData = Volume.SparseGrid.InstanceData[InstanceIndex];
			int TypeIndex = InstanceData >> 8;
			InstanceCounts.FindOrAdd(TypeIndex, 0) += 1;

			if (bIsDrawingAll || (Volume.FoliageTypes.IsValidIndex(TypeIndex) && Volume.MeshesToVisualizeInEditor.Contains(Volume.FoliageTypes[TypeIndex].Mesh)))
			{
				auto InstanceBounds = Volume.SparseGrid.InstanceBounds[InstanceIndex];

				int ColorIndex = TypeIndex;
				if (!Volume.bVisualizeBasedOnMeshInEditor)
					ColorIndex = InstanceData & 0xff;

				FLinearColor Color = FLinearColor::MakeFromHSV8(uint8((ColorIndex * 777) % 255), 128, 255);
				Debug::DrawDebugSphere(
					ActorTransform.TransformPositionNoScale(FVector(InstanceBounds.X, InstanceBounds.Y, InstanceBounds.Z)),
					InstanceBounds.W, LineColor = Color
				);
			}
		}

		if (InstanceCounts.Num() != 0)
		{
			auto Row = Section.SlotHAlign(EHorizontalAlignment::HAlign_Fill).HorizontalBox();
			auto Checkbox = Row
				.SlotFill(0.1)
				.CheckBox();

			Row
				.SlotFill()
				.Text(f"All Instances")
				.Color(FLinearColor::Green);

			Row
				.SlotFill()
				.Text(f"{Volume.SparseGrid.InstanceData.Num()} Total");

			Checkbox.Checked(bIsDrawingAll);
			if (Checkbox)
			{
				if (!bIsDrawingAll)
				{
					Volume.MeshesToVisualizeInEditor.Reset();
					for (auto FoliageType : Volume.FoliageTypes)
						Volume.MeshesToVisualizeInEditor.Add(FoliageType.Mesh);
				}
			}
			else
			{
				if (bIsDrawingAll)
				{
					Volume.MeshesToVisualizeInEditor.Reset();
				}
			}

			Section.Spacer(10);
		}

		for (auto Elem : InstanceCounts)
		{
			if (!Volume.FoliageTypes.IsValidIndex(Elem.Key))
				continue;

			const FFoliageDetectionInfo& FoliageType = Volume.FoliageTypes[Elem.Key];
			if (FoliageType.Mesh == nullptr)
				continue;

			auto Row = Section.SlotHAlign(EHorizontalAlignment::HAlign_Fill).HorizontalBox();
			auto Checkbox = Row
				.SlotFill(0.1)
				.CheckBox();

			Row
				.SlotFill()
				.Text(f"{FoliageType.Mesh.AssetName}");
			Row
				.SlotFill()
				.Text(f"{Elem.Value} Instances");

			bool bIsDrawing = Volume.MeshesToVisualizeInEditor.Contains(FoliageType.Mesh);
			Checkbox.Checked(bIsDrawing);
			if (Checkbox)
			{
				if (!bIsDrawing)
					Volume.MeshesToVisualizeInEditor.AddUnique(FoliageType.Mesh);
			}
			else
			{
				if (bIsDrawing)
					Volume.MeshesToVisualizeInEditor.Remove(FoliageType.Mesh);
			}
		}

		if (InstanceCounts.Num() == 0)
		{
			Section.Text("No foliage detected.");
		}
		else
		{
			Section.Spacer(10);

			const FName ColorOnMesh = n"Color Based on Mesh";
			const FName ColorOnType = n"Color Based on Type";

			auto Row = Section.SlotHAlign(EHorizontalAlignment::HAlign_Fill).HorizontalBox();
			Row.SlotFill().Text("Visualize:");
			auto Combo = Row.SlotFill().ComboBox();
			Combo.Item(ColorOnMesh);
			Combo.Item(ColorOnType);

			if (Volume.bVisualizeBasedOnMeshInEditor)
				Combo.Value(ColorOnMesh);
			else
				Combo.Value(ColorOnType);

			if (Combo.SelectedItem == ColorOnMesh)
				Volume.bVisualizeBasedOnMeshInEditor = true;
			else
				Volume.bVisualizeBasedOnMeshInEditor = false;
		}

		auto InfoSection = Root.Section("Information");
		InfoSection.Text(f"Memory Size: {Volume.SparseGrid.GetAllocatedSize() / 1024.f :.2} KiB");;

		// Check and show errors if there are any duplicate meshes
		for (int i = 0, Count = Volume.FoliageTypes.Num(); i < Count; ++i)
		{
			for (int j = i+1; j < Count; ++j)
			{
				if (Volume.FoliageTypes[i].Mesh == Volume.FoliageTypes[j].Mesh)
				{
					InfoSection
						.Text(f"Duplicate Foliage Type: {Volume.FoliageTypes[i].Mesh.AssetName}")
						.Color(FLinearColor::Red)
						.Scale(1.3)
					;
				}
			}
		}
	}
}
#endif
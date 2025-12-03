
#if EDITORONLY_DATA
#endif

enum EPropArrayRotationType
{
	// No rotation is applied to meshes in the prop array
	NoRotation,
	// A single static rotation is applied to all meshes
	StaticRotation,
	// Apply a random rotation within a specific range to each mesh
	RandomRotationRange,
	// Apply a random rotation that is a multiple of the specified interval
	RandomRotationInterval,
	// Apply a random rotation multiple of the interval, limited to a specific range
	RandomRotationIntervalLimitedRange,
	// Allow applying all previous options at the same time together
	AdvancedCombination,
};

/**
 * Automatically places a grid of meshes with optional randomized offsets.
 */
UCLASS(HideCategories = "Rendering Replication Collision Debug Input HLOD Actor LOD Cooking DataLayers WorldPartition Physics", Meta = (NoSourceLink))
class APropArray : AHazeBaseProp
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
    default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
    UTagContainerComponent TagContainer;
    default TagContainer.Mobility = EComponentMobility::Static;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "PropArray";
#endif

	// Which meshes to spawn in the prop array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	TArray<FHazePropSettings> Meshes;
	default Meshes.SetNum(1);

	// Randomize the selection of meshes. If false, generates in the order of the Meshes array.
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", AdvancedDisplay)
	bool bUseRandomMeshOrder = true;

	// Offset applied individually to each mesh based on its position
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (MakeEditWidget))
	FVector Offset = FVector(100.0, 0.0, 0.0);

	// How many meshes to spawn in the X dimension
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	int CopiesX = 2;

	// How many meshes to spawn in the Y dimension
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	int CopiesY = 1;

	// How many meshes to spawn in the Z dimension
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	int CopiesZ = 1;

	// Absolute maximum amount of instances that will be generated
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", AdvancedDisplay)
	int MaxInstances = 100;

	// Whether to randomly offset mesh positions
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	bool bRandomPositionOffset = false;

	// Randomized position offset for each mesh in the array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "bRandomPositionOffset", EditConditionHides))
	FVector RandomOffset;

	// How to rotate the meshes in the prop array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	EPropArrayRotationType MeshRotation = EPropArrayRotationType::NoRotation;

	// A single rotation applied to all meshes first
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "MeshRotation == EPropArrayRotationType::StaticRotation || MeshRotation == EPropArrayRotationType::AdvancedCombination", EditConditionHides))
	FRotator StaticRotation;

	// Maximum rotation to randomly offset meshes by
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "MeshRotation == EPropArrayRotationType::RandomRotationRange || MeshRotation == EPropArrayRotationType::AdvancedCombination", EditConditionHides))
	FRotator RandomRotationMax;

	// Interval to randomize the rotation for each mesh
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "MeshRotation == EPropArrayRotationType::RandomRotationInterval || MeshRotation == EPRopArrayRotationType::RandomRotationIntervalLimitedRange || MeshRotation == EPropArrayRotationType::AdvancedCombination", EditConditionHides))
	FRotator IntervalRandomRotation;

	// The rotation applied by the random interval is never more than this
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "MeshRotation == EPropArrayRotationType::RandomRotationIntervalLimitedRange || MeshRotation == EPropArrayRotationType::AdvancedCombination", EditConditionHides))
	FRotator IntervalLimitRotation(360.0, 360.0, 360.0);

	// Whether to randomly scale meshes in the array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	bool bRandomScale = false;

	// Minimum scale used for meshes in the array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "bRandomScale", EditConditionHides))
	FVector RandomScaleMin(1.0, 1.0, 1.0);

	// Maximum scale used for meshes in the array
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array", Meta = (EditCondition = "bRandomScale", EditConditionHides))
	FVector RandomScaleMax(1.0, 1.0, 1.0);

	// Additional offset individually to each mesh based on its in a specified axis
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	FVector Shear = FVector(0.0, 0.0, 0.0);

	// The axis the props are sheared along
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Prop Array")
	EAxis ShearAxis = EAxis::Z;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Meshes.Num() == 0)
			return;

		FRandomStream RandomStream(GetRandomSeed());
		TArray<UHazePropComponent> PlacedProps;

		// Place a mesh for each part of the grid
		for (int X = 0; X < CopiesX; ++X)
		{
			for (int Y = 0; Y < CopiesY; ++Y)
			{
				for (int Z = 0; Z < CopiesZ; ++Z)
				{
					auto NewProp = PlaceProp(RandomStream, PlacedProps.Num(), FIntVector(X, Y, Z));
					if (NewProp != nullptr)
						PlacedProps.Add(NewProp);
					if (PlacedProps.Num() >= MaxInstances)
						return;
				}
			}
		}
	}

	UHazePropComponent PlaceProp(FRandomStream RandomStream, int Index, FIntVector Position)
	{
		// Determine the mesh to use
		FHazePropSettings PropSettings;
		if (bUseRandomMeshOrder)
			PropSettings = Meshes[RandomStream.RandRange(0, Meshes.Num()-1)];
		else
			PropSettings = Meshes[Index % Meshes.Num()];

		// Can't place empty meshes
		if (PropSettings.StaticMesh == nullptr)
			return nullptr;

		// Create the new component
		FName PropName = PropSettings.StaticMesh.Name;
		PropName.SetNumber(Index + 2);

		auto PropComp = UHazePropComponent::Create(this, PropName);
		PropComp.ConfigureFromConstructionScript(PropSettings);
		Editor::CopyAllComponentTags(TagContainer, PropComp);

		FVector ShearValue = FVector::ZeroVector;
		if(ShearAxis == EAxis::X)
			ShearValue = FVector(0, Shear.Y, Shear.Z) * Position.X;
		if(ShearAxis == EAxis::Y)
			ShearValue = FVector(Shear.X, 0, Shear.Z) * Position.Y;
		if(ShearAxis == EAxis::Z)
			ShearValue = FVector(Shear.X, Shear.Y, 0) * Position.Z;
			
		// Figure out the transform for the component
		PropComp.RelativeLocation = FVector(
			Position.X * Offset.X + ShearValue.X,
			Position.Y * Offset.Y + ShearValue.Y,
			Position.Z * Offset.Z + ShearValue.Z,
		);

		if (bRandomPositionOffset)
		{
			PropComp.RelativeLocation = PropComp.RelativeLocation + FVector(
				RandomStream.RandRange(-RandomOffset.X, RandomOffset.X),
				RandomStream.RandRange(-RandomOffset.Y, RandomOffset.Y),
				RandomStream.RandRange(-RandomOffset.Z, RandomOffset.Z),
			);
		}

		if (bRandomScale)
		{
			PropComp.RelativeScale3D = FVector(
				RandomStream.RandRange(RandomScaleMin.X, RandomScaleMax.X),
				RandomStream.RandRange(RandomScaleMin.Y, RandomScaleMax.Y),
				RandomStream.RandRange(RandomScaleMin.Z, RandomScaleMax.Z),
			);
		}

		FRotator PropRotation = FRotator::ZeroRotator;

		// Apply static rotation
		if (MeshRotation == EPropArrayRotationType::StaticRotation || MeshRotation == EPropArrayRotationType::AdvancedCombination)
		{
			PropRotation += StaticRotation;
		}

		// Apply random rotation range
		if (MeshRotation == EPropArrayRotationType::RandomRotationRange || MeshRotation == EPropArrayRotationType::AdvancedCombination)
		{
			PropRotation += FRotator(
				RandomStream.RandRange(-RandomRotationMax.Pitch, RandomRotationMax.Pitch),
				RandomStream.RandRange(-RandomRotationMax.Yaw, RandomRotationMax.Yaw),
				RandomStream.RandRange(-RandomRotationMax.Roll, RandomRotationMax.Roll),
			);
		}

		// Apply random rotation interval
		if (MeshRotation == EPropArrayRotationType::RandomRotationInterval || MeshRotation == EPropArrayRotationType::RandomRotationIntervalLimitedRange || MeshRotation == EPropArrayRotationType::AdvancedCombination)
		{
			FRotator Limit = IntervalLimitRotation;
			if (MeshRotation == EPropArrayRotationType::RandomRotationInterval)
				Limit = FRotator(360.0, 360.0, 360.0);

			FRotator Interval = IntervalRandomRotation;

			int PitchMax = 0;
			int YawMax = 0;
			int RollMax = 0;

			if (!Math::IsNearlyZero(Interval.Pitch))
				PitchMax = Math::FloorToInt(Limit.Pitch / Interval.Pitch);
			if (!Math::IsNearlyZero(Interval.Yaw))
				YawMax = Math::FloorToInt(Limit.Yaw / Interval.Yaw);
			if (!Math::IsNearlyZero(Interval.Roll))
				RollMax = Math::FloorToInt(Limit.Roll / Interval.Roll);

			PropRotation += FRotator(
				float(RandomStream.RandRange(0, PitchMax)) * Interval.Pitch,
				float(RandomStream.RandRange(0, YawMax)) * Interval.Yaw,
				float(RandomStream.RandRange(0, RollMax)) * Interval.Roll,
			);
		}

		PropComp.RelativeRotation = PropRotation;

		return PropComp;
	}

	// Calculate a seed from the actor position
	int GetRandomSeed()
	{
		FVector Location = GetActorLocation();
		FRotator Rotation = GetActorRotation();

		const uint HashConstant = 2654435761;
		uint Seed = 0;
		Seed ^= uint(Math::RoundToInt(Location.X)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Location.Y)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Location.Z)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Yaw)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Pitch)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Roll)) * HashConstant;
		return int(Seed);
	}

	UFUNCTION(BlueprintOverride)
	void GetReferencedContentObjects(TArray<UObject>& Objects) const
	{
		for (auto Mesh : Meshes)
		{
			if (Mesh.StaticMesh != nullptr)
				Objects.Add(Mesh.StaticMesh);
		}
	}

	UFUNCTION()
	void InitializeFromStaticMesh(UStaticMesh Mesh)
	{
		FHazePropSettings DefaultMesh;
		DefaultMesh.StaticMesh = Mesh;

		Meshes.Reset();
		Meshes.Add(DefaultMesh);
	}

	UFUNCTION()
	void InitializeFromPropSettings(FHazePropSettings PropSettings)
	{
		Meshes.Reset();
		Meshes.Add(PropSettings);
	}
};
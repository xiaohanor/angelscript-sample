/**
 * Preset configuration for a prop line.
 */
class UPropLinePreset : UDataAsset
{
	UPROPERTY(Category = "Prop Line", Meta = (ShowOnlyInnerProperties))
	FPropLineSettings Settings;
};

struct FPropLineMesh
{
	UPROPERTY(Category = "Prop Line", Meta = (ShowOnlyInnerProperties))
	FHazePropSettings Mesh;

	/* Scale of the mesh when placed. Does not affect the spacing in the line. */
	UPROPERTY(Category = "Prop Line")
	FVector Scale = FVector::OneVector;

	/* Multiplier to the spacing this mesh requires in the prop line. */
	UPROPERTY(Category = "Prop Line")
	float SpacingMultiplier = 1.0;

	/* Which axis to use as the forward axis when placing the mesh on the prop line. */
	UPROPERTY(Category = "Prop Line")
	ESplineMeshAxis ForwardAxis = ESplineMeshAxis::X;

	/* Amount of roll to apply to the mesh when placed. This is applied on top of the roll that is already present in the spline. */
	UPROPERTY(Category = "Prop Line")
	float Roll = 0.0;

	/* Base value for the translucency sort order assigned to all meshes on the prop line. */
	UPROPERTY(Category = "Prop Line")
	int BaseTranslucentSortPriority = 0;

	float CalculateMeshSizeInSegment(bool bPlaceOnPivot) const
	{
		if (Mesh.StaticMesh == nullptr)
			return 0.0;

		float RelevantOrigin = 0.0;
		float RelevantExtent = 0.0;

		switch (ForwardAxis)
		{
			case ESplineMeshAxis::X:
				RelevantExtent = Mesh.StaticMesh.Bounds.BoxExtent.X;
				RelevantOrigin = Mesh.StaticMesh.Bounds.Origin.X;
			break;
			case ESplineMeshAxis::Y:
				RelevantExtent = Mesh.StaticMesh.Bounds.BoxExtent.Y;
				RelevantOrigin = Mesh.StaticMesh.Bounds.Origin.Y;
			break;
			case ESplineMeshAxis::Z:
				RelevantExtent = Mesh.StaticMesh.Bounds.BoxExtent.Z;
				RelevantOrigin = Mesh.StaticMesh.Bounds.Origin.Z;
			break;
		}

		if (bPlaceOnPivot)
		{
			float FurthestX = RelevantOrigin - RelevantExtent;
			return ((RelevantExtent * 2.0) + FurthestX) * SpacingMultiplier;
		}
		else
		{
			return RelevantExtent * SpacingMultiplier * 2.0;
		}
	}
};

enum EPropLineType
{
	// All segments in the prop line are straight
	StaticMeshes,

	// Places static meshes rotated along the curve
	StaticMeshesCurvedPlacement,

	// All segments in the prop line are curved and generate spline meshes
	SplineMeshes,

	// Configure each segment individually between straight and curved
	PerSegment,
};

enum EPropLineDistributionType
{
	// Distribute meshes over each spline segment
	DistributePerSegment,
	// Distribute meshes over the entire spline
	DistributeOverEntireSpline,
	// Generate exactly one mesh per spline segment
	OneMeshPerSegment,
};

enum EPropLineStretchType
{
	// Stretch the last mesh in the segment only to fit
	StretchLastMeshInSegment,
	// Stretch all meshes in the segment so it fits
	StretchAllMeshes,
	// Never stretch any meshes. This will cause meshes to overshoot the segment positions.
	NeverStretch,
};

enum EPropLineSegmentType
{
	// Straight line segment
	StaticMesh,

	// Curved line segment, place spline meshes for each mesh in the segment
	SplineMesh,

	// Curved line segment, place static meshes rotated along the curve
	StaticMeshCurvedPlacement,

	// Segment should not have any meshes generated on it
	NoMeshes,
};

enum EPropLineMeshSelectionType
{
	// Pick the largest mesh that fits in the available space
	LargestFitting,

	// Always place meshes in the order that they are in the list
	CycleInOrder,

	// Place meshes in the order that they have in the list, restarting the sequence for every segment
	CycleInOrderPerSegment,

	// Pick a random mesh
	Random,
};

struct FPropLineSegment
{
	/* Whether to make a curved segment here. */
	UPROPERTY()
	EPropLineSegmentType Type = EPropLineSegmentType::StaticMesh;

	/* If set, use a specific mesh for this segment instead of using the normal selection rules. */
	UPROPERTY(Meta = (EditCondition = "Type != EPropLineSegmentType::NoMeshes", EditConditionHides))
	bool bUseSpecificMesh = false;

	/* Which mesh to place on this segment when bUseSpecificMesh is true. */
	UPROPERTY(Meta = (EditCondition = "bUseSpecificMesh", EditConditionHides))
	int SpecificMeshIndex = 0;
};

struct FPropLineDivider
{
	UPROPERTY(Category = "Prop Line")
	bool bEnabled = false;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FHazePropSettings Mesh;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FVector Scale = FVector::OneVector;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FRotator Rotation;

	bool opEquals(const FPropLineDivider& Other) const
	{
		return bEnabled == Other.bEnabled
			&& UHazePropComponent::AreSettingsEqual(Mesh, Other.Mesh)
			&& Scale.Equals(Other.Scale)
			&& Rotation.Equals(Other.Rotation)
		;
	}
};

struct FPropLineAngledCorner
{
	UPROPERTY(Category = "Prop Line")
	float AngleMinimum = 0.0;

	UPROPERTY(Category = "Prop Line")
	float AngleMaximum = 360.0;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FHazePropSettings Mesh;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FVector Scale = FVector::OneVector;

	UPROPERTY(Category = "Prop Line", Meta = (EditCondition = "bEnabled", EditConditionHides))
	FRotator Rotation;
};

struct FPropLineSettings
{
	UPROPERTY(Category = "Prop Line")
	TArray<FPropLineMesh> Meshes;

	// Randomize which meshes are chosen for each segment, rather than choosing the best fitting one
	UPROPERTY(NotEditable, BlueprintHidden)
	bool bRandomizeMeshes = false;

	// Determines the selection method used to choose which mesh from the meshes list is used
	UPROPERTY(BlueprintReadOnly, Category = "Prop Line")
	EPropLineMeshSelectionType MeshSelection = EPropLineMeshSelectionType::LargestFitting;

	// Place meshes based on their pivot instead of in the center of their bounds
	UPROPERTY(BlueprintReadOnly, Category = "Prop Line", AdvancedDisplay)
	bool bPlaceMeshesOnPivot = true;

	// Specify specific corner meshes to use based on the angle of the corner
	UPROPERTY(BlueprintReadOnly, Category = "Prop Line Dividers", AdvancedDisplay)
	bool bUseAngledCorners = false;

	// Corner dividers are placed with the same rotation as the segment preceding them, instead of on the tangent
	UPROPERTY(BlueprintReadOnly, Category = "Prop Line Dividers", AdvancedDisplay)
	bool bRotateCornersAlongPrecedingSegment = false;

	UPROPERTY(Category = "Prop Line Dividers")
	FPropLineDivider Standard;

	UPROPERTY(Category = "Prop Line Dividers")
	FPropLineDivider Corner;

	UPROPERTY(Category = "Prop Line Dividers")
	FPropLineDivider Start;

	UPROPERTY(Category = "Prop Line Dividers")
	FPropLineDivider End;

	UPROPERTY(Category = "Prop Line Dividers", Meta = (EditCondition = "bUseAngledCorners", EditConditionHides))
	TArray<FPropLineAngledCorner> AngledCorners;

	UPROPERTY(Category = "Prop Line Segments", AdvancedDisplay)
	bool bForceSurfaceLightmaps = false;

	bool opEquals(const FPropLineSettings& Other) const
	{
		return Meshes == Other.Meshes
			&& bRandomizeMeshes == Other.bRandomizeMeshes
			&& MeshSelection == Other.MeshSelection
			&& bPlaceMeshesOnPivot == Other.bPlaceMeshesOnPivot
			&& bUseAngledCorners == Other.bUseAngledCorners
			&& bRotateCornersAlongPrecedingSegment == Other.bRotateCornersAlongPrecedingSegment
			&& Standard == Other.Standard
			&& Corner == Other.Corner
			&& Start == Other.Start
			&& End == Other.End
			&& AngledCorners == Other.AngledCorners
			&& bForceSurfaceLightmaps == Other.bForceSurfaceLightmaps
		;
	}
};

struct FPropLineMergedMeshData
{
	UPROPERTY()
	UStaticMesh StaticMesh;
	UPROPERTY()
	FTransform RelativeTransform;
};
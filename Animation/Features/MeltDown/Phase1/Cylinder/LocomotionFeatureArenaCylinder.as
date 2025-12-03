struct FLocomotionFeatureCylinderAnimData
{
	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData StartPhase;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData BendArena;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData FirstRotationLeft90;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData RotationRight180;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData SecondRotationLeft90;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData Reset;

	UPROPERTY(Category = "Cylinder")
	FHazePlaySequenceData FinishPhase;
}

class ULocomotionFeatureCylinder : UHazeLocomotionFeatureBase
{
	default Tag = n"Cylinder";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCylinderAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

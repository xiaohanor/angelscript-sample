struct FLocomotionFeaturePlantLauncherAnimData
{
	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData LightCharacter;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData LightDownMh;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData HeavyCharacter;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData HeavyDownMh;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData StartMh;

	UPROPERTY(Category = "PlantLauncher")
	FHazePlaySequenceData Launch;


}

class ULocomotionFeaturePlantLauncher : UHazeLocomotionFeatureBase
{
	default Tag = n"PlantLauncher";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePlantLauncherAnimData AnimData;
}

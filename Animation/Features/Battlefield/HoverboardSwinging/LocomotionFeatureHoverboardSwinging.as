struct FLocomotionFeatureHoverboardSwingingAnimData
{
	UPROPERTY(Category = "HoverboardSwinging")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "HoverboardSwinging")
	FHazePlaySequenceData Swing;

	UPROPERTY(Category = "HoverboardSwinging")
	FHazePlaySequenceData SwingAdditive;

	UPROPERTY(Category = "HoverboardSwinging")
	FHazePlaySequenceData Exit;

}

class ULocomotionFeatureHoverboardSwinging : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardSwinging";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardSwingingAnimData AnimData;
}

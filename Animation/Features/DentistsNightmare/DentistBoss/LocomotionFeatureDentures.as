struct FLocomotionFeatureDenturesAnimData
{
	
	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData MouthMH;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData Spit;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData FlipOver;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData FlippedMH;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData FlippedHitReaction;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData FlipBack;


	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData ControlledMH;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData ControlledJump;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData HandAttach;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData HandMH;

	UPROPERTY(Category = "Dentures")
	FHazePlaySequenceData HandBite;
	

}

class ULocomotionFeatureDentures : UHazeLocomotionFeatureBase
{
	default Tag = n"Dentures";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDenturesAnimData AnimData;
}
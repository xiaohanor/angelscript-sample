struct FLocomotionFeatureToothMovementAnimData
{

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "Fall")
	FHazePlaySequenceData Fall;

	UPROPERTY(Category = "Landings")
	FHazePlaySequenceData LandStill;

	UPROPERTY(Category = "Landings")
	FHazePlaySequenceData LandJog;

	UPROPERTY(Category = "Landings")
	FHazePlaySequenceData LandStillHigh;

	UPROPERTY(Category = "Landings")
	FHazePlaySequenceData LandJogHigh;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData Dash;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashEnd;

	UPROPERTY(Category = "GroundPound")
	FHazePlaySequenceData GroundPoundStart;

	UPROPERTY(Category = "GroundPound")
	FHazePlaySequenceData GroundPoundMH;

	UPROPERTY(Category = "GroundPound")
	FHazePlaySequenceData GroundPoundEnd;

	UPROPERTY(Category = "Flail")
	FHazePlaySequenceData Flail;

}

class ULocomotionFeatureToothMovement : UHazeLocomotionFeatureBase
{
	default Tag = Dentist::Feature;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureToothMovementAnimData AnimData;
};

namespace Dentist
{
	const FName Feature = n"Movement";
}
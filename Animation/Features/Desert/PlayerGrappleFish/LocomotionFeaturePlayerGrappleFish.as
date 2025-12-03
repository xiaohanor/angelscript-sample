struct FLocomotionFeaturePlayerGrappleFishAnimData
{
	UPROPERTY(Category = "PlayerGrappleFish")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "PlayerGrappleFish")
	FHazePlayBlendSpaceData MH;

	UPROPERTY(Category = "PlayerGrappleFish")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "PlayerGrappleFish")
	FHazePlaySequenceData EndJump;

}

class ULocomotionFeaturePlayerGrappleFish : UHazeLocomotionFeatureBase
{
	default Tag = n"PlayerGrappleFish";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePlayerGrappleFishAnimData AnimData;
}

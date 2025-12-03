struct FOpportunityAttackSegment
{
	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData Attack;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData Fail;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData TargetAttackResponse;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData TargetMh;

	UPROPERTY(Category = "Animation")
	FHazePlaySequenceData TargetFailResponse;
}

struct FOpportunityAttackSequence
{
	UPROPERTY(EditAnywhere)
	TArray<FOpportunityAttackSegment> Segments;
}

struct FLocomotionFeatureOpportunityAttackAnimData
{
	UPROPERTY(EditAnywhere)
	TArray<FOpportunityAttackSequence> Sequences;
}

class ULocomotionFeatureOpportunityAttack : UHazeLocomotionFeatureBase
{
	default Tag = n"OpportunityAttack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, Category = "Animation" meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureOpportunityAttackAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

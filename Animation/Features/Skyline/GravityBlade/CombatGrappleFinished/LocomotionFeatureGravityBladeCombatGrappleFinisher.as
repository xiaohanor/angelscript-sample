struct FLocomotionFeatureGravityBladeCombatGrappleFinisherAnimData
{
	UPROPERTY(Category = "GravityBladeCombatGrappleFinisher")
	FHazePlaySequenceData StabFinisher_Var1;
}

class ULocomotionFeatureGravityBladeCombatGrappleFinisher : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityBladeCombatGrappleFinisher";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBladeCombatGrappleFinisherAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

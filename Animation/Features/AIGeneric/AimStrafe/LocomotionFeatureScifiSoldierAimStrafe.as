struct FLocomotionFeatureScifiSoldier_AimStrafeAnimData
{
	UPROPERTY(Category = "MH")
	FHazePlayBlendSpaceData AimMhBlendSpace;

	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData AimStrafeFwd400BlendSpace;

	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData AimStrafeFwd750BlendSpace;

	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData AimStrafeBack400BlendSpace;

	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData AimStrafeLeft400BlendSpace;

	UPROPERTY(Category = "Strafe")
	FHazePlayBlendSpaceData AimStrafeRight400BlendSpace;


	UPROPERTY(Category = "TurnInPlace")
	FHazePlayBlendSpaceData TurnInPlaceBlendSpace;


	UPROPERTY(Category = "Enforcer|AimSpace")
	FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(Category = "Enforcer|Locomotion")
	FHazePlayBlendSpaceData LocomotionBS;

	UPROPERTY(Category = "Enforcer|TurnInPlace")
	FHazePlayBlendSpaceData TurnInPlaceBS;

}

class ULocomotionFeatureScifiSoldier_AimStrafe : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureScifiSoldier_AimStrafeAnimData AnimData;
}

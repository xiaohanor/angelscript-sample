struct FLocomotionFeatureGlitchWeaponStrafeAnimData
{
	UPROPERTY(Category = "GlitchWeaponStrafe")
	FHazePlayBlendSpaceData StationaryBS;

	UPROPERTY(Category = "Locomotion|Fwd")
	FHazePlayBlendSpaceData FwdStart;

	UPROPERTY(Category = "Locomotion|Fwd")
	FHazePlayBlendSpaceData FwdLoop;

	UPROPERTY(Category = "Locomotion|Fwd")
	FHazePlayBlendSpaceData FwdStop;

	UPROPERTY(Category = "Locomotion|Bwd")
	FHazePlayBlendSpaceData BwdStart;

	UPROPERTY(Category = "Locomotion|Bwd")
	FHazePlayBlendSpaceData BwdLoop;

	UPROPERTY(Category = "Locomotion|Bwd")
	FHazePlayBlendSpaceData BwdStop;

	UPROPERTY(Category = "Locomotion|Left")
	FHazePlayBlendSpaceData LeftStart;

	UPROPERTY(Category = "Locomotion|Left")
	FHazePlayBlendSpaceData LeftLoop;

	UPROPERTY(Category = "Locomotion|Left")
	FHazePlayBlendSpaceData LeftStop;

	UPROPERTY(Category = "Locomotion|Right")
	FHazePlayBlendSpaceData RightStart;

	UPROPERTY(Category = "Locomotion|Right")
	FHazePlayBlendSpaceData RightLoop;

	UPROPERTY(Category = "Locomotion|Right")
	FHazePlayBlendSpaceData RightStop;

	UPROPERTY(Category = "Locomotion|Air")
	FHazePlayBlendSpaceData AirFwd;

	UPROPERTY(Category = "Locomotion|Air")
	FHazePlayBlendSpaceData AirBwd;

	UPROPERTY(Category = "Locomotion|Air")
	FHazePlayBlendSpaceData AirLeft;

	UPROPERTY(Category = "Locomotion|Air")
	FHazePlayBlendSpaceData AirRight;
	
	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData AimSpace;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData Shoot_Start;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData Shooting;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData Shoot_Stop;

	UPROPERTY(Category = "Sword")
	FHazePlayRndSequenceData AttackLeft;

	UPROPERTY(Category = "Sword")
	FHazePlayRndSequenceData AttackRight;



}

class ULocomotionFeatureGlitchWeaponStrafe : UHazeLocomotionFeatureBase
{
	default Tag = n"GlitchWeaponStrafe";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGlitchWeaponStrafeAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

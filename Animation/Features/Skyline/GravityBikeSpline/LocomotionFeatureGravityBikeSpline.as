struct FLocomotionFeatureGravityBikeSplineAnimData
{
	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringHeightBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringChargeBS;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBoost;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringBoostLanding;
	
	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlaySequenceData SteeringFallingMh;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringLanding;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringThrottleStart;

	UPROPERTY(Category = "GravityBike|Steering")
	FHazePlayBlendSpaceData SteeringThrottleStop;

	UPROPERTY(Category = "GravityBike|Blade Grapple")
	FHazePlaySequenceData SteerBladeGrappleStart;

	UPROPERTY(Category = "GravityBike|Blade Grapple")
	FHazePlaySequenceData SteerBladeGrappleMh;

	UPROPERTY(Category = "GravityBike|Blade Grapple")
	FHazePlayBlendSpaceData SteerBladeGrappleThrow;

	UPROPERTY(Category = "GravityBike|Gravity Shift")
	FHazePlayBlendSpaceData SteeringGravityShiftStart;

	UPROPERTY(Category = "GravityBike|Gravity Shift")
	FHazePlayBlendSpaceData SteeringGravityShiftMh;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatBS;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatHeightBS;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatChargeBS;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatBoost;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatBoostLanding;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlaySequenceData BackseatFallingMh;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatLanding;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatWhip;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatGravityShiftStart;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatGravityShiftMh;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatThrottleStart;

	UPROPERTY(Category = "GravityBike|Backseat")
	FHazePlayBlendSpaceData BackseatThrottleStop;

	UPROPERTY(Category = "GravityBike|Phone")
	FHazePlayBlendSpaceData PhoneLocomotionBS;

	UPROPERTY(Category = "GravityBike|Phone")
	FHazePlayBlendSpaceData ThumbBlendSpace;
	
	UPROPERTY(Category = "GravityBike|Phone")
	FHazePlayBlendSpaceData ThumbPressBlendSpace;

	UPROPERTY(Category = "GravityBike|Phone")
	FHazePlayBlendSpaceData HandBlendSpace;
}

class ULocomotionFeatureGravityBikeSpline : UHazeLocomotionFeatureBase
{
	default Tag = GravityBikeSpline::GravityBikeSplinePlayerFeature;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityBikeSplineAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

class UGravityBikeSplineMovementComponent : UHazeMovementComponent
{
	private AGravityBikeSpline GravityBike;
	private FHitResult SteeringWallHit;
	private uint SteeringWallHitFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GravityBike = Cast<AGravityBikeSpline>(Owner);

		auto Settings = UGravityBikeSplineSettings::GetSettings(GravityBike);
		
		UMovementStandardSettings::SetAlsoUseActorUpForWalkableSlopeAngle(GravityBike, true, this);
		UMovementStandardSettings::SetWalkableSlopeAngle(GravityBike, Settings.WalkableSlopeAngle, this);
		UMovementGravitySettings::SetGravityAmount(GravityBike, GravityBikeSpline::GravityAmount, this);
		
		GravityBike.AddMovementAlignsWithGroundContact( this, bCanFallOfEdges = true);
	}

	FHitResult GetSteeringWallHit() const
	{
		if(Time::FrameNumber > SteeringWallHitFrame)
			return FHitResult();

		return SteeringWallHit;
	}
	
	void SetSteeringWallHit(FHitResult InWallHit)
	{
		SteeringWallHit = InWallHit;
		SteeringWallHitFrame = Time::FrameNumber;
	}
}
asset PlayerDefaultMovementSettings of UMovementStandardSettings
{
	WalkableSlopeAngle = 40;
	AutoFollowGround = EMovementAutoFollowGroundType::FollowWalkable;
}

asset PlayerDefaultMovementResolverSettings of UMovementResolverSettings
{
	MaxRedirectIterations = 5;
	MaxDepenetrationIterations = 2;
};

asset PlayerDefaultMovementGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2385;
	TerminalVelocity = 2500;
};

asset PlayerDefaultMovementSteppingSettings of UMovementSteppingSettings
{
	bSweepStep = false;
	bCanTriggerStepUpOnUnwalkableSurface = true;
	StepDownInAirSize = FMovementSettingsValue::MakePercentage(0.1);
	bPerformEdgeDetection = true;
};

asset PlayerDefaultMovementSweepingSettings of UMovementSweepingSettings
{
	bPerformEdgeDetection = true;
};

asset PlayerDefaultMovementFloatingSettings of UMovementFloatingSettings
{
	bPerformEdgeDetection = true;
};
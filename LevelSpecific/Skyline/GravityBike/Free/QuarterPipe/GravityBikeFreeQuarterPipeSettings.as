namespace GravityBikeFree
{
	namespace QuarterPipe
	{
		// Start Threshold
		const float StartDistanceToSpline = 1000;	// If distance to the spline is further than this, we are not close enough to start

		// Movement
		const float Drag = 0.5;

		// Vertical Movement
		const float Gravity = 6000;

		// Normal Movement
		const float NormalTargetOffset = 200;	// How far away from the surface we want to be when we land
		const float NormalLocationInterpSpeed = 100; // How fast (per second) we travel towards TargetNormalOffset

		// Land Rotation
		const float LandMaxRotationDuration = 0.5;
		const float LandTargetPitch = 25; // How much to pitch up

		// Apex Rotation
		const float ApexMaximumVerticalSpeed = 2000;	// If our vertical speed if over this, wait for gravity to lower it below this before starting apex rotation
		const float ApexMinimumVerticalSpeed = 0;	// If our vertical speed is lower than this (negative is falling), don't start apex rotation
		const float ApexMinimumVerticalLocation = 3000;	// If we are lower than this over the spline, don't start apex rotation
		const float ApexRotationDuration = 1.0;	// How long time the full rotation should take
		const float ApexRotationAccelerateDuration = 0.1;

		// Velocity Rotation
		const float VelocityRotationAccelerateDuration = 1;

		// Leave Threshold
		const float LeavePredictionDistanceMultiplier = 0.2;	// How many seconds ahead to predict movement when checking curvature
		const float LeaveConvexAngleDiffThreshold = 5;
		const float LeaveConcaveAngleDiffThreshold = 10;
	};
};
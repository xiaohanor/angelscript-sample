namespace CongaLine
{
	// Defaults
	const float DefaultMoveSpeed = 700;
	const float MaxMoveSpeedCap = 1200;
	const float SpeedIncreasePerMonkey = 50;
	const float TurnRateIncreasePerMonkey = 0.01;
	const float OtherPlayerCollisionRadius = 150;
	const float EndSpeed = 300;

	//New variables for top down movement
	const float MinGroundMovementAcceleration = 1250;
	const float GroundMovementAcceleration = 5000;
	const float HorizontalGroundFriction = 6;
	const float RotationInterpSpeed = 5;

	// Timing
	const int BeatsPerMinute = 90;
	const int AdditionalBeatsPerStage = 0;
	const int BeatsPerMeasure = 4;
	
	//const float TimeBetweenBeats = 1.0 / (BeatsPerMinute / 60.0);
	//const float MeasureTime = TimeBetweenBeats * BeatsPerMeasure;

	// Dancers
	const bool bOnlyEnterCongaLineDuringPoses = true;
	const float EnterCongaLineRange = 500;	// Monkey will join conga line if this range is entered
	const float MonkeyStartReactingRange = 1400;	// Monkey will rotate toward player and start dancing within this range
	const bool bVisualizeStartEnteringRange = false;

	//const float DancerMoveSpeed = DefaultMoveSpeed * 1.5;
	const float DancerEnterSpeed = DefaultMoveSpeed + 350;
	const float DistanceBetweenDancers = 300;
	const float DistanceFromPlayerToFirstDancer = 300;

	// Disperse
	const float DancersDisperseSpeed = 800;
	const float DancersDisperseRandomTurnFrequency = 2;
	const float DancersDisperseRandomTurnRate = 400;
	const FHazeRange DancersDisperseDuration = FHazeRange(1.5, 3);

	// Spline
	const int MaxDancers = 30;
	const float MaxSplineLength = DistanceBetweenDancers * (MaxDancers) + DistanceFromPlayerToFirstDancer + 1000;

	// Vibe Meter
	const float VibeMeterStartValue = 0.5;
	const float VibeMeterIncreaseSuccessfulInput = 0.04;
	const float VibeMeterDecreaseFailedInput = 0;
	const float VibeMeterDecreaseMissedInput = 0;
	const float VibeMeterAccelerationStiffness = 500.0;
	const float VibeMeterAccelerationDamping = 0.4;

	// Animation
	const float StrikePoseDuration = 0.4;
	const float EnteringStrikePoseDuration = 0.5;
	const float HitWallDuration = 0.8;

	// Strike Pose
	const float StrikePoseMargin = 0.25;
	const float StrikePoseAlpha = (BeatsPerMeasure - 1) / float(BeatsPerMeasure);
	const float StrikePoseStartMargin = 0.1;
	const float StrikePoseEndMargin = 0.1;
	const float HiddenExtraMargin = 0.05;
	const float StrikePoseCooldown = 0.5;
};
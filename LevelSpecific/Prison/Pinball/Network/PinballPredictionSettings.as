namespace Pinball::Prediction
{
	const bool bPredictionLogsSubframes = true;

	const float PredictedFramesPerSecond = 30;

	const float LaunchPredictionSlowdownTime = 0.5;

	const bool bPredictedBallPlaceOnGround = true;

	const float TimeBasedTeleportThreshold = 500.0;
	const float TimeBasedCatchUpSpeed = 2.0;
	const float TimeBasedCatchUpMinimumBoost = 0.2;

	const bool bUseAcceleratedMispredictionCorrection = true;
	const float MispredictionCorrectionAcceleration = 5000.0;
	const float MispredictionOffsetDecay = 0.01;
};
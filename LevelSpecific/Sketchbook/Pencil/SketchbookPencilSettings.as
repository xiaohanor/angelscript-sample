namespace Sketchbook
{
	const float MoveTiltFactor = 0.001;
	const float MoveMaxTiltRad = 0.2;
	
	// How long it takes to flip from drawing to erasing
	const float RotateAroundPivotDuration = 0.4;

	namespace Projection
	{
		const float PageDepthInOverlayView = 1200.0;
		const FVector PagePlaneOrigin = FVector::ZeroVector;
		const FVector PagePlaneNormal = FVector::ForwardVector;
	}

	namespace Sentence
	{
		const FVector DrawWaitingOffset = FVector(-50, 50, 50);
		const FVector DrawWaitingPerlinFrequency = FVector(0.1, 0.5, 0.6);
		const FVector DrawWaitingPerlinAmplitude = FVector(5, 15, 15);

		const FRotator DrawWaitingRotationPerlinFrequency = FRotator(0.1, 0.2, 0.5);
		const FRotator DrawWaitingRotationPerlinAmplitude = FRotator(1, 2.5, 1.5);

		const float DefaultDrawSpeed = 1000;
		const float DefaultEraseSpeed = 2000;

		const float DrawVerticalFrequency = 10;

		const float DrawHorizontalAmplitude = 50;
		const float DrawHorizontalFrequency = 1;

		const float DrawPitchAmplitude = 10;
		const float DrawPitchFrequency = 8;

		const float DrawYawAmplitude = 3;
		const float DrawYawFrequency = 5;

		const float TravelToNextWordsDuration = 0.05;
		const FVector TravelToNextWordOffset = FVector(-30, 20, 20);

		const float EraseVerticalFrequency = 50;
	}
};
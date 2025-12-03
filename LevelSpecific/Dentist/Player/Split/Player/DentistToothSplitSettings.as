namespace Dentist::SplitTooth
{
	const float SpawnOffset = 40;
	const float VerticalImpulse = 1100;
	const float HorizontalImpulse = 800;
	const float TargetLaunchHeight = 500;
	const float CameraPitch = -35;

	const float MinSplitDuration = 1.0;

	const float RecombineDistance = 150.0;
	const float RecombineSpeed = 750;

	const FName SplitToothTag = n"SplitTooth";
	const FName SplitToothRecombineTag = n"SplitToothRecombine";

	FVector GetSideLocation(FTransform Transform, bool bRight)
	{
		FVector LocalOffset;
		
		if(bRight)
			LocalOffset = FVector(0, SpawnOffset, 0);
		else
			LocalOffset = FVector(0, -SpawnOffset, 0);

		return Transform.TransformPositionNoScale(LocalOffset);
	}
};
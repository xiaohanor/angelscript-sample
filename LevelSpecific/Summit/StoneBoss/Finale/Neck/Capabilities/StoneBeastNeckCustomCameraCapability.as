class UStoneBeastNeckCustomCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStoneBeastNeckCustomCamera CustomCamera;
	UHazeSplineComponent SplineComp;

	FHazeAcceleratedVector AccelVec;
	FHazeAcceleratedQuat AccelQuat;

	float DistanceFromSpline = 1200.0;

	float LookAheadDistance = 250.0;
	float BackwardsSplineOffset = 0.0;

	FVector LocationOffsetFromTarget = FVector(0,0,450.0);
	FVector LookToOffset = FVector(0,0,250);

	float LocationDuration = 1.1;
	float RotationDuration = 1.6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CustomCamera = Cast<AStoneBeastNeckCustomCamera>(Owner);
		SplineComp = CustomCamera.SplineActor.Spline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTransform TargetTransform = GetTargetTransform();
		AccelVec.SnapTo(TargetTransform.Location);
		AccelQuat.SnapTo(TargetTransform.Rotation);

		CustomCamera.ActorLocation = AccelVec.Value;
		CustomCamera.ActorRotation = AccelQuat.Value.Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform TargetTransform = GetTargetTransform();
		AccelVec.AccelerateTo(TargetTransform.Location, LocationDuration, DeltaTime);
		AccelQuat.AccelerateTo(TargetTransform.Rotation, RotationDuration, DeltaTime);	

		CustomCamera.ActorLocation = AccelVec.Value;
		CustomCamera.ActorRotation = AccelQuat.Value.Rotator();

		// TEMPORAL_LOG(CustomCamera, "Camera")
		// 	.Value("AccelVec", AccelVec.Value)
		// 	.Value("AccelQuatForward", AccelQuat.Value.ForwardVector)
		// 	.Sphere("Actor Location", CustomCamera.ActorLocation, 50, FLinearColor::DPink, 5)
		// ;
	}

	FTransform GetTargetTransform()
	{
		FVector PlayerAverageLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		float Distance = SplineComp.GetClosestSplineDistanceToWorldLocation(PlayerAverageLocation);
		FVector PlayerAverageSplineLocation = SplineComp.GetWorldLocationAtSplineDistance(Distance - BackwardsSplineOffset);
		FVector RightDirection = SplineComp.GetWorldRotationAtSplineDistance(Distance).RightVector;

		float LookDistance = Math::Clamp(Distance + LookAheadDistance, 0, SplineComp.SplineLength);

		FVector LookToLocation = SplineComp.GetWorldLocationAtSplineDistance(LookDistance) + LookToOffset;
		// Debug::DrawDebugSphere(LookToLocation, 200.0, 12, FLinearColor::Green, 10);
		// LookToLocation = PlayerAverageLocation + LookToOffset;
		
		float HeightOffset = Math::Abs(Game::Mio.ActorLocation.Z - Game::Zoe.ActorLocation.Z);

		FVector TargetLocation = PlayerAverageSplineLocation + (RightDirection * DistanceFromSpline) + LocationOffsetFromTarget + FVector(0,0,HeightOffset / 2);
		FRotator TargetRotation = (LookToLocation - TargetLocation).Rotation();

		FTransform NewTransform;
		NewTransform.Scale3D = FVector(1,1,1);
		NewTransform.Location = TargetLocation;
		NewTransform.Rotation = TargetRotation.Quaternion();

		return NewTransform;
	}
};
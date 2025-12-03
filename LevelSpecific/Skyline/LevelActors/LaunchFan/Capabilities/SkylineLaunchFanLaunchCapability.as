class USkylineLaunchFanLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	USkylineLaunchFanUserComponent UserComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FHazeAcceleratedVector AccVector;
	float LaunchTime = 10.0;

	FHazeRuntimeSpline RuntimeSpline;
	float DistanceOnSpline = 0.0;
	float StartSpeed = 0.0;
	FHazeAcceleratedFloat AccFloat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineLaunchFanUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!UserComp.bIsLaunched)
			return false;

		if (DeactiveDuration < 2.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LaunchTime)
			return true;

		if (DistanceOnSpline > RuntimeSpline.Length)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartSpeed = Player.ActorVelocity.Size();
		DistanceOnSpline = 0.0;

		AccFloat.SnapTo(Player.ActorVelocity.Size());
		AccVector.SnapTo(Player.ActorLocation, Player.ActorVelocity);
	
		RuntimeSpline = FHazeRuntimeSpline();
		RuntimeSpline.AddPoint(Player.ActorLocation);
		RuntimeSpline.AddPoint(Player.ActorLocation + Player.ActorVelocity.SafeNormal * Math::Min(Player.ActorVelocity.Size(), 100.0));
//		RuntimeSpline.AddPoint(UserComp.LaunchLocation - FVector::UpVector * 200.0);
		RuntimeSpline.AddPoint(UserComp.LaunchLocation - FVector::UpVector * 100.0);
		RuntimeSpline.AddPoint(UserComp.LaunchLocation);
//
//		RuntimeSpline.SetCustomEnterTangentPoint(Player.ActorVelocity);
		RuntimeSpline.SetCustomCurvature(1.0);
//		RuntimeSpline.SetCustomExitTangentPoint(UserComp.LaunchLocation + FVector::UpVector * 1000.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ActorVelocity = UserComp.LaunchVelocity;
	
		UserComp.bIsLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RuntimeSpline.DrawDebugSpline();
		PrintToScreen("Fan", 0.0, FLinearColor::Green);

//		AccVector.AccelerateTo(UserComp.LaunchLocation, LaunchTime, DeltaTime);
//		FVector DeltaMove = AccVector.Value - Player.ActorLocation;

		AccFloat.AccelerateTo(UserComp.LaunchVelocity.Size(), 3.0, DeltaTime);

		DistanceOnSpline += AccFloat.Value * DeltaTime;

		FVector LocationOnSpline = RuntimeSpline.GetLocationAtDistance(DistanceOnSpline);

		FVector DeltaMove = LocationOnSpline - Player.ActorLocation;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddDelta(DeltaMove);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}
};
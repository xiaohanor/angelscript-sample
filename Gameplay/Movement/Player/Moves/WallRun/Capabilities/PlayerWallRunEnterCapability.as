
/*
	This is the standard enter for wall run. 
	Enter if you are holding A and hitting a wall
*/
class UPlayerWallRunEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Collision);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunEnter);

	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 32;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerAirDashComponent AirDashComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Owner);
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallRunEnterActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WallRunComp.bWallRunAvailableUntilGrounded)
			return false;

		if (WallRunComp.HasActiveWallRun())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		bool bRefreshAirDash = false;
	
		FVector TraceDirection = MoveComp.MovementInput.GetSafeNormal();			
		if (TraceDirection.IsNearlyZero())
			TraceDirection = Player.ActorForwardVector;

		FPlayerWallRunData Data = WallRunComp.TraceForWallRun(Player, TraceDirection, FInstigator(this, n"ShouldActivate"));

		// If we're doing a dash enter, we might be dashing fully parallel to the wall,
		// in which case we still want to be able to enter wall run if we're within a threshold distance.
		float MinEnterInputDot = 0.0;
		if (!Data.HasValidData())
			return false;

		// Make sure that input is towards the wall
		const FVector WallDirection = -Data.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		const float InputTowardsWallDot = MoveComp.MovementInput.DotProduct(WallDirection);
		if (InputTowardsWallDot <= MinEnterInputDot)
			return false;

		// If we've previously wallrunned before becoming grounded, we only allow
		// wall runs that are in a reasonably opposite direction, so we don't allow climbing
		// a single wall with repeated wallruns
		if (WallRunComp.bHasWallRunnedSinceLastGrounded)
		{
			FVector CurrentNormal = Data.WallNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			FVector PreviousNormal = WallRunComp.LastWallRunNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			const float AngleFromPrevious = CurrentNormal.AngularDistance(PreviousNormal);
			if (AngleFromPrevious < Math::DegreesToRadians(WallRunComp.Settings.ActivationWeight))
			{
				return false;
			}
		}

		float WallRunWeight = 0.0;

		// Camera Direction
		FRotator CameraRotation = Player.ViewRotation;
		CameraRotation.Pitch = 0.0;
		const float CameraDot = 1.0 - CameraRotation.ForwardVector.DotProductLinear(WallDirection);
		WallRunWeight += CameraDot;

		// Input Direction
		const float InputDot = 1.0 - MoveComp.MovementInput.DotProductLinear(WallDirection);
		WallRunWeight += InputDot;

		WallRunWeight *= WallRunComp.Settings.ActivationWeight;

		if (WallRunWeight < (Data.Component.HasTag(ComponentTags::WallScrambleable) ? WallRunComp.Settings.WallRunScrambleEvalWeight : WallRunComp.Settings.WallRunOnlyEvalWeight))
			return false;

		ActivationParams.WallRunData = Data;
		ActivationParams.bRefreshAirDash = bRefreshAirDash;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallRunEnterActivationParams ActivationParams)
	{
		FPlayerWallRunData WallRunData =  ActivationParams.WallRunData;

		FVector WantedDirection = MoveComp.MovementInput.GetSafeNormal();
		if (WantedDirection.IsNearlyZero())
			WantedDirection = Player.ActorVelocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		
		//Determine direction scalar based on WallRight (Wallforward being Wall normal)
		float DirectionScale = Math::Sign(WallRunData.WallRight.DotProduct(WantedDirection));
		//Set Direction relative to wall right vector 
		FVector WallRunForward = WallRunData.WallRight * DirectionScale;
		//Construct the unit vector entry angle for movement along the wall (horizontal + vertical)
		FVector WallVelocity = FQuat(WallRunData.WallNormal, Math::DegreesToRadians(30.0 * DirectionScale)) * WallRunForward;
		WallVelocity *= Math::Clamp(Player.ActorVelocity.Size(), WallRunComp.Settings.MinimumSpeed, WallRunComp.Settings.MaximumSpeed);

		// // Rotate a flat vector up to the rotation of the wall. This will not account for any vertical speed in the direction of world up
		// float Angle = MoveComp.WorldUp.AngularDistance(WallRunData.WallNormal);
		// FQuat VelocityRotator = FQuat(WallRunData.WallRight, Angle);
		// FVector WallVelocity = VelocityRotator * WantedDirection;
		
		// // Constrain to remove any of the 'vertical' velocity that was rotated, which would otherwise push us in/out from the wall
		// WallVelocity = WallVelocity.ConstrainToPlane(WallRunData.WallNormal);
		// WallVelocity = WallVelocity.GetSafeNormal() * Math::Clamp(Player.ActorVelocity.Size(), WallRunComp.Settings.MinimumSpeed, WallRunComp.Settings.MaximumSpeed);

		// // Make sure the wall run is within the range
		// float VerticalAngle = (Math::Acos(WallRunData.WallRotation.RightVector.DotProduct(WallVelocity.GetSafeNormal())) * RAD_TO_DEG) - 90.0;
		// if (90.0 - Math::Abs(VerticalAngle) < WallRunComp.Settings.LowestVerticalAngle)
		// {
		// 	FQuat NewWallVelocityRotator = FQuat(WallRunData.WallNormal, (90.0 - WallRunComp.Settings.LowestVerticalAngle) * DEG_TO_RAD * Math::Sign(VerticalAngle));
		// 	WallVelocity = (NewWallVelocityRotator * WallRunData.WallUp) * WallVelocity.Size();
		// }

		WallRunData.InitialVelocity = WallVelocity;
		WallRunComp.StartWallRun(WallRunData);

		if (ActivationParams.bRefreshAirDash)
			Player.ResetAirDashUsage();
	}
}

struct FPlayerWallRunEnterActivationParams
{
	FPlayerWallRunData WallRunData;
	bool bRefreshAirDash = false;
}
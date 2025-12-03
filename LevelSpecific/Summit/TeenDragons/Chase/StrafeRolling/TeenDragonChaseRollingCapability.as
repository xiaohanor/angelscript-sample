class UTeenDragonChaseRollingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonChaseComponent ChaseComp;
	UTeenDragonRollComponent RollComp;	
	UCameraUserComponent CameraUserComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;
	// USteppingMovementData Movement;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		ChaseComp = UTeenDragonChaseComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));
		// Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!ChaseComp.bIsInChase)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!ChaseComp.bIsInChase)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(Player.ActorRotation);
		DragonComp.NonOrientedInputInstigators.AddUnique(this);

		RollComp.RollingInstigators.AddUnique(this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonRoll, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.NonOrientedInputInstigators.RemoveSingleSwap(this);

		RollComp.RollingInstigators.RemoveSingleSwap(this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonRoll, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// RollComp.IgnoreRollThroughActors(Movement);

				FVector MovementInput = MoveComp.MovementInput;

				float PlayerForwardDotViewForward = CameraUserComp.ViewRotation.ForwardVector.DotProduct(Player.ActorForwardVector);

				if(PlayerForwardDotViewForward < 0)
					MovementInput *= -1;

				auto SplinePos = ChaseComp.ChaseSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
				
				FRotator WantedRotation = FRotator(0, MovementInput.Y * TeenDragonChaseRollingSettings::MaxInputRotation.Yaw, 0);

				WantedRotation = SplinePos.WorldTransform.TransformRotation(WantedRotation);
				AccRotation.AccelerateTo(WantedRotation, TeenDragonChaseRollingSettings::TurningAccelerationDuration, DeltaTime);

				Movement.SetRotation(AccRotation.Value);

				float RubberBandingSpeed = GetRubberBandingSpeed(SplinePos);

				// Note: We had to make the dragons always move with the spline so as to prevent them "not escaping" or "getting crushed by beast"
				float ForwardSpeed = TeenDragonChaseRollingSettings::BaseSpeed  + RubberBandingSpeed;
				SplinePos.Move(ForwardSpeed * DeltaTime);

				FVector Velocity = Player.ActorForwardVector * ForwardSpeed;
				FVector DesiredLocation = Player.ActorLocation + Velocity * DeltaTime;
				FVector ClampedLocation = DesiredLocation.PointPlaneProject(SplinePos.WorldLocation, SplinePos.WorldForwardVector);
				Movement.AddDelta(ClampedLocation - Player.ActorLocation);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();


				TEMPORAL_LOG(ChaseComp)
					.DirectionalArrow("Wanted Rotation", Player.ActorLocation, WantedRotation.ForwardVector * 5000, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Actor Forward", Player.ActorLocation, Player.ActorForwardVector * 5000, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Actor Up", Player.ActorLocation, Player.ActorUpVector * 5000, 10, 40, FLinearColor::Blue)
					.DirectionalArrow("Actor Right", Player.ActorLocation, Player.ActorRightVector * 5000, 10, 40, FLinearColor::Green)
					.Value("Movement Input", MovementInput)
					.Value("Acc Rotation", AccRotation.Value)
				;

				// RollComp.HandleRollingOverlaps();
				// RollComp.HandleRollingImpact();
			}
			else
			{
				if(MoveComp.IsOnWalkableGround())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}
		}

		MoveComp.ApplyMove(Movement);
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
	}

	float GetRubberBandingSpeed(FSplinePosition CurrentSplinePos) const
	{
		float RubberBandingSpeed = 0;

		auto OtherSplinePos = ChaseComp.ChaseSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorLocation);

		float DeltaDistance = OtherSplinePos.CurrentSplineDistance - CurrentSplinePos.CurrentSplineDistance;
		DeltaDistance = Math::Clamp(DeltaDistance, -TeenDragonAutoGlideStrafeSettings::DistanceForMaxRubberBandingSpeed, TeenDragonAutoGlideStrafeSettings::DistanceForMaxRubberBandingSpeed);
		float DistToMaxAlpha = Math::Abs(DeltaDistance) / TeenDragonAutoGlideStrafeSettings::DistanceForMaxRubberBandingSpeed;
		RubberBandingSpeed = Math::Sign(DeltaDistance) * DistToMaxAlpha * TeenDragonAutoGlideStrafeSettings::MaxRubberBandingSpeed;	

		TEMPORAL_LOG(ChaseComp)
			.Value("RubberBanding speed", RubberBandingSpeed)
		;

		return RubberBandingSpeed;
	}
}
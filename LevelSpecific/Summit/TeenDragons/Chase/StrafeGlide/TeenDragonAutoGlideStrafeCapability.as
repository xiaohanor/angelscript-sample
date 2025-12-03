class UTeenDragonAutoGlideStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonChaseComponent ChaseComp;
	UCameraUserComponent CameraUserComp;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		ChaseComp = UTeenDragonChaseComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
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
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::High);

		Player.BlockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSpray, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAirGlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.NonOrientedInputInstigators.RemoveSingleSwap(this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		MoveComp.ClearMovementInput(this);

		Player.UnblockCapabilities(TeenDragonCapabilityTags::TeenDragonAcidSpray, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(TeenDragonCapabilityTags::BlockedWhileInTeenDragonAirGlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector MovementInput = FVector(1 - MovementRaw.Y, MovementRaw.Y, 0.0);

				MoveComp.ApplyMovementInput(MovementInput, this, EInstigatePriority::Normal);

				auto SplinePos = ChaseComp.ChaseSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
				
				FRotator WantedRotation = FRotator(
					MovementInput.X * TeenDragonAutoGlideStrafeSettings::MaxInputRotation.Pitch, 
					-MovementInput.Y * TeenDragonAutoGlideStrafeSettings::MaxInputRotation.Yaw, 0);

				WantedRotation = SplinePos.WorldTransform.TransformRotation(WantedRotation);
				AccRotation.AccelerateTo(WantedRotation, TeenDragonAutoGlideStrafeSettings::TurningAccelerationDuration, DeltaTime);

				Movement.SetRotation(AccRotation.Value);

				float RubberBandingSpeed = GetRubberBandingSpeed(SplinePos);

				// Note: We had to make the dragons always move with the spline so as to prevent them "not escaping" or "getting crushed by beast"
				float ForwardSpeed = TeenDragonAutoGlideStrafeSettings::BaseSpeed + RubberBandingSpeed;
				SplinePos.Move(ForwardSpeed * DeltaTime);

				FVector Velocity = Player.ActorForwardVector * ForwardSpeed;
				FVector DesiredLocation = Player.ActorLocation + Velocity * DeltaTime;
				FVector ClampedLocation = DesiredLocation.PointPlaneProject(SplinePos.WorldLocation, SplinePos.WorldForwardVector);
				Movement.AddDelta(ClampedLocation - Player.ActorLocation);
				//Movement.AddVelocity(Velocity);



				TEMPORAL_LOG(ChaseComp)
					.DirectionalArrow("Wanted Rotation", Player.ActorLocation, WantedRotation.ForwardVector * 5000, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Actor Forward", Player.ActorLocation, Player.ActorForwardVector * 5000, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Actor Up", Player.ActorLocation, Player.ActorUpVector * 5000, 10, 40, FLinearColor::Blue)
					.DirectionalArrow("Actor Right", Player.ActorLocation, Player.ActorRightVector * 5000, 10, 40, FLinearColor::Green)
					.Value("Movement Input", MovementInput)
					.Value("Acc Rotation", AccRotation.Value)
				;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
		}

		MoveComp.ApplyMove(Movement);
		DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AcidTeenHover);
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


class UPerchSplineAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointSpline);

	default CapabilityTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent FloorMotionComp;

	float VerticalDistanceToSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (PerchComp.GetState() != EPlayerPerchState::PerchingOnSpline)
			return false;

		if (MoveComp.HasCustomMovementStatus(n"Perching"))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) <= 0.0)
		{
			if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
				return true;
			if (VerticalDistanceToSpline < 5.0)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Activated", 3.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				//if we are in a perchspline then detect our distance to spline
				if(PerchComp.Data.bInPerchSpline)
				{
					float SplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
					FVector SplineLocation = PerchComp.Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);

					VerticalDistanceToSpline = (Player.ActorLocation - SplineLocation).DotProduct(MoveComp.WorldUp);
				}

				//Vertical
				float VerticalVelocity = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
				float VerticalDelta = VerticalVelocity * DeltaTime;
				VerticalDelta -= MoveComp.GetGravityForce() * DeltaTime * DeltaTime * 0.5;
				VerticalVelocity -= MoveComp.GetGravityForce() * DeltaTime;

				Movement.AddDeltaWithCustomVelocity(MoveComp.WorldUp * VerticalDelta, MoveComp.WorldUp * VerticalVelocity);

				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveInput,
					MoveComp.HorizontalVelocity,
					DeltaTime
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);
				Movement.InterpRotationToTargetFacingRotation(FloorMotionComp.Settings.FacingDirectionInterpSpeed);

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}
};
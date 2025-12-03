struct FSwarmBoatRapidsSplineInfo
{
	FTransform Transform;
	FVector Location;
	float Distance;

	float GetWidth() const property
	{
		return Transform.Scale3D.Y;
	}
}

class USwarmBoatRapidsMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::BoatRapidsMovementCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 95;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	USwarmBoatSettings BoatSettings;
	USwarmBoatRapidsSettings RapidsSettings;

	UHazeSplineComponent SplineComponent;

	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSweepingMovementData();

		BoatSettings = USwarmBoatSettings::GetSettings(Player);
		RapidsSettings = USwarmBoatRapidsSettings::GetSettings(Player);

		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return false;

		if (!SwarmBoatComponent.IsInRapids())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (!SwarmBoatComponent.IsBoatActive())
		// 	return true;

		if (!SwarmBoatComponent.IsInRapids())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineComponent = SwarmBoatComponent.GetRapidsSpline();

		Player.BlockCapabilities(CapabilityTags::Movement, this);

		CameraSettings.FOV.ApplyAsAdditive(5, this, 1.0);

		FHazeCameraClampSettings ClampSettings;
		ClampSettings.ApplyClampsPitch(-10, 30);
		ClampSettings.ApplyClampsYaw(20, 20);
		CameraSettings.Clamps.Apply(ClampSettings, this, 1.0);

		SpeedEffect::RequestSpeedEffect(Player, 0.8, this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineComponent = nullptr;

		Player.ClearCameraSettingsByInstigator(this);
		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Debug::DrawDebugString(Player.ActorCenterLocation, "omg SO temp");

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FSwarmBoatRapidsSplineInfo SplineInfo = GetSplineInfoAtLocation(Player.ActorLocation, 0);
				FVector Input = GetInput(SplineInfo);

				FVector Velocity = MovementComponent.Velocity;
				Velocity = SplineInfo.Transform.Rotation.Vector() * RapidsSettings.MaxSpeed;

				// Add input
				// Eman TODO: Move mesh instead?
				Velocity += Input * RapidsSettings.MaxSpeed * DeltaTime * 20;

				ConstrainToSplineWidth(Velocity, SplineInfo, DeltaTime);
				ConstrainToSplinePlane(Velocity, SplineInfo, DeltaTime);

				MoveData.AddVelocity(Velocity);

				if (!Velocity.IsNearlyZero())
					MoveData.SetRotation(SplineInfo.Transform.Rotation);

				// FQuat MeshRotation = Math::QInterpTo(SwarmDroneComponent.DroneMesh.ComponentQuat, SplineInfo.Transform.Rotation, DeltaTime, 10);

				// AArghhh so temp!!
				float LolNoise = Math::PerlinNoise1D(Time::GameTimeSeconds * 0.5);
				FQuat TargetRotation = FQuat(SplineInfo.Transform.Rotation.UpVector, LolNoise) * SplineInfo.Transform.Rotation ;
				FQuat MeshRotation = Math::QInterpTo(SwarmDroneComponent.DroneMesh.ComponentQuat,  TargetRotation, DeltaTime, 10);
				
				SwarmDroneComponent.DroneMesh.SetWorldRotation(MeshRotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}

	void ConstrainToSplinePlane(FVector& Velocity, const FSwarmBoatRapidsSplineInfo& SplineInfo, float DeltaTime)
	{
		FVector PlayerToSplinePlane = (SplineInfo.Location - Player.ActorLocation).ConstrainToDirection(SplineInfo.Transform.Rotation.UpVector);
		Velocity += PlayerToSplinePlane / DeltaTime;
	}

	void ConstrainToSplineWidth(FVector& Velocity, const FSwarmBoatRapidsSplineInfo& SplineInfo, float DeltaTime)
	{
		FVector MoveDelta = Velocity * DeltaTime;
		float SplineWidth = SplineInfo.Width * RapidsSettings.SplineWidthScaleMultiplier;
		float SplineWidthSquared = Math::Square(SplineWidth);

		FVector NextPlayerLocation = Player.ActorLocation + MoveDelta;
		FSwarmBoatRapidsSplineInfo NextSplineInfo = GetSplineInfoAtLocation(NextPlayerLocation, 0);

		// float DistanceToSpline = NextSplineInfo.Transform.Location.DistSquared(NextPlayerLocation);
		FVector PlayerToSpline = (SplineInfo.Location - Player.ActorLocation).ConstrainToDirection(SplineInfo.Transform.Rotation.RightVector);
		float DistanceToSplineSquared = PlayerToSpline.SizeSquared();
		if (DistanceToSplineSquared > SplineWidthSquared)
		{

			// Get difference and remove from velocity
			float Delta = Math::Sqrt(DistanceToSplineSquared) - Math::Sqrt(SplineWidthSquared);
			if (Math::IsNearlyZero(Delta, DeltaTime))
				return;

			FVector Correction = PlayerToSpline.GetSafeNormal() * Delta;
			MoveDelta += Correction;

			// // Redirect towards spline
			// FVector Normal = (NextSplineInfo.Transform.Location - NextPlayerLocation).GetSafeNormal();
			// FVector Reflection = Math::GetReflectionVector(MoveDelta.GetSafeNormal(), Normal).GetSafeNormal();
			// MoveDelta += Reflection * Delta;
		}

		Velocity = MoveDelta / DeltaTime;
	}

	FVector GetInput(const FSwarmBoatRapidsSplineInfo& SplineInfo)
	{
		return MovementComponent.MovementInput.ConstrainToDirection(SplineInfo.Transform.Rotation.RightVector);
	}

	FSwarmBoatRapidsSplineInfo GetSplineInfoAtLocation(FVector Location, float Offset) const
	{
		FSwarmBoatRapidsSplineInfo SplineInfo;
		SplineInfo.Distance = SplineComponent.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation) + Offset;
		SplineInfo.Transform = SplineComponent.GetWorldTransformAtSplineDistance(SplineInfo.Distance);
		SplineInfo.Location = SplineComponent.GetWorldLocationAtSplineDistance(SplineInfo.Distance);

		return SplineInfo;
	}
}
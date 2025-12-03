class USwarmBotMovementComponent : UActorComponent
{
	ASwarmBot BotOwner;
	USphereComponent Collider;

	FVector ActualVelocity;
	FVector Velocity;
	FVector WorldUp = FVector::UpVector;

	const float MaxSpeed = 1200.0;
	const float RadialBounds = 300.0;

	private FVector DroneVelocity;

	FHazeAcceleratedQuat AcceleratedBotRotation;

	USwarmDroneMovementTrailCrumb TargetTrailCrumb = nullptr;

	UPrisonSwarmMovementSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BotOwner = Cast<ASwarmBot>(Owner);
		Collider = USphereComponent::Get(Owner);
		Settings = UPrisonSwarmMovementSettings::GetSettings(BotOwner.PlayerSwarmDroneComponent.Player);

		BotOwner.PlayerSwarmDroneComponent.OnSwarmTransitionStartEvent.AddUFunction(this, n"OnSwarmTransitionStart");
		BotOwner.OnSwarmBotRespawnEvent.AddUFunction(this, n"OnBotRespawn");

		AcceleratedBotRotation.SnapTo(BotOwner.InitialTransformOnMesh.Rotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// if (BotOwner.Id < SwarmDrone::DeployedBotCount)
		// 	Debug::DrawDebugSphere(BotOwner.Collider.WorldLocation, BotOwner.Collider.SphereRadius, 12, FLinearColor::Green * BotOwner.Id * 20, 0.5);

		DroneVelocity = Owner.AttachParentActor.ActorVelocity;

		// Don't do shit if bot is not deployed
		// if (BotOwner.Id >= SwarmDrone::DeployedBotCount)
		// 	return;

		// DroneSwarmTransitionCapability handles deswarmification
		if (BotOwner.PlayerSwarmDroneComponent.bDeswarmifying)
			return;

		// DroneSwarmHoverCapability handles this movement
		if (BotOwner.PlayerSwarmDroneComponent.IsHovering())
			return;

		if (BotOwner.PlayerSwarmDroneComponent.bSwarmDashing || BotOwner.PlayerSwarmDroneComponent.IsDashing())
			return;

		// Handle in hover dash capability
		if (BotOwner.PlayerSwarmDroneComponent.bHoverDashing)
			return;

		// Handle in float capability
		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::BoatCapability))
			return;

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmDroneJumpCapability))
			return;

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmGliderCapability))
			return;

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsPlayerDead())
			return;

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirMovementCapability))
			return;

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmDroneCongaLineCapability))
			return;

		if (BotOwner.PlayerSwarmDroneComponent.IsSwarmBotMovementBlocked())
			return;

		// =========================
// >>>>>>  Eman TODO: IN FACT! Handle all movement in their respective capabilities, this should only move and trace
		// ---------------------------------------------------------------

		// Only allow movement if swarm is working normally
		if (!BotOwner.bSwarmActive)
		{
			// Rotate the little guys to make it look they are moving the ball
			SimulateSlatedDroneBallAcceleration(DeltaTime);

			// Do some fun translations here
			FVector DroneCoreToBot = (BotOwner.ActorLocation - BotOwner.PlayerSwarmDroneComponent.DroneMesh.WorldLocation).GetSafeNormal();
			float Alignment = DroneCoreToBot.DotProduct(WorldUp);
			if (Alignment < 0.0)
			{
				// Squish the bottom bots up
				FVector Offset = BotOwner.RootComponent.RelativeTransform.TransformVectorNoScale(DroneCoreToBot) * 15.0 * Math::Abs(Alignment);
				BotOwner.RootComponent.SetRelativeLocation(BotOwner.InitialTransformOnMesh.Location + Offset);
			}
			else
			{
				// Extend upper bots up
				// Height offset
				FVector Offset = BotOwner.RootComponent.RelativeTransform.TransformVectorNoScale(DroneCoreToBot) * Alignment * DroneVelocity.Size() * DeltaTime * 0.5;
				BotOwner.RootComponent.SetRelativeLocation(BotOwner.InitialTransformOnMesh.Location + Offset);

				// Horizontal offset (squeeze gubben!)
				// FVector VelocityNormal = DroneVelocity.GetSafeNormal().CrossProduct(WorldUp).GetSafeNormal();
				// float HorizontalAlingment = VelocityNormal.DotProduct(-DroneCoreToBot);
				// Offset = BotOwner.RootComponent.RelativeTransform.TransformVectorNoScale(VelocityNormal) * DroneVelocity.Size() * DeltaTime * HorizontalAlingment * 2;
			}

			return;
		}

		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmDroneHijackCapability))
			return;
		
		if (BotOwner.PlayerSwarmDroneComponent.Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmAirductCapability))
			return;

		FVector FrameVelocity;
		FVector FrameWorldUp = WorldUp;

		if (BotOwner.bRespawning)
		{
			TickRespawnMovement(FrameVelocity, DeltaTime);
		}
		else
		{
			// Get target velocity
			FrameVelocity = CalculateTargetVelocity(DeltaTime);

			FVector MoveDelta = Velocity * DeltaTime;
			if(!MoveDelta.IsNearlyZero())
			{
				// Trace for hits and redirect
				// Eman TODO: Add stepups
				FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collider);
				Trace.UseSphereShape(Collider.SphereRadius);
				FHitResultArray HitResults = Trace.QueryTraceMulti(Collider.WorldLocation, Collider.WorldLocation + MoveDelta);
				for (FHitResult HitResult : HitResults)
				{
					if (HitResult.bBlockingHit)
					{
						// Handle collisions with other bots
						if (HitResult.Actor != nullptr && HitResult.Actor.IsA(ASwarmBot))
						{
							float SpeedFraction = Math::Saturate(Velocity.Size() / MaxSpeed);
							FVector Horizontal = HitResult.ImpactNormal.ConstrainToPlane(WorldUp);
							// FrameVelocity += Horizontal * 12.0 * Math::Max(0.5, SpeedFraction); // * 60

							// Constrain bounce to upper dome
							FVector Vertical = HitResult.ImpactNormal.ConstrainToDirection(WorldUp);
							Vertical = Vertical * HitResult.ImpactNormal.DotProduct(WorldUp);

							float BounceMultiplier = 20.0 + (/*SpeedFraction */ HitResult.PenetrationDepth * 2.0);
							FVector Bounce = Vertical + Horizontal * BounceMultiplier;

							// FrameVelocity = FrameVelocity.RotateTowards(Bounce, (HitResult.Distance + HitResult.PenetrationDepth));
							FrameVelocity += Bounce;
						}
						else
						{
							// Handle ground
							float SlopeAngle = Math::RadiansToDegrees(Math::Acos(HitResult.ImpactNormal.DotProduct(WorldUp)));
							if (SlopeAngle < 45.0)
							{
								// Move away from impact
								FVector BotToImpact = HitResult.ImpactPoint - BotOwner.ActorLocation;
								FVector NextBotLocation = BotOwner.ActorLocation + HitResult.ImpactNormal * (BotOwner.Collider.BoundsRadius - BotToImpact.Size());

								// Subtract used delta and move along binormal
								float DeltaMagnitude = FrameVelocity.Size() - BotToImpact.Size();
								if (DeltaMagnitude > 0.0)
								{
									FVector Horizontal = FrameVelocity.CrossProduct(HitResult.ImpactNormal);
									FVector Binormal = HitResult.ImpactNormal.CrossProduct(Horizontal);
									NextBotLocation += Binormal.GetSafeNormal() * DeltaMagnitude;
								}

								FrameVelocity = NextBotLocation - BotOwner.ActorLocation;
							}
							// Handle wall
							else
							{
								// Do cheap stuff
								FrameVelocity = FrameVelocity * 0.5 + HitResult.ImpactNormal * FrameVelocity.Size() * 0.5;
								FrameWorldUp = HitResult.ImpactNormal;
							}
						}
					}
				}
			}

			if (!ShouldFallOverEdge())
				HandleEdge(FrameVelocity);
		}

		Velocity = FrameVelocity.GetClampedToMaxSize(GetSpeedClamp());

		// Move!!
		FVector LastLocation = BotOwner.ActorLocation;

		// Rotate!!
		float RotationSpeedMultiplier = Math::Min(0.1, Velocity.Size() / MaxSpeed) * 50.0;
		FQuat Rotation = FQuat::FastLerp(Owner.ActorRotation.Quaternion(), FQuat::MakeFromXZ(Velocity, FrameWorldUp), RotationSpeedMultiplier * DeltaTime);

			// float SpeedMultiplier = Velocity.Size() / 1000.0;
			// float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 40.0 + BotOwner.Id) * 5.0 * SpeedMultiplier);
			// FQuat Jiggle = FQuat(FVector::ForwardVector, Roll);
			// Rotation *= Jiggle;


		// Chill the fuck down if there is no velocity
		if (Velocity.Size() > 10.0)
		{
			Owner.SetActorLocationAndRotation(Owner.ActorLocation + Velocity * DeltaTime, Rotation);
		}
		else
		{
			Owner.SetActorRotation(Rotation);
		}

		ActualVelocity = (BotOwner.ActorLocation - LastLocation) / DeltaTime;

	}

	bool ShouldFallOverEdge()
	{
		if (!BotOwner.PlayerSwarmDroneComponent.IsPlayerGrounded())
			return true;

		if (BotOwner.PlayerSwarmDroneComponent.MoveComp.WasFalling())
			return true;

		// Eman TODO: Pass as param to optimize
		// I don't know, maybe we check if player is below?
		FVector BotToPlayer = Owner.AttachParentActor.RootComponent.WorldLocation - Owner.ActorLocation;
		if (BotToPlayer.GetSafeNormal().DotProduct(WorldUp) < 0)
		{
			// How far below is player?
			// if (BotToPlayer.ConstrainToDirection(WorldUp).Size() > BotOwner.Collider.SphereRadius * 0.3)
			{
				// Only fall if horizontal distance is important
				float HorizontalDistance = BotToPlayer.ConstrainToPlane(WorldUp).Size();
				if (HorizontalDistance > 100.0)
					return true;
			}
		}

		// float VerticalDistance = BotToPlayer.ConstrainToDirection(WorldUp).Size();
		// if (VerticalDistance > BotOwner.Collider.SphereRadius * 0.1)
		// 	return true;

		// float HorizontalDistance = BotToPlayer.ConstrainToPlane(WorldUp).Size();
		// if (HorizontalDistance > 200.0)
		// 	return true;

		return false;
	}

	void HandleEdge(FVector& OutVelocity)
	{
		const float StepDown = 1.0;

		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collider);
		Trace.UseSphereShape(Collider.SphereRadius);
		Trace.IgnorePlayers();

		FHitResult HitResult = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation - WorldUp * StepDown);
		bool bGrounded = HitResult.bBlockingHit;

		if (bGrounded)
		{
			Trace.UseLineWithShapeOffset();

			// Eman TODO: Filip added a vertical offset here to fix the bots not being able to walk on brushes.
			const FVector VerticalOffset = WorldUp * (Collider.SphereRadius * 0.5);

			FVector TraceStart = Owner.ActorLocation + OutVelocity.ConstrainToPlane(WorldUp) * Time::GetActorDeltaSeconds(BotOwner) * 2.0 + VerticalOffset;
			HitResult = Trace.QueryTraceSingle(TraceStart, TraceStart - WorldUp * Collider.SphereRadius * 1.6);
			if (!HitResult.bBlockingHit)
			{
				OutVelocity = -OutVelocity * 0.1;

				// Eman TODO: How to steer towards player and avoid other edges without 1 thousand traces?
				// FVector BotToPlayer = (Owner.AttachParentActor.RootComponent.WorldLocation - Owner.ActorLocation);
				// OutVelocity = OutVelocity.GetReflectionVector(BotToPlayer) - OutVelocity * 0.5;
				// OutVelocity = OutVelocity.GetReflectionVector(-OutVelocity);
			}
		}
	}

	FVector CalculateTargetVelocity(float DeltaTime)
	{
		// Inherit last frame's velocity but reduce horizontal to give weight
		FVector TargetVelocity = Velocity.ConstrainToPlane(WorldUp) * 0.2 + Velocity.ConstrainToDirection(WorldUp);
		if (!HasClearPathToPlayer())
		{
			USwarmDroneMovementTrailComponent TrailComponent = USwarmDroneMovementTrailComponent::Get(BotOwner.PlayerSwarmDroneComponent.Player);
			if (TrailComponent != nullptr && TrailComponent.GetTrailSize() > 0)
			{
				if (TargetTrailCrumb == nullptr)
				{
					TargetTrailCrumb = TrailComponent.GetTrail()[0];
				}
				else
				{
					float DistanceToCrumb = BotOwner.ActorLocation.Distance(TargetTrailCrumb.Location);
					if (DistanceToCrumb < 50. && TargetTrailCrumb.NextCrumb != nullptr)
					{
						TargetTrailCrumb = TargetTrailCrumb.NextCrumb;
					}
				}

				FVector BotToCrumb = TargetTrailCrumb.Location - BotOwner.ActorLocation;
				TargetVelocity = BotToCrumb * 10.;
			}
		}
		else
		{
			TargetTrailCrumb = nullptr;

			FVector Gravity = -WorldUp * Drone::Gravity;

			FVector BotToPlayer = (Owner.AttachParentActor.RootComponent.WorldLocation - Owner.ActorLocation).ConstrainToPlane(WorldUp);
			float DistanceToPlayer = Math::Max(DeltaTime, BotToPlayer.Size());
			BotToPlayer.Normalize();

			float RadialMultiplier = (DistanceToPlayer / RadialBounds) * 1.0; //* 0.5

			// Accelerate towards center the further away it is
			TargetVelocity += BotToPlayer * (DistanceToPlayer / Math::Sqrt(DistanceToPlayer * DeltaTime)) * Math::Pow(RadialMultiplier, 2.0) * Settings.StickTogetherMultiplier;

			// Apply gravity
			TargetVelocity += Gravity * DeltaTime;

			// Add some resting movement to organify der swarm
			const float RestingMovementSpeed = 50;
			if (DroneVelocity.IsNearlyZero(RestingMovementSpeed))
			{
				float OddMultiplier = BotOwner.Id % 3 == 0 ? -1 : 1;
				FVector Tangent = BotToPlayer.CrossProduct(WorldUp) * OddMultiplier * RestingMovementSpeed;
				TargetVelocity += Tangent;
			}

			// Add friction
			FVector Friction = -TargetVelocity * 8.0 * (1.0 - RadialMultiplier);
			Friction = Friction.VectorPlaneProject(WorldUp) * DeltaTime;
			Friction = Friction.GetClampedToMaxSize(Velocity.Size());
			TargetVelocity += Friction;

			// Add drone velocity
			FVector PlayerVelocity = DroneVelocity.ConstrainToPlane(WorldUp);
			TargetVelocity += PlayerVelocity * (1.1333 - RadialMultiplier);
		}

		// Debug::DrawDebugCircle(Owner.AttachParentActor.ActorLocation, RadialBounds, 12, FLinearColor::DPink);

		// float UniqueMultiplier = Math::NormalizeToRange((Math::PerlinNoise1D(Time::GameTimeSeconds * BotOwner.Id)), 25, 80);
		// return Velocity.RotateTowards(TargetVelocity, UniqueMultiplier * 1000).GetSafeNormal() * TargetVelocity.Size();
		return TargetVelocity;
	}

	// Inherit last frame's velocity and apply gravity;
	// we are done when bot touches ground
	void TickRespawnMovement(FVector& FrameVelocity, float DeltaTime)
	{
		FrameVelocity = Velocity - WorldUp * Drone::Gravity * DeltaTime;
		FrameVelocity += DroneVelocity * 3.0 * DeltaTime;

		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collider);
		Trace.UseSphereShape(Collider.SphereRadius);
		Trace.IgnorePlayers();

		FVector FrameDelta = FrameVelocity * DeltaTime;
		if (!FrameDelta.IsNearlyZero())
		{
			FHitResult HitResult = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + FrameDelta);
			if (HitResult.bBlockingHit)
				BotOwner.bRespawning = false;
		}
	}

	void SimulateSlatedDroneBallAcceleration(float DeltaTime)
	{
		FQuat RotationOffset = FQuat::Identity;
		FVector DroneCoreToBot = (BotOwner.ActorLocation - BotOwner.PlayerSwarmDroneComponent.DroneMesh.WorldLocation).GetSafeNormal();

		if (!DroneVelocity.IsNearlyZero(20.0))
		{
			float FaceDot = DroneVelocity.GetSafeNormal().DotProduct(DroneCoreToBot);
			if (FaceDot < 0)
			{
				float AlingmentMultiplier = Math::Min(DroneCoreToBot.DotProduct(WorldUp), 0.0);
				if (AlingmentMultiplier > -0.8 && AlingmentMultiplier < -0.6)
				{
					// AlingmentMultiplier *= BotOwner.PlayerSwarmDroneComponent.CurrentSpeedFraction;

					float Angle = -20 * Math::Abs(AlingmentMultiplier * 4);
					FVector RotationAxis = DroneVelocity.GetSafeNormal();
					RotationAxis = BotOwner.PlayerSwarmDroneComponent.Player.ActorVelocity.ConstrainToPlane(WorldUp).GetSafeNormal();

					RotationAxis = RotationAxis.CrossProduct(WorldUp);
					RotationAxis = BotOwner.ActorTransform.InverseTransformVector(RotationAxis);
					// Debug::DrawDebugDirectionArrow(BotOwner.ActorLocation, BotOwner.ActorTransform.TransformVector(RotationAxis), 100, 1, FLinearColor::Green, 1);

					RotationOffset = FQuat(RotationAxis, Math::DegreesToRadians(Angle));
				}
			}
		}

		// Rotate bot to give slate-acceleration appearance
		FQuat Rotation = BotOwner.InitialTransformOnMesh.Rotation * RotationOffset;
		float AccelerationTime = Math::Min(1.0, 90.0 / Math::Max(DroneVelocity.Size(), DeltaTime));
		AcceleratedBotRotation.AccelerateTo(Rotation, AccelerationTime, DeltaTime);
		BotOwner.RootComponent.SetRelativeRotation(AcceleratedBotRotation.Value);
	}

	float GetSpeedClamp()
	{
		float Clamp = Math::Max(MaxSpeed, DroneVelocity.Size());

		if (BotOwner.bRespawning)
			Clamp *= 2.0;

		return Clamp;
	}

	bool HasClearPathToPlayer()
	{
		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(Collider);
		// Trace.UseSphereShape(Collider.SphereRadius * 0.9);
		Trace.UseLine();
		Trace.IgnorePlayers();

		FVector HeightOffset = WorldUp * Collider.SphereRadius * 0.5;
		FHitResult HitResult = Trace.QueryTraceSingle(Owner.ActorLocation + HeightOffset, Owner.AttachParentActor.RootComponent.WorldLocation);

		return !HitResult.bBlockingHit;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBotRespawn()
	{
		AHazePlayerCharacter Player = BotOwner.PlayerSwarmDroneComponent.Player;

		FVector SpawnLocation = Player.ViewLocation;
		float Direction = Math::RandRange(0.3, 1.0) * (Math::RandBool() ? 1.0 : -1.0);
		SpawnLocation += Player.ViewRotation.RightVector * Direction * 200.0;

		Owner.SetActorLocation(SpawnLocation);

		FVector CameraToPlayer = Player.ActorLocation - Player.ViewLocation;
		Velocity = (CameraToPlayer + WorldUp) * 20.0;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwarmTransitionStart(bool bSwarmifying)
	{
		if (bSwarmifying)
			Velocity = Owner.AttachParentActor.ActorVelocity;
	}
}
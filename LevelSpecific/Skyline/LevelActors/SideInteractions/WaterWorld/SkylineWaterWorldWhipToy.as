class ASkylineWaterWorldWhipToy : AWhipSlingableObject
{
	default bCanDamagePlayer = false;
	default bDestroyOnImpact = false;
	default bImpactDamage = false;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineWaterWorldWhipToyFaux> WaterFauxClass;
	ASkylineWaterWorldWhipToyFaux FauxWaterActor;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UStaticMeshComponent MeshComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	USphereComponent PlayerOverlapper;
	default PlayerOverlapper.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor PoolConstrainSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor CarCrashPoolConstrainSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor PoolCurrentSpline;

	UPROPERTY(EditInstanceOnly)
	ASkylineWaterWorldDuckRowSpline MainPoolRowSpline;

	UPROPERTY(EditInstanceOnly)
	ASkylineWaterWorldDuckRowSpline CrashPoolRowSpline;

	bool bIsInCrashPool = false;
	bool bWasInPool = false;
	bool bInPool = false;
	float LastBumpFrame = 0.0;
	float WaveTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		FName FauxName(FString(ActorNameOrLabel + "_Faux"));
		FauxWaterActor = SpawnActor(WaterFauxClass, ActorLocation, ActorRotation, FauxName, true);
		FauxWaterActor.MakeNetworked(this, 0);
		FinishSpawningActor(FauxWaterActor);
		FauxWaterActor.FauxTranslation.OnConstraintHit.AddUFunction(this, n"HitWall");
		PlayerOverlapper.OnComponentBeginOverlap.AddUFunction(this, n"PlayerPushInWater");
	}

	UFUNCTION()
	private void HitWall(FSplinePosition SplinePosition, EFauxPhysicsSplineTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Math::IsNearlyEqual(LastBumpFrame, Time::GameTimeSeconds, 0.01))
			return;
		LastBumpFrame = Time::GameTimeSeconds;

		FSkylineSwimmingBumpEnvRingEventData Data;
		Data.ImpulseStrength = HitStrength;
		Data.ApproxBumpPoint = SplinePosition.WorldLocation;
		USkylineWaterWorldToyEventHandler::Trigger_OnBumpIntoWall(this, Data);
	}

	UFUNCTION()
	private void PlayerPushInWater(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                               const FHitResult&in SweepResult)
	{
		if (!bWasInPool)
			return;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		UPlayerMovementComponent PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		const FVector Force = PlayerMoveComp.Velocity * 1;
		if (Network::IsGameNetworked())
			NetBounced(Player, Force);
		else
			Bounced(Player, Force);
	}

	UFUNCTION(NetFunction)
	private void NetBounced(AHazePlayerCharacter PushingPlayer, FVector Force)
	{
		Bounced(PushingPlayer, Force);
	}

	private void Bounced(AHazePlayerCharacter PushingPlayer, FVector Force)
	{
		FauxWaterActor.FauxTranslation.ApplyImpulse(PushingPlayer.ActorCenterLocation, Force);
		FSkylineSwimmingBumpRingEventData Data;
		Data.Player = PushingPlayer;
		Data.Force = Force;
		USkylineWaterWorldToyEventHandler::Trigger_OnPlayerBumpIntoSide(this, Data);
	}

	// custom behavior to be constrained by spline if in pool
	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Tick(float DeltaSeconds)
	{
		if (HasControl())
		{
			if (bThrown)
			{
				bGrabbed = false;
				if (MovementComponent.PrepareMove(Movement))
				{
					FVector Velocity = MovementComponent.Velocity;
					FVector Force;

					for (auto& Grab : GravityWhipResponseComponent.Grabs)
						Force += Grab.TargetComponent.ConsumeForce();

					FVector Acceleration = Force * GrabForceMultiplier
										- MovementComponent.Velocity * (bThrown ? ThrownDrag : GrabbedDrag)
										+ FVector::UpVector * Gravity * (bThrown && HomingProjectileComp.Target == nullptr ? 1.0 : 0.0);

					AngularVelocity -= AngularVelocity * 1.0 * DeltaSeconds;

					if(HomingProjectileComp.Target != nullptr)
					{
						FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
						if(Velocity.DotProduct(TargetLocation - ActorLocation) > 0)
						{
							float LaunchDuration = Time::GetGameTimeSince(ThrowTime);
							Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, Velocity.GetSafeNormal(), HomingStrength * LaunchDuration) * DeltaSeconds;
						}
					}

					Movement.AddVelocity(Velocity);
					Movement.AddAcceleration(Acceleration);
					Movement.BlockGroundTracingForThisFrame();
					Movement.SetRotation(GetMovementRotation(DeltaSeconds));
					MovementComponent.ApplyMove(Movement);
				}
			}

			if (bGrabbed)
				bInPool = false;

			bInPool = bInPool || IsInPool();
			if (bInPool)
			{
				bThrown = false;
				if (MovementComponent.PrepareMove(Movement))
				{
					if (!bWasInPool)
					{
						CrumbLandInWater(ActorVelocity);
						
						FVector ClosestBigPoolLocation = PoolConstrainSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
						FVector ClosestCrashPoolLocation = CarCrashPoolConstrainSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
						ASplineActor ConstrainSpline = PoolConstrainSpline;
						if (ClosestBigPoolLocation.Dist2D(ActorLocation) > ClosestCrashPoolLocation.Dist2D(ActorLocation))
						{
							ConstrainSpline = CarCrashPoolConstrainSpline;
							bIsInCrashPool = true;
						}
						FauxWaterActor.FauxTranslation.OtherSplineActor = ConstrainSpline;
						FauxWaterActor.FauxTranslation.bConstrainWithSpline = true;
						FauxWaterActor.FauxTranslation.bClockwise = false;
						FauxWaterActor.FauxTranslation.RemoveDisabler(this);
						FauxWaterActor.AccRemoveOffset.SnapTo(ActorQuat);

						FauxWaterActor.SetActorLocationAndRotation(ActorLocation, ActorRotation);
						FauxWaterActor.FauxTranslation.SetRelativeLocationAndRotation(FVector(),FQuat());
						FauxWaterActor.FauxRotateComp.SetRelativeLocationAndRotation(FVector(),FQuat());

						// FauxWaterActor.FauxTranslation.ApplyImpulse(ActorLocation - FVector::UpVector, FVector::UpVector * -90);
						bWasInPool = true;

						if (GravityWhipTargetComponent.IsDisabled())
							GravityWhipTargetComponent.Enable(this);

					}

					UpdateTranslationFaux(DeltaSeconds);
					//UpdateFauxRotationBuoyancy();

					FVector DeltaLoc = FauxWaterActor.FauxTranslation.WorldLocation - ActorLocation;
					Movement.AddDelta(DeltaLoc);
					Movement.SetRotation(FauxWaterActor.FauxRotateComp.ComponentQuat);
					Movement.BlockGroundTracingForThisFrame();
					MovementComponent.ApplyMove(Movement);
				}
			}
			else
			{
				if (bWasInPool)
				{
					FauxWaterActor.FauxTranslation.OtherSplineActor = nullptr;
					FauxWaterActor.FauxTranslation.bConstrainWithSpline = false;
					FauxWaterActor.FauxTranslation.bClockwise = false;
					FauxWaterActor.FauxTranslation.AddDisabler(this);
					bWasInPool = false;
				}
				bInPool = false;
				bIsInCrashPool = false;
			}

			if (bThrown || bInPool)
			{
				// Process movement component impacts
				if (bDestroyOnImpact || MovementComponent.PreviousVelocity.Size() > 1.0)
				{
					if (MovementComponent.HasAnyValidBlockingContacts())
					{
						auto MovementImpacts = GetImpacts();
						auto ImpactMembers = GetImpactTeamMembers();

						// Filter out any hits on local-only objects so we don't get issues in network
						for (int i = MovementImpacts.Num() - 1; i >= 0; --i)
						{
							if (MovementImpacts[i].Component == nullptr || !MovementImpacts[i].Component.IsObjectNetworked())
								MovementImpacts.RemoveAt(i);
						}

						// Reflect velocity off the impact
						for (auto HitResult : MovementImpacts)
						{
							if (HitResult.Actor == nullptr)
								continue;

							FVector Velocity = MovementComponent.PreviousVelocity;

							auto ImpactResponseComponent = UGravityWhipImpactResponseComponent::Get(HitResult.Actor);
							if (ImpactResponseComponent != nullptr && bImpactDamage)
							{
								if (ImpactResponseComponent.bIsNonStopping)
								{
									ActorVelocity = Velocity * ImpactResponseComponent.VelocityScaleAfterImpact;
								}
								else
								{
									ActorVelocity = Math::GetReflectionVector(Velocity, MovementImpacts[0].Normal) * ImpactResponseComponent.VelocityScaleAfterImpact * Bounce;
									AngularVelocity = ActorTransform.InverseTransformVectorNoScale(MovementImpacts[0].ImpactNormal.CrossProduct(Velocity) * ImpactResponseComponent.VelocityScaleAfterImpact * 0.01);
								}
							}
							else
							{
								ActorVelocity = Math::GetReflectionVector(Velocity, MovementImpacts[0].Normal) * Bounce;
								AngularVelocity = ActorTransform.InverseTransformVectorNoScale(MovementImpacts[0].ImpactNormal.CrossProduct(Velocity) * 0.01);
							}
						}

						if (bDestroyOnImpact || Time::GetGameTimeSince(TimeLastImpact) > 0.1)
						{
							CrumbProcessImpacts(MovementImpacts, ImpactMembers, MovementComponent.PreviousVelocity);
						}
					}
					else if(TryToHitMio() && Time::GetGameTimeSince(TimeLastImpact) > 0.1)
					{
						// Make it easier to hit Mio with stuff
						if(PlayerCollisionPreviousLocation.IsNearlyZero())
							PlayerCollisionPreviousLocation = ActorLocation;
						FVector Delta = ActorLocation - PlayerCollisionPreviousLocation;
						PlayerCollisionPreviousLocation = ActorLocation;

						if(!Delta.IsNearlyZero())
						{
							FHazeTraceSettings Trace = Trace::InitAgainstComponent(Game::Mio.CapsuleComponent);
							Trace.UseSphereShape(PlayerCollisionRadius);
							FHitResult Hit = Trace.QueryTraceComponent(ActorCenterLocation, ActorCenterLocation - Delta);
							if(Hit.bBlockingHit)
							{
								TArray<FHitResult> MovementImpacts;
								MovementImpacts.Add(Hit);
								CrumbProcessImpacts(MovementImpacts, TArray<AActor>(), MovementComponent.PreviousVelocity);
							}
						}					
					}
				}
			}
		}
		else
		{
			if (bThrown)
			{
				auto& Position = SyncedPosition.Position;
				SetActorLocationAndRotation(
					Position.WorldLocation,
					Position.WorldRotation
				);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLandInWater(FVector SplashVelocity)
	{
		Collision.SetCollisionProfileName(n"NoCollision");
		FSkylineWaterToyLandInWaterData Data;
		Data.SplashVelocity = SplashVelocity;
		USkylineWaterWorldToyEventHandler::Trigger_OnLandInWater(this, Data);
		UWhipSlingableObjectEventHandler::Trigger_OnRubberDuckLandInWater(this, Data);
	}

	private bool IsInPool() const
	{
		if (bGrabbed)
			return false;
		if (PoolConstrainSpline == nullptr)
			return false;
		{// big pool
			FTransform Transform = PoolConstrainSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
			FVector Diff = ActorLocation - Transform.Location;
			if (Diff.Size() < 3300)
			{
				if (Transform.Rotation.RightVector.DotProduct(Diff) > 0.0)
					return false;
				if (Diff.Z > 0) // above surface
					return false;
				return true;
			}
		}
		if (CarCrashPoolConstrainSpline == nullptr)
			return false;
		{// car crash pool
			FTransform Transform = CarCrashPoolConstrainSpline.Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
			FVector Diff = ActorLocation - Transform.Location;
			if (Diff.Size() < 3300)
			{
				if (Transform.Rotation.RightVector.DotProduct(Diff) > 0.0)
					return false;
				if (Diff.Z > 0) // above surface
					return false;
				return true;
			}
		}
		return false;
	}

	private void UpdateTranslationFaux(float DeltaSeconds)
	{
		ASplineActor PoolSpline = FauxWaterActor.FauxTranslation.OtherSplineActor;
		float Distance = PoolSpline.Spline.GetClosestSplineDistanceToWorldLocation(MeshComponent.WorldLocation);
		Distance = Math::Wrap(Distance - 300.0, 0.0, PoolSpline.Spline.SplineLength);
		FTransform Transform = PoolSpline.Spline.GetWorldTransformAtSplineDistance(Distance);

		FVector GoingAroundCurrent = - Transform.Rotation.ForwardVector * 50.0;
		FVector Outwards = Transform.Location - MeshComponent.WorldLocation;
		FVector SlightlyPushToOuterToNotGetStuckInCenter = Outwards.GetSafeNormal() * 50.0;
		SlightlyPushToOuterToNotGetStuckInCenter.Z = 0.0;

		if (!bIsInCrashPool)
			FauxWaterActor.FauxTranslation.ApplyForce(FauxWaterActor.FauxTranslation.WorldLocation - ActorForwardVector, (SlightlyPushToOuterToNotGetStuckInCenter + GoingAroundCurrent));
		FVector SlightlyBelowFaux = FauxWaterActor.FauxTranslation.WorldLocation - FVector::UpVector;

		ASkylineWaterWorldDuckRowSpline RowPool = nullptr;
		if (MainPoolRowSpline != nullptr && MainPoolRowSpline.AreAllDucksInThisPool())
			RowPool = MainPoolRowSpline;
		else if (CrashPoolRowSpline != nullptr && CrashPoolRowSpline.AreAllDucksInThisPool())
			RowPool = CrashPoolRowSpline;

		if (RowPool != nullptr)
		{
			FTransform TargetTransform = RowPool.GetDucksInARowTargetLocation(this);
			FVector Direction = TargetTransform.Location - ActorLocation;
			Direction.Z = 0.0;
			FauxWaterActor.FauxTranslation.ApplyForce(FauxWaterActor.FauxTranslation.WorldLocation - ActorForwardVector, Direction.GetSafeNormal() * 300.0);
			float RadianForce = Math::DegreesToRadians(FauxWaterActor.FauxRotateComp.ForwardVector.GetAngleDegreesTo(TargetTransform.Rotation.ForwardVector));
			if (FauxWaterActor.FauxRotateComp.ForwardVector.DotProduct(TargetTransform.Rotation.RightVector) < 0.0)
				RadianForce *= -1.0;
			FauxWaterActor.FauxRotateComp.ApplyAngularForce(RadianForce);
		}
		else
			FauxWaterActor.FauxRotateComp.ApplyAngularForce(Math::DegreesToRadians(90.0));

		FQuat FacingButUpwards = FQuat::MakeFromZX(FVector::UpVector, FauxWaterActor.ActorForwardVector);
		FauxWaterActor.AccRemoveOffset.SpringTo(FacingButUpwards, 25, 0.6, DeltaSeconds);
		FauxWaterActor.FauxTranslation.SetWorldRotation(FauxWaterActor.AccRemoveOffset.Value);

		// Debug::DrawDebugLine(FauxWaterActor.FauxTranslation.WorldLocation, FauxWaterActor.FauxTranslation.WorldLocation + FauxWaterActor.FauxTranslation.UpVector * 100);
		// Debug::DrawDebugLine(FauxWaterActor.FauxRotateComp.WorldLocation, FauxWaterActor.FauxRotateComp.WorldLocation + FauxWaterActor.FauxRotateComp.UpVector * 100, ColorDebug::Cyan);
		// Debug::DrawDebugLine(FauxWaterActor.FauxRotateComp.WorldLocation, FauxWaterActor.FauxRotateComp.WorldLocation + FauxWaterActor.FauxRotateComp.ForwardVector * 100, ColorDebug::Ruby);

		if (FauxWaterActor.FauxTranslation.WorldLocation.Z < PoolSpline.ActorLocation.Z)
		{
			float Factor = Math::Abs(PoolSpline.ActorLocation.Z - FauxWaterActor.FauxTranslation.WorldLocation.Z);
			FauxWaterActor.FauxTranslation.ApplyForce(SlightlyBelowFaux, FVector::UpVector * Factor * 50.0);
		}
		else if (FauxWaterActor.FauxTranslation.WorldLocation.Z > PoolSpline.ActorLocation.Z + 10.0)
		{
			// gravity
			FauxWaterActor.FauxTranslation.ApplyForce(SlightlyBelowFaux, -FVector::UpVector * 980.0 * 2.0);
		}

		WaveTimer = Math::Wrap(WaveTimer + DeltaSeconds, 0.0, 1.0);
		FVector WaveMovement = FVector(0.0, 0.0, Math::SinusoidalInOut(1.0, -1.0, WaveTimer) * 0.1);
		FauxWaterActor.FauxTranslation.ApplyMovement(SlightlyBelowFaux, WaveMovement);

		// avoid rings!
		TListedActors<ASkylineSwimmingRing> AllRings;
		for (auto Ring : AllRings)
		{
			FVector ToOther = Ring.FauxPlayerImpulseRotateComp.WorldLocation - FauxWaterActor.FauxRotateComp.WorldLocation;
			ToOther.Z = 0.0;
			if (ToOther.Size() < Ring.RingRadius + 50)
			{
				if (!Math::IsNearlyEqual(LastBumpFrame, Time::GameTimeSeconds, 0.01))
				{
					FVector Impulse = -ToOther.GetSafeNormal() * 1000.0 - FVector::UpVector * 500;
					FauxWaterActor.FauxTranslation.ApplyImpulse(Ring.FauxPlayerImpulseRotateComp.WorldLocation, Impulse);
					LastBumpFrame = Time::GameTimeSeconds;
					FSkylineSwimmingBumpEnvRingEventData Data;
					Data.ImpulseStrength = Impulse.Size();
					Data.ApproxBumpPoint = FauxWaterActor.FauxRotateComp.WorldLocation + ToOther * 0.5;
					USkylineWaterWorldToyEventHandler::Trigger_OnBumpIntoRing(this, Data);
				}
			}
			if (ToOther.Size() < 500)
				FauxWaterActor.FauxTranslation.ApplyForce(Ring.FauxPlayerImpulseRotateComp.WorldLocation, -ToOther.GetSafeNormal() * 100.0);
		}
	}
};
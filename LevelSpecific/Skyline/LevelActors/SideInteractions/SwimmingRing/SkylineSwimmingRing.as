class ASkylineSwimmingRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsSplineTranslateComponent FauxTranslationMio;
	default FauxTranslationMio.Shape = EFauxPhysicsSplineTranslateShape::Cylinder;
	default FauxTranslationMio.bConstrainWithSpline = false;
	default FauxTranslationMio.ConstrainedVerticalVelocity = 500.0;
	default FauxTranslationMio.ConstrainedHorizontalVelocity = 1200.0;
	
	UPROPERTY(DefaultComponent, Attach = FauxTranslationMio)
	UFauxPhysicsSplineTranslateComponent FauxTranslationZoe;
	default FauxTranslationZoe.Shape = EFauxPhysicsSplineTranslateShape::Cylinder;
	default FauxTranslationZoe.bConstrainWithSpline = false;
	default FauxTranslationZoe.ConstrainedVerticalVelocity = 200.0;
	default FauxTranslationZoe.ConstrainedHorizontalVelocity = 600.0;

	UPROPERTY(DefaultComponent, Attach = FauxTranslationZoe)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslationZoe)
	UFauxPhysicsFreeRotateComponent FauxPlayerImpulseRotateComp;
	default FauxPlayerImpulseRotateComp.ConstrainedAngularVelocityDegrees = 360.0;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	UStaticMeshComponent MeshComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	USphereComponent PlayerOverlapper;
	default PlayerOverlapper.SphereRadius = 90.0;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	USceneComponent BounceOverlapperRoot;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	USceneComponent PlayerAttachComp1;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	USceneComponent PlayerAttachComp2;

	UPROPERTY(DefaultComponent, Attach = FauxPlayerImpulseRotateComp)
	UDynamicWaterEffectDecalComponent WaterEffect;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	bool bCanBecomeOccupied = true;

	UPROPERTY(EditAnywhere)
	UAnimSequence SitInRingAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence EnterAnimTop;

	UPROPERTY(EditAnywhere)
	UAnimSequence EnterAnimBottom;

	UPROPERTY(EditInstanceOnly)
	ASplineActor PoolCurrentSpline;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FordeFeedback;

	float WaveTimer = 0.0;

	TArray<ASkylineSwimmingRingForce> Forces;

	const float MeshRadius = 215.0;
	float RingRadius = 0.0;

	bool bOccupied = false;
	float TimeSinceOccupied = 100.0;
	float LastBumpFrame = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RingRadius = MeshRadius * MeshComponent.GetWorldScale().Y;
		PlayerOverlapper.OnComponentBeginOverlap.AddUFunction(this, n"PlayerOverlapHole");
		
		TArray<UCapsuleComponent> CapsuleColliders;
		BounceOverlapperRoot.GetChildrenComponentsByClass(UCapsuleComponent, true, CapsuleColliders);
		for (int iCapsule = 0; iCapsule < CapsuleColliders.Num(); ++iCapsule)
		{
			CapsuleColliders[iCapsule].OnComponentBeginOverlap.AddUFunction(this, n"PlayerBounce");
		}

		TListedActors<ASkylineSwimmingRingForce> RingForces;
		Forces = RingForces.GetArray();

		FauxTranslationMio.OnConstraintHit.AddUFunction(this, n"HitWall");
		FauxTranslationZoe.OnConstraintHit.AddUFunction(this, n"HitWall");
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
		USkylineSwimmingRingEventHandler::Trigger_OnBumpIntoWall(this, Data);
	}

	UFUNCTION()
	private void PlayerBounce(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (TimeSinceOccupied < 1.0)
			return;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (!Player.HasControl())
			return;

		FVector BounceVector = (OverlappedComponent.WorldLocation - OtherComp.WorldLocation).GetSafeNormal() * OtherActor.ActorVelocity.Size();
		if (Player != nullptr)
		{
			UPlayerMovementComponent PlayerMoveComp = UPlayerMovementComponent::Get(Player);
			BounceVector = PlayerMoveComp.Velocity * 3.0;
		}

		const FVector Force = BounceVector * 0.5;

		if (Network::IsGameNetworked())
			NetBounced(Player, Force);
		else
			Bounced(Player, Force);

		NetImpulse(OtherActor.ActorLocation, Force, true);
		NetImpulse(OtherActor.ActorLocation, Force, false);
	
		if (!bOccupied)
			FauxPlayerImpulseRotateComp.ApplyImpulse(OtherActor.ActorLocation, BounceVector * 0.7);
	}

	UFUNCTION(NetFunction)
	private void NetImpulse(FVector Location, FVector Force, bool bIsMio)
	{
		if (bIsMio)
			FauxTranslationMio.ApplyImpulse(Location, Force);
		else
			FauxTranslationZoe.ApplyImpulse(Location, Force);
	}

	UFUNCTION(NetFunction)
	private void NetBounced(AHazePlayerCharacter PushingPlayer, FVector Force)
	{
		Bounced(PushingPlayer, Force);
	}

	private void Bounced(AHazePlayerCharacter PushingPlayer, FVector Force)
	{
		FSkylineSwimmingBumpRingEventData Data;
		Data.Player = PushingPlayer;
		Data.Force = Force;
		USkylineSwimmingRingEventHandler::Trigger_OnPlayerBumpIntoSide(this, Data);
	}

	UFUNCTION()
	private void PlayerOverlapHole(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
		{
			// UPlayerMovementComponent MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
			// if (!MoveComp.IsInAir()) // only allow sit from jumping into it
			// 	return;

			if (!bCanBecomeOccupied)
				return;

			USkylineSwimmingRingPlayerComponent RingOccupationComp = USkylineSwimmingRingPlayerComponent::GetOrCreate(Player);
			if (RingOccupationComp.OccupiedRing == nullptr && !bOccupied)
			{
				RingOccupationComp.OccupiedRing = this;
				bOccupied = true;
				CrumbSetSide(Player.OtherPlayer);
				Player.PlayForceFeedback(FordeFeedback, false, false, this, 2.0);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetSide(AHazePlayerCharacter Player)
	{
		SetActorControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeSinceOccupied += DeltaSeconds;

		if (PoolCurrentSpline != nullptr)
		{
			WaveTimer = Math::Wrap(WaveTimer + DeltaSeconds, 0.0, 1.0);
			UpdateTranslationFaux(FauxTranslationMio, DeltaSeconds);
			UpdateTranslationFaux(FauxTranslationZoe, DeltaSeconds);

			UpdateFauxRotationBuoyancy();
			// Debug::DrawDebugString(LowestPoint, "" + FloatingForce);
			// Debug::DrawDebugArrow(LowestPoint, LowestPoint + SwimmingRingUp * FloatingForce, 5.0, ColorDebug::Magenta, 3.0, 0.0, true);
			// Debug::DrawDebugCoordinateSystem(MeshComponent.WorldLocation, MeshComponent.WorldRotation, 100.0, 1.0, 0.0, true);
		}
	}

	private void UpdateTranslationFaux(UFauxPhysicsSplineTranslateComponent &InFauxTranslation, float DeltaSeconds)
	{
		float Distance = PoolCurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(MeshComponent.WorldLocation);
		Distance = Math::Wrap(Distance - 300.0, 0.0, PoolCurrentSpline.Spline.SplineLength);
		FTransform Transform = PoolCurrentSpline.Spline.GetWorldTransformAtSplineDistance(Distance);

		FVector GoingAroundCurrent = - Transform.Rotation.ForwardVector * 50.0;
		FVector Outwards = Transform.Location - MeshComponent.WorldLocation;
		FVector SlightlyPushToOuterToNotGetStuckInCenter = Outwards.GetSafeNormal() * 50.0;
		SlightlyPushToOuterToNotGetStuckInCenter.Z = 0.0;

		const float HalfForceBecauseTwoComponents = 0.5;

		InFauxTranslation.ApplyForce(MeshComponent.WorldLocation, (SlightlyPushToOuterToNotGetStuckInCenter + GoingAroundCurrent) * HalfForceBecauseTwoComponents);
		FauxRotateComp.ApplyAngularForce(Math::DegreesToRadians(Outwards.Size() * 0.1 * HalfForceBecauseTwoComponents));

		if (InFauxTranslation.WorldLocation.Z < PoolCurrentSpline.ActorLocation.Z)
		{
			float Factor = Math::Abs(PoolCurrentSpline.ActorLocation.Z - InFauxTranslation.WorldLocation.Z);
			InFauxTranslation.ApplyForce(MeshComponent.WorldLocation, FVector::UpVector * Factor * 100.0 * HalfForceBecauseTwoComponents);
		}
		else if (InFauxTranslation.WorldLocation.Z > PoolCurrentSpline.ActorLocation.Z + 10.0)
		{
			// gravity
			InFauxTranslation.ApplyForce(MeshComponent.WorldLocation, -FVector::UpVector * 980.0 * 3.0 * HalfForceBecauseTwoComponents);
		}

		FVector WaveMovement = FVector(0.0, 0.0, Math::SinusoidalInOut(1.0, -1.0, WaveTimer) * 0.1);
		InFauxTranslation.ApplyMovement(MeshComponent.WorldLocation, WaveMovement * HalfForceBecauseTwoComponents);

		// avoid other rings!
		TListedActors<ASkylineSwimmingRing> AllRings;
		for (auto Ring : AllRings)
		{
			if (Ring == this)
				continue;

			FVector ToOther = Ring.FauxPlayerImpulseRotateComp.WorldLocation - FauxPlayerImpulseRotateComp.WorldLocation;
			ToOther.Z = 0.0;
			if (ToOther.Size() < RingRadius * 1.5)
			{
				FVector Impulse = -ToOther.GetSafeNormal() * 1000.0 * HalfForceBecauseTwoComponents;
				InFauxTranslation.ApplyImpulse(Ring.FauxPlayerImpulseRotateComp.WorldLocation, Impulse);

				if (!Math::IsNearlyEqual(LastBumpFrame, Time::GameTimeSeconds, 0.01))
				{
					LastBumpFrame = Time::GameTimeSeconds;
					FSkylineSwimmingBumpEnvRingEventData Data;
					Data.ImpulseStrength = Impulse.Size();
					Data.ApproxBumpPoint = FauxPlayerImpulseRotateComp.WorldLocation + ToOther * 0.5;
					USkylineSwimmingRingEventHandler::Trigger_OnBumpIntoOtherRing(this, Data);
				}
			}
			if (ToOther.Size() < RingRadius * 2.1)
				InFauxTranslation.ApplyForce(Ring.FauxPlayerImpulseRotateComp.WorldLocation, -ToOther.GetSafeNormal() * 100.0 * HalfForceBecauseTwoComponents);
		}

		// for (ASkylineSwimmingRingForce Force : Forces)
		// {
		// 	bool bOverlapping = Force.ForceArea.IsOverlappingComponent(PlayerOverlapper);
		// 	if (bOverlapping)
		// 	{
		// 		FauxTranslation.ApplyForce(Force.ActorLocation, Force.DownardsForce);
		// 		FauxPlayerImpulseRotateComp.ApplyForce(Force.ActorLocation, Force.DownardsForce);
		// 	}
		// }

	}

	private void UpdateFauxRotationBuoyancy()
	{
		FVector SwimmingRingUp = MeshComponent.WorldRotation.UpVector;
		float PrefferedSign = 1.0;
		if (SwimmingRingUp.Z < 0.0)
			PrefferedSign = -1.0;

		FRotator PrefferedRotation = FRotator::MakeFromZX(FVector::UpVector * PrefferedSign, SwimmingRingUp);
		// Rotation diff
		float AngularDistance = PrefferedRotation.Quaternion().AngularDistance(MeshComponent.WorldRotation.Quaternion());
		float CorrectAlignedAlpha = Math::Clamp(Math::Abs(SwimmingRingUp.DotProduct(FVector::UpVector)), 0.0, 1.0);
	
		const float FloatyForce = 1000.0;
		float FloatingForce = AngularDistance * Math::EaseIn(1.0, 0.0, CorrectAlignedAlpha, 4.0) * FloatyForce;
		
		FVector LowestDirection = MeshComponent.WorldRotation.RightVector;
		int Granularity = 8;
		float AngleStep = 360.0 / float(Granularity);
		for (int i = 1; i < Granularity; ++i)
		{
			FVector RotatedVector = FQuat(SwimmingRingUp, AngleStep * i).RotateVector(MeshComponent.WorldRotation.RightVector);
			if (RotatedVector.Z < LowestDirection.Z)
				LowestDirection = RotatedVector;
		}
		FVector LowestPoint = MeshComponent.WorldLocation + LowestDirection * RingRadius;
		FauxPlayerImpulseRotateComp.ApplyForce(LowestPoint, SwimmingRingUp * FloatingForce);
	}
};
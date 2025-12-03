UCLASS(Abstract)
class ATundra_River_InteractableConeBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxRotateComp;
	default FauxRotateComp.ConeAngle = 120.0;
	default FauxRotateComp.bConstrainTwist = true;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UFauxPhysicsWeightComponent FauxWeight;
	default FauxWeight.RelativeLocation = FVector(0.0, 0.0, -100.0);
	default FauxWeight.bApplyInertia = true;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	USphereComponent OverlapSphere;
	default OverlapSphere.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UFauxPhysicsConeRotateComponent ClapperFauxRotateComp;
	default ClapperFauxRotateComp.ConeAngle = 20.0;
	default ClapperFauxRotateComp.ConstrainBounce = 0.5;

	UPROPERTY(DefaultComponent, Attach = ClapperFauxRotateComp)
	UStaticMeshComponent ClapperMesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = ClapperFauxRotateComp)
	UFauxPhysicsWeightComponent FauxClapperWeight;
	default FauxClapperWeight.RelativeLocation = FVector(0.0, 0.0, -95.0);
	default FauxClapperWeight.bApplyInertia = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	float RopeImpulseMultiplier = 30000.0;

	UPROPERTY(EditAnywhere)
	float RopeImpulseDrag = 0.01;

	UPROPERTY(EditAnywhere)
	float RopeImpulseVerticalMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float WeightMassScale = 1.0;

	/* How many percent of the mass is on the clapper */
	UPROPERTY(EditAnywhere)
	float ClapperWeightMassScale = 0.4;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_InteractableBellRope OptionalBellRope;

	UPROPERTY(EditAnywhere)
	bool bAttachToEnd = false;

	int RopeParticleIndex1;
	int RopeParticleIndex2;
	float RopeAttachPositionAlpha;
	bool bHasAttached = false;

	TPerPlayer<bool> PlayerIsImpacting;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetFauxValues();
	}

	void SetFauxValues()
	{
		FauxWeight.MassScale = WeightMassScale;
		FauxClapperWeight.MassScale = ClapperWeightMassScale;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetFauxValues();
		HandleAttachToRope();
		ClapperFauxRotateComp.OnConstraintHit.AddUFunction(this, n"OnClapperHitSide");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleMoveWithRope();
		HandleRotateInProximityToPlayer();
	}

	UFUNCTION()
	private void OnClapperHitSide(float Strength)
	{
		UTundra_River_InteractableConeBellEffectHandler::Trigger_OnClapperHitSoundBow(this, FTundra_River_InteractableConeBellEffectParams(Strength));
	}

	void HandleRotateInProximityToPlayer()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			FVector SphereLocation = OverlapSphere.WorldLocation;
			FVector LineStart = Player.ActorLocation + FVector::UpVector * Player.CapsuleComponent.ScaledCapsuleRadius;
			FVector LineEnd = LineStart + FVector::UpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight_WithoutHemisphere;
			FVector Point = Math::ClosestPointOnLine(LineStart, LineEnd, SphereLocation);

			float CombinedRadius = OverlapSphere.ScaledSphereRadius + Player.CapsuleComponent.ScaledCapsuleRadius;
			float DistSphereToPlayerSphere = Point.Distance(SphereLocation);

			// Player is overlapping sphere!
			if(DistSphereToPlayerSphere < CombinedRadius)
			{
				DepenetrateFromPlayerCapsule(Player, Point);
				FVector PlayerSphereToPivot = FauxRotateComp.WorldLocation - Point;
				float Alpha = (CombinedRadius - DistSphereToPlayerSphere) / CombinedRadius;

				if(!PlayerIsImpacting[Player])
				{
					PlayerIsImpacting[Player] = true;
					UTundra_River_InteractableConeBellEffectHandler::Trigger_OnPlayerStartImpactingBell(this, FTundra_River_InteractableConeBellEffectParams(Alpha));
				}

				PlayerSphereToPivot.Z = PlayerSphereToPivot.Z * RopeImpulseVerticalMultiplier;
				FVector Dir = PlayerSphereToPivot.GetSafeNormal();
				OptionalBellRope.ApplyImpulseAtLocationWithDrag(Point, Dir * (Alpha * RopeImpulseMultiplier), RopeImpulseDrag);
			}
			else if(DistSphereToPlayerSphere > CombinedRadius + 10.0 && PlayerIsImpacting[Player])
			{
				PlayerIsImpacting[Player] = false;
				UTundra_River_InteractableConeBellEffectHandler::Trigger_OnPlayerStopImpactingBell(this);
			}
		}
	}

	void DepenetrateFromPlayerCapsule(AHazePlayerCharacter Player, FVector SpherePoint)
	{
		FVector Pivot = FauxRotateComp.WorldLocation;
		float CombinedRadius = OverlapSphere.ScaledSphereRadius + Player.CapsuleComponent.ScaledCapsuleRadius;
		float SphereToPivotDistance = Pivot.Distance(OverlapSphere.WorldLocation);
		FVector PivotToPlayerSphere = (SpherePoint - Pivot);
		float PivotToPlayerDist = PivotToPlayerSphere.Size();
		FVector PivotToPlayerSphereDir = PivotToPlayerSphere / PivotToPlayerDist;
		FVector PivotToSphereDir = (OverlapSphere.WorldLocation - Pivot).GetSafeNormal();

		// Figure out the B angle in a non-right angled triangle.
		// https://acegikmo.com/trianglesolver/
		// SphereToPivotDistance = a
		// CombinedRadius = b
		// PivotToPlayerDist = c
		// B = acos((c*c+a*a-b*b)/(2*c*a));
		float AngleRad = Math::Acos((Math::Square(PivotToPlayerDist) + Math::Square(SphereToPivotDistance) - Math::Square(CombinedRadius)) / (2.0 * PivotToPlayerDist * SphereToPivotDistance));
		float AngleFromSphereToPlayerSphereDeg = PivotToPlayerSphereDir.GetAngleDegreesTo(PivotToSphereDir);

		// Subtract the angle between pivot -> player sphere and pivot -> overlap sphere to get the delta angle to rotate sphere to depenetrate!
		float DeltaAngleRad = AngleRad - Math::DegreesToRadians(AngleFromSphereToPlayerSphereDeg);

		FVector Axis = FVector::UpVector.CrossProduct(PivotToPlayerSphere).GetSafeNormal();

		FVector BottomSphereLocation = OverlapSphere.WorldLocation - OverlapSphere.UpVector * OverlapSphere.ScaledSphereRadius;
		if((BottomSphereLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).DotProduct((Pivot - Player.ActorLocation).VectorPlaneProject(FVector::UpVector)) < 0.0)
			Axis = -Axis;

		FQuat DeltaRotation = FQuat(Axis, DeltaAngleRad);
		FauxRotateComp.ApplyDeltaRotation(DeltaRotation);
		FauxRotateComp.AngularVelocity = FVector::ZeroVector;
	}

	void HandleAttachToRope()
	{
		if(OptionalBellRope == nullptr)
			return;

		if(bAttachToEnd)
		{
			ActorRotation = OptionalBellRope.ActorRotation;
			RopeParticleIndex1 = OptionalBellRope.CableComp.Particles.Num() - 2;
			RopeParticleIndex2 = RopeParticleIndex1 + 1;
			RopeAttachPositionAlpha = 1.0;
		}
		else
		{
			OptionalBellRope.GetClosestParticlesToWorldLocation(ActorLocation, RopeParticleIndex1, RopeParticleIndex2, RopeAttachPositionAlpha);
			FCableParticle Particle1 = OptionalBellRope.CableComp.Particles[RopeParticleIndex1];
			FCableParticle Particle2 = OptionalBellRope.CableComp.Particles[RopeParticleIndex2];
			
			ActorRotation = FRotator::MakeFromXZ(Particle2.Position - Particle1.Position, FVector::UpVector);
		}
	}

	void HandleMoveWithRope()
	{
		FCableParticle Particle1 = OptionalBellRope.CableComp.Particles[RopeParticleIndex1];
		FCableParticle Particle2 = OptionalBellRope.CableComp.Particles[RopeParticleIndex2];
		ActorLocation = Math::Lerp(Particle1.Position, Particle2.Position, RopeAttachPositionAlpha);

		if(!bHasAttached)
		{
			FauxWeight.ResetInternalState();
			FauxClapperWeight.ResetInternalState();
			bHasAttached = true;
		}
	}
}
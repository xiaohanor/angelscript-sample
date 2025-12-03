event void FSandHandProjectileCollisionEvent(FSandHandHitData HitData);

struct FSandHandBroadcastData
{
	FSandHandBroadcastData(FSandHandHitData InHitData, TArray<USandHandResponseComponent> InResponseComponents)
	{
		HitData = InHitData;
		ResponseComponents = InResponseComponents;
	}
	
	UPROPERTY()
	FSandHandHitData HitData;
	
	UPROPERTY()
	TArray<USandHandResponseComponent> ResponseComponents;
}

UCLASS(Abstract)
class ASandHandProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UForceFeedbackComponent ImpactForceFeedbackComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogComp;
#endif

	UPROPERTY(Meta = (BPCannotCallEvent))
	FSandHandProjectileCollisionEvent OnCollisionEvent;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent Trail;

	bool bIsAimingAtTarget;

	private AHazePlayerCharacter PlayerCaster = nullptr;

	private USandHandAutoAimTargetComponent HomingTarget;
	private FVector LastHomingTargetLocation;
	private FHazeAcceleratedVector AccHomingOffset;

	bool bActive = false;

	UProjectileProximityManagerComponent ProximityManager;

	bool bShot = false;
	bool bMissed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		check(bShot);

		// Move projectile. Maybe add movement component?
		FVector Velocity = GetActorVelocity() - ActorUpVector * SandHand::Gravity * DeltaTime;

		if(HomingTarget != nullptr && !bMissed)
		{
			const FQuat VelocityRotation = Velocity.ToOrientationQuat();
			const float Speed = Velocity.Size();
			const FVector VelocityDirection = Velocity / Speed;

			FVector TargetLocation = HomingTarget.WorldLocation;
			const FVector TargetDirection = (TargetLocation - ActorLocation).GetSafeNormal();
			const bool bTargetIsInFront = VelocityDirection.DotProduct(TargetDirection) > 0;

			if(bTargetIsInFront)
			{
				if(SandHand::HomingPredictionMultiplier > 0)
				{
					const FVector HomingTargetLocation = HomingTarget.WorldLocation;
					const FVector HomingTargetVelocity = (HomingTargetLocation - LastHomingTargetLocation) / DeltaTime;

					const float DistanceToTarget = HomingTargetLocation.Distance(ActorLocation);
					const float TimeToImpact = DistanceToTarget / Velocity.Size();

					FVector WorldHomingOffset = HomingTargetVelocity * TimeToImpact;
					WorldHomingOffset = WorldHomingOffset.GetClampedToMaxSize(SandHand::HomingMaxPredictionDistance);

					if(SandHand::bHomeInRelativeSpace)
					{
						FVector RelativeHomingOffset = HomingTarget.WorldTransform.InverseTransformVectorNoScale(WorldHomingOffset);
						RelativeHomingOffset *= SandHand::HomingPredictionMultiplier;

						if(AccHomingOffset.Value.IsZero())
							AccHomingOffset.SnapTo(RelativeHomingOffset);
						else
							AccHomingOffset.AccelerateTo(RelativeHomingOffset, SandHand::HomingPredictionSmoothingDuration, DeltaTime);

						WorldHomingOffset = HomingTarget.WorldTransform.TransformVector(AccHomingOffset.Value);
					}

					TargetLocation = HomingTargetLocation + WorldHomingOffset;
				}

				//Debug::DrawDebugPoint(TargetLocation, 10, FLinearColor::Green);

				const FQuat TargetRotation = (TargetLocation - ActorLocation).ToOrientationQuat();

				const float DistanceToTarget = ActorLocation.Distance(TargetLocation);
				const float DistanceAlpha = Math::NormalizeToRange(DistanceToTarget, SandHand::HomingNearDistance, SandHand::HomingFarDistance);
				const float HomingSpeed = Math::Lerp(DistanceAlpha, SandHand::HomingSpeedNear, SandHand::HomingSpeedFar);

				const FQuat NewDirection = Math::QInterpConstantTo(VelocityRotation, TargetRotation, DeltaTime, HomingSpeed);
				Velocity = NewDirection.ForwardVector * Velocity.Size();

				LastHomingTargetLocation = HomingTarget.WorldLocation;
			}
			else
			{
				bMissed = true;
			}
		}

		SetActorVelocity(Velocity);

		const FVector OldLocation = ActorLocation;
		const FVector NewLocation = ActorLocation + Velocity * DeltaTime;
		SetActorLocation(NewLocation);

		// Set rotation
		SetActorRotation(Velocity.Rotation());

		if(HasControl())
		{
			// Trace for overlaps
			FHazeTraceSettings Trace;
			//ETraceTypeQuery TraceTypeQuery = PlayerCaster.Player == EHazePlayer::Mio ? ETraceTypeQuery::WeaponTraceMio : ETraceTypeQuery::WeaponTraceZoe;
			Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
			Trace.UseSphereShape(Mesh.BoundsExtent.Y * 0.5);
			Trace.IgnoreActor(this);
			Trace.IgnoreActor(PlayerCaster);

			const FVector TraceStart = OldLocation + GetTraceMeshOffset();
			const FVector TraceEnd = NewLocation + GetTraceMeshOffset();
			FHitResult HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

	#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(PlayerCaster, Name.ToString());
			TemporalLog.HitResults("SandHandProjectile Trace", HitResult, Trace.Shape, Trace.ShapeWorldOffset);
	#endif

			// FB TODO: Maybe make hitting something a capability to sync with OnActivated instead of CrumbFunction?

			if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
			{
				FSandHandHitData HitData;
				HitData.SandHandProjectile = this;
				HitData.Caster = PlayerCaster;

				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if(HitPlayer != nullptr)
				{
					HitData.HitComponent = HitPlayer.CapsuleComponent;
					HitData.RelativeImpactLocation = HitPlayer.CapsuleComponent.WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
					HitData.RelativeImpactNormal = HitPlayer.CapsuleComponent.WorldTransform.InverseTransformVectorNoScale(HitResult.ImpactNormal);
					CrumbOnSandHandHitPlayer(HitData);
					return;
				}

				bool bValidHitData = false;

				// Sniff for earth hand response components and fire
				TArray<USandHandResponseComponent> SandHandResponseComponents;
				HitResult.Actor.GetComponentsByClass(SandHandResponseComponents);
				TArray<USandHandResponseComponent> HitResponseComponents;

				for (auto SandHandResponseComponent : SandHandResponseComponents)
				{
					// We ignore scale on SandHandResponseComponents
					FBox ResponseComponentCollisionBox(-SandHandResponseComponent.CollisionSettings.BoxExtents, SandHandResponseComponent.CollisionSettings.BoxExtents);
					FTransform AdjustedResponseComponentTransform = SandHandResponseComponent.WorldTransform;
					AdjustedResponseComponentTransform.SetScale3D(FVector::OneVector);
					ResponseComponentCollisionBox = ResponseComponentCollisionBox.TransformBy(AdjustedResponseComponentTransform);

					// Adjust mesh collision box to fix scale and animation offset
					FBox SandHandCollisionBox(-Mesh.BoundsExtent, Mesh.BoundsExtent);
					FTransform AdjustedMeshTransform = Mesh.WorldTransform;
					AdjustedMeshTransform.SetLocation(TraceEnd);
					AdjustedMeshTransform.SetScale3D(ActorTransform.Scale3D * FVector(1.5, 0.75, 0.75));
					SandHandCollisionBox = SandHandCollisionBox.TransformBy(AdjustedMeshTransform);

					if (SandHandCollisionBox.Intersect(ResponseComponentCollisionBox))
					{
						if(!bValidHitData)
						{
							HitData.HitComponent = HitResult.Component;
							HitData.RelativeImpactLocation = HitResult.Component.WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
							HitData.RelativeImpactNormal = HitResult.Component.WorldTransform.InverseTransformVectorNoScale(HitResult.ImpactNormal);
						}

						HitResponseComponents.Add(SandHandResponseComponent);

						bValidHitData = true;
					}
				}

				// Just use first overlap result in case there weren't any response components
				if (!bValidHitData)
				{
					HitData.HitComponent = HitResult.Component;
					HitData.RelativeImpactLocation = HitResult.Component.WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
					HitData.RelativeImpactNormal = HitResult.Component.WorldTransform.InverseTransformVectorNoScale(HitResult.ImpactNormal);
				}

				// Store all hit response components and relevant hit data
				const FSandHandBroadcastData BroadcastHit = FSandHandBroadcastData(HitData, HitResponseComponents);

				// Dispatch all broadcasts on both clients
				CrumbOnSandHandHit(BroadcastHit);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSandHandHitPlayer(FSandHandHitData HitData)
	{
		OnCollisionEvent.Broadcast(HitData);

		auto Player = Cast<AHazePlayerCharacter>(HitData.HitComponent.Owner);
		if(Player.HasControl())
			Player.KillPlayer();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSandHandHit(FSandHandBroadcastData BroadcastHit)
	{
		// Fire collision event
		OnCollisionEvent.Broadcast(BroadcastHit.HitData);

		for(auto ResponseComp : BroadcastHit.ResponseComponents)
		{
			if(ResponseComp == nullptr)
				continue;
			
			ResponseComp.OnSandHandHitEvent.Broadcast(BroadcastHit.HitData);
		}
	}

	void Shoot(FVector InitialVelocity, AHazePlayerCharacter Caster, USandHandAutoAimTargetComponent Target, UProjectileProximityManagerComponent ProjectileProximityManager = nullptr)
	{
		Activate();

		bShot = true;
		SetActorTickEnabled(true);

		// Set initial velocity
		SetActorVelocity(InitialVelocity);
		SetActorRotation(InitialVelocity.Rotation());
		
		PlayerCaster = Caster;
		HomingTarget = Target;

		ProximityManager = ProjectileProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);

		if(HomingTarget != nullptr)
		{
			LastHomingTargetLocation = HomingTarget.WorldLocation;
			AccHomingOffset.SnapTo(FVector::ZeroVector);
		}
	}

	void Activate()
	{
		Mesh.SetHiddenInGame(false);
		SetActorEnableCollision(true);

		bActive = true;
		bMissed = false;
	}

	void Deactivate()
	{
		SetActorTickEnabled(false);
		Mesh.SetHiddenInGame(true);
		SetActorEnableCollision(false);

		// Detach from the parent if deactivated mid charge to prevent weird attachment when reused
		if(GetAttachParentActor() != nullptr)
			DetachFromActor();

		if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);

		// We can clear since we always bind after spawning
		OnCollisionEvent.Clear();
		bShot = false;
	}

	private FVector GetTraceMeshOffset()
	{
		return ActorForwardVector * 40;
	}
}
UCLASS(Abstract)
class AIslandRedBlueStickyGrenade : AHazeActor
{
	access GrenadeCapability = private, UIslandRedBlueStickyGrenadeThrowCapability, UIslandRedBlueStickyGrenadeDetonateCapability;
	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedActorPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UIslandPortalTravelerComponent PortalTraveler;
	default PortalTraveler.bIsProjectile = true;
	default PortalTraveler.bKillWhenEnteringWrongPortal = true;

	UPROPERTY(EditDefaultsOnly)
	float SpinningTargetRotationRate = 100.0;

	UPROPERTY(EditDefaultsOnly)
	float SpinningRotationRateLerpDuration = 0.5;

	AHazePlayerCharacter PlayerOwner;
	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;
	UPlayerAimingComponent AimComp;

	private UIslandRedBlueStickyGrenadeSettings Settings;
	UIslandRedBlueStickyGrenadeResponseContainerComponent GrenadeResponseContainer;

	private bool bGrenadeIsThrown = false;
	private bool bGrenadeIsAttached = false;
	private float GrenadeGravity;
	private FVector CurrentDestination;
	private FVector CurrentVelocity;
	private FVector PreviousLocation;
	private FTransform OriginalTransform;
	private FVector DestinationRelativeToTarget;
	private FVector DestinationToOriginalLocationDirection;
	private float TotalTimeToHitTarget;
	private bool bApplyGravity = false;
	private USceneComponent GrenadeTarget;
	private TArray<UIslandRedBlueStickyGrenadeResponseComponent> AlreadyTriggeredResponseComponents;
	private TArray<AActor> IgnoreActors;
	private FHazeAcceleratedFloat CurrentRotationRate;
	private UIslandRedBlueStickyGrenadeKillTriggerContainerComponent KillTriggerContainer;
	private bool bHasTeleportedThroughAPortal = false;
	private TOptional<uint> FrameOfLastBounceOff;

	access:ReadOnly float TimeOfThrow = -100.0;
	access:ReadOnly float TimeOfAttach = -100.0;
	
	access:GrenadeCapability bool bExternallyRequestedShouldDetonate = false;

	const FString GeneralCategory = "General";
	const FString PortalCategory = "Portal";
	const FString TracesCategory = "Traces";
	const FString IgnoreActorTraceCategory = "Ignore Actor Trace";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(PlayerOwner);
		Settings = UIslandRedBlueStickyGrenadeSettings::GetSettings(PlayerOwner);
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(PlayerOwner);
		AimComp = UPlayerAimingComponent::Get(PlayerOwner);
		GrenadeResponseContainer = UIslandRedBlueStickyGrenadeResponseContainerComponent::GetOrCreate(Game::Mio);
		KillTriggerContainer = UIslandRedBlueStickyGrenadeKillTriggerContainerComponent::GetOrCreate(Game::Mio);
		
		LocalResetGrenade();

		PortalTraveler.TravelerType = IslandRedBlueWeapon::IsPlayerRed(PlayerOwner) ? EIslandTravelerType::Red : EIslandTravelerType::Blue;

#if TEST
		UTemporalLogTransformLoggerComponent::Create(this);
		UIslandRedBlueStickyGrenadeDisableLoggerComponent::Create(this);
#endif
	}

	bool IsGrenadeThrown() const
	{
		return bGrenadeIsThrown;
	}

	bool IsGrenadeAttached() const
	{
		return bGrenadeIsAttached;
	}

	void ThrowGrenade(FTransform OriginTransform, FVector MuzzleVelocity, FVector Destination, FVector TargetVelocity, FVector ShoulderLocation, USceneComponent GrenadeTargetComponent, FHitResult TargetHit)
	{
		CurrentRotationRate.SnapTo(0.0);
		bApplyGravity = false;
		bHasTeleportedThroughAPortal = false;
		bGrenadeIsThrown = true;
		ActorTransform = OriginTransform;
		OriginalTransform = OriginTransform;
		PreviousLocation = ActorLocation;
		GrenadeTarget = GrenadeTargetComponent;
		TimeOfThrow = Time::GetGameTimeSeconds();

		if(GrenadeTargetComponent != nullptr)
			DestinationRelativeToTarget = GrenadeTargetComponent.WorldTransform.InverseTransformPosition(Destination);

		GetGrenadeParams(OriginTransform, MuzzleVelocity, Destination, TargetVelocity, CurrentDestination, CurrentVelocity, TotalTimeToHitTarget);
		DestinationToOriginalLocationDirection = (OriginalTransform.Location - CurrentDestination).GetSafeNormal();

		float AdditionalGravityMultiplier = FVector::UpVector.DotProduct((CurrentDestination - OriginalTransform.Location).GetSafeNormal());
		GrenadeGravity = Settings.GrenadeBaseGravity + AdditionalGravityMultiplier * Settings.GrenadeAdditionalVerticalityGravity;

		RemoveActorDisable(this);

		FHitResult Hit;
		AIslandPortal Portal;
		FVector Delta = ActorLocation - ShoulderLocation;
		if(TraceForHits(ShoulderLocation, ActorLocation, Hit, Portal, Delta, "Shoulder Trace"))
		{
			FVector NewLocation = ShoulderLocation + Delta;
			ActorLocation += NewLocation - ActorLocation;
			if(Portal != nullptr)
			{
				CrumbPortalTeleportGrenade(Portal, Hit.ImpactPoint, Hit.TraceEnd, Delta);
				TraceForHits(ActorLocation, ActorLocation + Delta, Hit, Portal, Delta, "Shoulder Trace Portal");
				ActorLocation += Delta;
			}

			return;
		}

		SetupIgnoreActors(TargetHit, GrenadeTargetComponent);

		if(Settings.bDebugGrenadeMovementArc)
			Debug::DrawDebugSphere(CurrentDestination, 100.0, 12, FLinearColor::Red, 10.0, TotalTimeToHitTarget + 3.0);
	}

	void SetupIgnoreActors(FHitResult TargetHit, USceneComponent GrenadeTargetComponent)
	{
		// If we are in sidescroller or top down the origin of the trace will be pretty much lined up with the muzzle so we don't need to ignore any actors!
		if(AimComp.GetCurrentAimingConstraintType() != EAimingConstraintType2D::None)
			return;

		// Ignore any actors that aren't the pre traced actor
		// In the below situation, if the player stands on the edge and aims with the camera on point A the gun will be at a lower angle than
		// the camera and hit the ledge (B) instead. So we trace again from the grenade location to the target location to see if we hit any actors on the way and if so, ignore these
		// │ A /___________  \┌─┐
		// │   \	       	 /└─┘
		// └──────┐ B 	 O
		//   	  │	  🔫/|\
		//   	  │    	 │
		// 		  │	  	/ \
		// 		  └─────────
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseComponentShape(Collision);
		Trace.IgnorePlayers();
		Trace.IgnoreActors(GrenadeResponseContainer.IgnoreMovementCollisionActors);
		Trace.IgnoreComponents(GrenadeResponseContainer.IgnoreMovementCollisionComponents);

		FHitResultArray GrenadeHits = Trace.QueryTraceMulti(ActorLocation, CurrentDestination);

#if TEST
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.HitResults(f"{IgnoreActorTraceCategory};Ignore Actor Hit Results", GrenadeHits, ActorLocation, CurrentDestination, Trace.Shape, Trace.ShapeWorldOffset);
#endif

		for(FHitResult Current : GrenadeHits.BlockHits)
		{
			if(Current.Actor.IsA(AIslandPortal))
				break;

			if(Current.Actor == TargetHit.Actor)
				continue;

			if(GrenadeTargetComponent != nullptr && Current.Actor == GrenadeTargetComponent.Owner)
				continue;

			IgnoreActors.Add(Current.Actor);
		}
	}

	void GetGrenadeParams(FTransform OriginTransform, FVector MuzzleVelocity, FVector Destination, FVector TargetVelocity, FVector&out OutDestination, FVector&out OutVelocity, float&out OutTime)
	{
		OutDestination = Destination;
		float GrenadeMoveSpeed = Settings.GrenadeMoveSpeed;
		
		// If the target's velocity is zero we simply fire the grenade at the target's current location.
		if(TargetVelocity.IsNearlyZero())
		{
			OutVelocity = (Destination - OriginTransform.Location).GetSafeNormal() * GrenadeMoveSpeed + MuzzleVelocity;
			TryConstrainVelocityToSpline(OutVelocity);
			return;
		}

		OutTime = Trajectory::GetTimeUntilHitMovingTarget(OriginTransform.Location, MuzzleVelocity, Destination, TargetVelocity, GrenadeMoveSpeed);
		if(OutTime <= 0.0)
		{
			PrintWarning("Grenade wont hit target, probably because it is moving too fast compared to the grenade.");
			OutVelocity = (Destination - OriginTransform.Location).GetSafeNormal() * GrenadeMoveSpeed + MuzzleVelocity;
			TryConstrainVelocityToSpline(OutVelocity);
			return;
		}

		OutDestination += TargetVelocity * OutTime;
		OutVelocity = (OutDestination - OriginTransform.Location).GetSafeNormal() * GrenadeMoveSpeed + MuzzleVelocity;
		TryConstrainVelocityToSpline(OutVelocity);
	}

	USceneComponent GetGrenadeTarget()
	{
		return GrenadeTarget;
	}

	bool TryConstrainVelocityToSpline(FVector& Velocity)
	{
		if(AimComp.GetCurrentAimingConstraintType() != EAimingConstraintType2D::Spline)
			return false;

		float OriginalSize = Velocity.Size();
		UHazeSplineComponent Spline = AimComp.Get2DConstraintSpline();
		FTransform SplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
		FVector LocalVelocity = SplineTransform.InverseTransformVectorNoScale(Velocity);
		LocalVelocity.Y = 0.0;
		Velocity = SplineTransform.TransformVectorNoScale(LocalVelocity).GetSafeNormal() * OriginalSize;
		return true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPortalTeleportGrenade(AIslandPortal Portal, FVector ImpactPoint, FVector TraceEnd, FVector& Delta)
	{
#if TEST
		TEMPORAL_LOG(this)
			.DirectionalArrow(f"{PortalCategory};Pre Portal Teleport Velocity", ActorLocation, CurrentVelocity)
			.Value(f"{PortalCategory};Portal", Portal)
		;
#endif
		FIslandRedBlueStickyGrenadeEnterPortalEffectParams Params;
		Params.OriginPortal = Portal;
		Params.DestinationPortal = Portal.DestinationPortal;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnPrePortalTeleport(this, Params);

		FVector Start;
		FVector End;
		PortalTraveler.GetProjectileLocationOnOtherSide(Portal, ImpactPoint, TraceEnd, Start, End);
		TeleportActor(Start, ActorRotation, this, false);
		Delta = (End - Start);
		CurrentVelocity = IslandPortal::TransformVectorToPortalSpace(Portal, Portal.DestinationPortal, CurrentVelocity);
		TryConstrainVelocityToSpline(CurrentVelocity);
#if TEST
		TEMPORAL_LOG(this)
			.DirectionalArrow(f"{PortalCategory};Post Portal Teleport Velocity", ActorLocation, CurrentVelocity)
		;
#endif

		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnPostPortalTeleport(this, Params);

		IgnoreActors.Reset();
		IgnoreActors.AddUnique(Portal.DestinationPortal);
		for(AActor IgnoredActor : Portal.DestinationPortal.ActorsToIgnoreWhenEnteringPortal)
		{
			IgnoreActors.AddUnique(IgnoredActor);
		}

		FIslandPortalGrenadeEnterEffectParams Params2;
		Params2.OriginPortal = Portal;
		Params2.DestinationPortal = Portal.DestinationPortal;
		Params2.Grenade = this;
		UIslandPortalEffectHandler::Trigger_OnGrenadeEnter(Portal, Params2);
		bHasTeleportedThroughAPortal = true;
	}

	void ResetGrenade(bool bShouldPlayFailEffect = false)
	{
		if(!HasControl())
			return;

		CrumbResetGrenade(bShouldPlayFailEffect);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetGrenade(bool bShouldPlayFailEffect = false)
	{
		if(bShouldPlayFailEffect)
		{
			PlayerOwner.PlayForceFeedback(GrenadeUserComp.FailForceFeedback, false, true, n"Fail");

			FIslandRedBlueStickyGrenadeOnDespawnOnForceFieldParams Params;
			Params.GrenadeOwner = PlayerOwner;
			Params.GrenadeLocation = ActorLocation;
			Params.ImpactPoint = ActorLocation;
			Params.ImpactNormal = ActorForwardVector;
			UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDespawnOnForceField(this, Params);
			UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDespawnOnForceField(PlayerOwner, Params);
		}

		LocalResetGrenade();
	}

	private void LocalResetGrenade()
	{
		bGrenadeIsThrown = false;

		FrameOfLastBounceOff.Reset();
		DetachGrenade();
		AlreadyTriggeredResponseComponents.Empty();
		IgnoreActors.Empty();
		AddActorDisable(this);

		FIslandRedBlueStickyGrenadeBasicEffectParams Params;
		Params.GrenadeOwner = PlayerOwner;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnResetGrenade(this, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnResetGrenade(PlayerOwner, Params);
	}

	access:GrenadeCapability
	void DetachGrenade()
	{
		if(!bGrenadeIsAttached)
			return;

		DetachFromActor();
		bGrenadeIsAttached = false;
		SyncedActorPosition.ClearRelativePositionSync(this);
		TimeOfAttach = -100.0;
	}

	void DetonateGrenade()
	{
		if(!HasControl())
		{
			CrumbDetonateGrenade();
			return;
		}

		bExternallyRequestedShouldDetonate = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDetonateGrenade()
	{
		bExternallyRequestedShouldDetonate = true;
	}

	access:GrenadeCapability
	void StartDetonate_Internal()
	{
		if(!Settings.bDebugGrenadeExplosionRadius)
		{
			FIslandRedBlueStickyGrenadeOnDetonateParams Params;
			Params.GrenadeOwner = PlayerOwner;
			Params.ExplosionOrigin = ActorLocation;
			Params.ExplosionRadius = Settings.GrenadeExplosionRadius;
			Params.AttachParentActor = AttachParentActor;
			UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDetonate(this, Params);
			UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDetonate(PlayerOwner, Params);
		}

		BP_OnGrenadeAnimation(false);
		AddActorDisable(this);
		TEMPORAL_LOG(this).Value("StartDetonate", true);
	}

	access:GrenadeCapability
	TArray<UIslandRedBlueStickyGrenadeResponseComponent> GetAffectedResponseComponents() const
	{
		TArray<UIslandRedBlueStickyGrenadeResponseComponent> OutAffectedComps;
		for(UIslandRedBlueStickyGrenadeResponseComponent ResponseComp : GrenadeResponseContainer.ResponseComponents)
		{
			if(!ActorLocation.IsWithinDist(ResponseComp.WorldLocation, Settings.GrenadeExplosionRadius + ResponseComp.Shape.EncapsulatingSphereRadius))
				continue;

			float Distance;
			if(ResponseComp.Shape.IsZeroSize())
			{
				Distance = ResponseComp.WorldLocation.Distance(ActorLocation);
			}
			else
			{
				Distance = ResponseComp.Shape.GetWorldDistanceToShape(ResponseComp.WorldTransform, ActorLocation);
			}

			if(!ResponseComp.CanTriggerFor(PlayerOwner, this, Distance, Settings.GrenadeExplosionRadius))
				continue;

			OutAffectedComps.Add(ResponseComp);
		}

		return OutAffectedComps;
	}

	access:GrenadeCapability
	void TriggerResponseComponents_Internal(TArray<UIslandRedBlueStickyGrenadeResponseComponent> AffectedResponseComps, FVector DetonateLocation, float CurrentExplosionRadius)
	{
		for(UIslandRedBlueStickyGrenadeResponseComponent ResponseComp : AffectedResponseComps)
		{
			if (!IsValid(ResponseComp))
				continue;

			float Distance;
			if(ResponseComp.Shape.IsZeroSize())
			{
				Distance = ResponseComp.WorldLocation.Distance(DetonateLocation);
			}
			else
			{
				Distance = ResponseComp.Shape.GetWorldDistanceToShape(ResponseComp.WorldTransform, DetonateLocation);
			}

			auto HazeResponseActor = Cast<AHazeActor>(ResponseComp.Owner);
			if(HazeResponseActor != nullptr)
			{
				FIslandRedBlueStickyGrenadeOnDetonateParams Params;
				Params.GrenadeOwner = PlayerOwner;
				Params.ExplosionOrigin = DetonateLocation;
				Params.ExplosionRadius = CurrentExplosionRadius;
				UIslandRedBlueStickyGrenadeResponseEffectHandler::Trigger_OnDetonate(HazeResponseActor, Params);
			}

			ResponseComp.TriggerDetonation(PlayerOwner, this, DetonateLocation, Distance, CurrentExplosionRadius, GrenadeUserComp.ExplosionIndex);
			TEMPORAL_LOG(this).Value("Trigger Detonation For Response", ResponseComp);

			if(!ResponseComp.bCanImpactMultipleTimesPerDetonation)
				AlreadyTriggeredResponseComponents.Add(ResponseComp);
		}

		TEMPORAL_LOG(this).Value("TriggerResponseComponents_Internal", true);
	}

	access:GrenadeCapability
	void EndDetonation_Internal()
	{
		GrenadeUserComp.ExplosionIndex++;
		ResetGrenade();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if !RELEASE
		devCheck(bGrenadeIsThrown, "Grenade is not thrown but somehow tick still run, scream at Oliver");
#endif

		if(bGrenadeIsAttached)
		{
			HandleSpinningRotation(DeltaTime);
		}

		if(!HasControl())
		{
			if (!bGrenadeIsAttached)
			{
				auto Position = SyncedActorPosition.GetPosition();
				ActorLocation = Position.WorldLocation;
				ActorRotation = Position.WorldRotation;
			}

			return;
		}

		if(bGrenadeIsAttached)
		{
			if(!PreviousLocation.Equals(ActorLocation))
			{
				FVector Delta = ActorLocation - PreviousLocation;
				TraceForHits(PreviousLocation, ActorLocation, Delta, "Attached Trace");
				ActorLocation = PreviousLocation + Delta;
			}
		}
		else
		{
			// When we have passed the destination we want to apply gravity
			if(!bHasTeleportedThroughAPortal && !bApplyGravity && DestinationToOriginalLocationDirection.DotProduct(ActorLocation - CurrentDestination) < 0.0)
				bApplyGravity = true;

			if(bApplyGravity)
				CurrentVelocity += FVector::DownVector * (GrenadeGravity * DeltaTime);

			if(!bApplyGravity && GrenadeTarget != nullptr && !GrenadeTarget.Owner.IsA(AIslandPortal))
			{
				FVector NewDestination = GrenadeTarget.WorldTransform.TransformPosition(DestinationRelativeToTarget);
				FVector NewVelocity;
				float NewTime;
				GetGrenadeParams(ActorTransform, FVector::ZeroVector, NewDestination, GrenadeTarget.Owner.ActorVelocity, CurrentDestination, NewVelocity, NewTime);

				DestinationToOriginalLocationDirection = (ActorLocation - CurrentDestination).GetSafeNormal();
				float AdditionalGravityMultiplier = FVector::UpVector.DotProduct((CurrentDestination - OriginalTransform.Location).GetSafeNormal());
				GrenadeGravity = Settings.GrenadeBaseGravity + AdditionalGravityMultiplier * Settings.GrenadeAdditionalVerticalityGravity;

				CurrentVelocity = NewVelocity;
			}

			FVector CurrentDelta = CurrentVelocity * DeltaTime;
			if(!TraceForHits(ActorLocation, ActorLocation + CurrentDelta, CurrentDelta, "Move Trace"))
			{
				ActorLocation += CurrentDelta;
				ActorRotation = FRotator::MakeFromX(CurrentVelocity);
			}

			if(Settings.bDebugGrenadeMovementArc)
				Debug::DrawDebugLine(PreviousLocation, ActorLocation, FLinearColor::Red, 10.0, TotalTimeToHitTarget + 3.0);

#if TEST
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value(f"{GeneralCategory};Apply Gravity", bApplyGravity);
			TemporalLog.Point(f"{GeneralCategory};Current Destination", CurrentDestination);
			TemporalLog.DirectionalArrow(f"{GeneralCategory};Current Velocity", ActorLocation, CurrentVelocity);
#endif
		}

		PreviousLocation = ActorLocation;
	}

	private void HandleSpinningRotation(float DeltaTime)
	{
		CurrentRotationRate.AccelerateTo(SpinningTargetRotationRate, SpinningRotationRateLerpDuration, DeltaTime);
		FRotator DeltaRotation = Math::RotatorFromAxisAndAngle(ActorForwardVector, CurrentRotationRate.Value * DeltaTime);
		ActorQuat = DeltaRotation.Quaternion() * ActorQuat;
	}

	void ExternalTriggerHitOppositeColorShield()
	{
		if(!HasControl())
			return;

		FHitResult Hit;
		Hit.ImpactPoint = ActorLocation;
		Hit.ImpactNormal = -ActorForwardVector;
		CrumbTriggerHitOppositeColorShield(Hit);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerHitOppositeColorShield(FHitResult RelevantHit)
	{
		FIslandRedBlueStickyGrenadeOnDespawnOnForceFieldParams Params;
		Params.GrenadeOwner = PlayerOwner;
		Params.GrenadeLocation = ActorLocation;
		Params.ImpactPoint = RelevantHit.ImpactPoint;
		Params.ImpactNormal = RelevantHit.ImpactNormal;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDespawnOnForceField(this, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnDespawnOnForceField(PlayerOwner, Params);
		ResetGrenade(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAttachGrenade(FHitResult Hit, FVector RelativeLocation, FRotator RelativeRotation)
	{
		AttachToComponent(Hit.Component, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		ActorRelativeLocation = RelativeLocation;
		ActorRelativeRotation = RelativeRotation;
		bGrenadeIsAttached = true;
		SyncedActorPosition.ApplyRelativePositionSync(this, Hit.Component);
		TimeOfAttach = Time::GetGameTimeSeconds();

		auto ResponseComp = UIslandRedBlueStickyGrenadeResponseComponent::Get(Hit.Actor);
		if(ResponseComp != nullptr)
		{
			FIslandRedBlueStickGrenadeOnAttachedData Data;
			Data.GrenadeOwner = PlayerOwner;
			Data.AttachedWorldLocation = ActorLocation;
			Data.AttachParent = Hit.Component;
			Data.AttachParentActor = Hit.Actor;
			ResponseComp.OnAttached.Broadcast(Data);

			auto HazeActor = Cast<AHazeActor>(Hit.Actor);
			if(HazeActor != nullptr)
				UIslandRedBlueStickyGrenadeResponseEffectHandler::Trigger_OnAttached(HazeActor, Data);
		}

		PlayerOwner.PlayForceFeedback(GrenadeUserComp.AttachForceFeedback, false, true, this);

		FIslandRedBlueStickyGrenadeOnAttachedParams Params;
		Params.GrenadeOwner = PlayerOwner;
		Params.GrenadeLocation = ActorLocation;
		Params.AttachParent = Hit.Component;
		Params.AttachParentActor = Hit.Actor;
		Params.PhysMat = Hit.PhysMaterial;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnAttached(this, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnAttached(PlayerOwner, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnAttachedAudio(Game::Mio, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnAttachedAudio(Game::Zoe, Params);

		BP_OnGrenadeAnimation(true);
	}

	private bool TraceForHits(FVector StartLocation, FVector EndLocation, FVector&out OutDelta, FString TraceTag)
	{
		FHitResult RelevantHit;
		AIslandPortal Portal;
		bool bResult = TraceForHits(StartLocation, EndLocation, RelevantHit, Portal, OutDelta, TraceTag);

		if(bResult && Portal != nullptr)
		{
			CrumbPortalTeleportGrenade(Portal, RelevantHit.ImpactPoint, RelevantHit.TraceEnd, OutDelta);
		}

		return bResult;
	}

	private bool TraceForHits(FVector StartLocation, FVector EndLocation, FHitResult&out RelevantHit, AIslandPortal&out OutPortal, FVector&out OutDelta, FString TraceTag)
	{
		if(KillTriggerContainer.CheckHitKillTrigger(this, StartLocation, EndLocation))
			return false;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseComponentShape(Collision);
		Trace.IgnorePlayers();
		Trace.IgnoreActors(GrenadeResponseContainer.IgnoreMovementCollisionActors);
		Trace.IgnoreComponents(GrenadeResponseContainer.IgnoreMovementCollisionComponents);
		Trace.IgnoreActors(IgnoreActors);

		if(bGrenadeIsAttached && RootComponent.AttachParent != nullptr)
			Trace.IgnoreActor(RootComponent.AttachParent.Owner);

		Trace.SetReturnPhysMaterial(true);
		FHitResultArray Hits = Trace.QueryTraceMulti(StartLocation, EndLocation);
		
		bool bHasValidHit = HitResultArrayHasValidHit(Hits, RelevantHit);
#if TEST
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value(f"{TracesCategory};{TraceTag} Has Valid Hit", bHasValidHit);
		TemporalLog.HitResults(f"{TracesCategory};{TraceTag} Hits", Hits, StartLocation, EndLocation, Trace.Shape, Trace.ShapeWorldOffset);
		TemporalLog.Value(f"{TracesCategory};{TraceTag} Ignore Actor Num", IgnoreActors.Num());
		for(int i = 0; i < IgnoreActors.Num(); i++)
		{
			TemporalLog.Value(f"{TracesCategory};{TraceTag} Ignore Actor [{i}]", IgnoreActors[i]);
		}
#endif

		if(bHasValidHit)
		{
			auto BounceOffComp = UIslandRedBlueStickyGrenadeBounceOffComponent::Get(RelevantHit.Actor);
			if(BounceOffComp != nullptr && RelevantHit.Normal.DotProduct(FVector::UpVector) < 0.99 && (!FrameOfLastBounceOff.IsSet() || Time::FrameNumber - FrameOfLastBounceOff.Value > 1))
			{
				IgnoreActors.Reset();
				bApplyGravity = true;
				FVector NewVelocity = Math::GetReflectionVector(CurrentVelocity, RelevantHit.Normal);
				CurrentVelocity = NewVelocity * BounceOffComp.BounceImpulseMultiplier;
				float SpeedAlongNormal = CurrentVelocity.DotProduct(RelevantHit.Normal);
				if(SpeedAlongNormal < BounceOffComp.BounceMinVelocityAlongNormal)
					CurrentVelocity += RelevantHit.Normal * (BounceOffComp.BounceMinVelocityAlongNormal - SpeedAlongNormal);

				TryConstrainVelocityToSpline(CurrentVelocity);

				OutDelta = OutDelta.GetSafeNormal() * (RelevantHit.Distance - 1.0);
				CrumbOnTriggerBounce(RelevantHit);
				FrameOfLastBounceOff.Set(Time::FrameNumber);
				return true;
			}

			AIslandPortal Portal = Cast<AIslandPortal>(RelevantHit.Actor);
			if(Portal != nullptr && PortalTraveler.ShouldKillTraveler(Portal))
			{
				ResetGrenade(true);
				return true;
			}

			if(Portal != nullptr && PortalTraveler.CanProjectileEnterPortal(Portal, StartLocation, EndLocation))
				OutPortal = Portal;

			if(CheckHasHitOppositeShieldType(RelevantHit))
			{
				CrumbTriggerHitOppositeColorShield(RelevantHit);
			}
			else if(OutPortal == nullptr && HasControl() && !bGrenadeIsAttached)
			{
				FVector Start = RelevantHit.Location + (StartLocation - RelevantHit.Location).GetSafeNormal() * Collision.SphereRadius;
				FVector End = RelevantHit.Location;
				FHitResult Hit = RelevantHit;

				if(!Start.Equals(End))
				{
					// We do a final trace to find the correct normal and location. Previously, when throwing a grenade between two floor tiles,
					// the grenade would be attached to the side of the further floor tile because the closer floor tile would've been ignored because of the SetupIgnoreActors trace.
					// This seems like the safest solution to mitigate this.
					FHazeTraceSettings FinalTrace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
					FinalTrace.UseComponentShape(Collision);
					FinalTrace.IgnorePlayers();
					FinalTrace.IgnoreActors(GrenadeResponseContainer.IgnoreMovementCollisionActors);
					FinalTrace.IgnoreComponents(GrenadeResponseContainer.IgnoreMovementCollisionComponents);
					FHitResultArray FinalHits = FinalTrace.QueryTraceMulti(Start, End);
					
					FHitResult RelevantFinalHit;
					bool bHasValidFinalHit = HitResultArrayHasValidHit(FinalHits, RelevantFinalHit);
	#if TEST
					TemporalLog.HitResults(f"{TracesCategory};{TraceTag} FinalTrace Hits", FinalHits, Start, End, Trace.Shape, Trace.ShapeWorldOffset);
					TemporalLog.Value(f"{TracesCategory};{TraceTag} bHasValidFinalHit", bHasValidFinalHit);
					TemporalLog.HitResults(f"{TracesCategory};{TraceTag} FinalTrace Relevant Hit", RelevantFinalHit, Trace.Shape, Trace.ShapeWorldOffset);
	#endif
					if(bHasValidFinalHit && RelevantFinalHit.bBlockingHit && !RelevantFinalHit.bStartPenetrating)
						Hit = RelevantFinalHit;
				}

				FVector RelativeLocation = Hit.Component.WorldTransform.InverseTransformPosition(Hit.Location);
				FRotator RelativeRotation = Hit.Component.WorldTransform.InverseTransformRotation(FRotator::MakeFromX(-Hit.Normal));
				CrumbAttachGrenade(Hit, RelativeLocation, RelativeRotation);
			}

			return true;
		}

		return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnTriggerBounce(FHitResult BounceHit)
	{
		FIslandRedBlueStickyGrenadeOnBounceOffParams Params;
		Params.GrenadeOwner = PlayerOwner;
		Params.BounceOffHit = BounceHit;
		Params.NewVelocity = CurrentVelocity;
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnBounceOffSurface(this, Params);
		UIslandRedBlueStickyGrenadeEffectHandler::Trigger_OnBounceOffSurface(PlayerOwner, Params);
	}

	private bool HitResultArrayHasValidHit(FHitResultArray Hits, FHitResult&out RelevantHit)
	{
		for(FHitResult Hit : Hits.BlockHits)
		{
			if(!CurrentHitIsValid(Hit))
				continue;

			RelevantHit = Hit;
			return true;
		}

		return false;
	}

	private bool CurrentHitIsValid(FHitResult Hit)
	{
		if(bGrenadeIsAttached && UIslandRedBlueStickyGrenadeIgnoreAttachedCollisionComponent::Get(Hit.Actor) != nullptr)
			return false;

		if(!Hit.bBlockingHit)
			return false;

		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		// We didn't hit a force field, the hit is valid!
		if(ForceField == nullptr)
			return true;

		// If this player can't hit the shield however and we are aiming through a hole, we should try to hit something behind.
		if(ForceField.IsPointInsideHoles(Hit.ImpactPoint))
			return false;

		return true;
	}

	private bool CheckHasHitOppositeShieldType(FHitResult Hit)
	{		
		UIslandForceFieldStateComponent ForceFieldState = UIslandForceFieldStateComponent::Get(Hit.Actor);
		if (ForceFieldState == nullptr)
			return false;

		if(!ForceFieldState.bShouldKillGrenade)
			return false;

		// If the shield is attached to the same thing the grenade is attached to we are going to assume the grenade just moved very fast and the shield moved in the same direction.
		// For example the spinning wheel with grenade locks makes the grenade fizzle out if you place it near the opposite colored shields.
		if(bGrenadeIsAttached && Hit.Actor.AttachmentRootActor == AttachmentRootActor)
			return false;

		if (ForceFieldState.CanPlayerHitCurrentForceField(PlayerOwner))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnGrenadeAnimation(bool bShouldBlossom){}
}

#if TEST
struct FIslandRedBlueStickyGrenadeDisableTemporalLogData
{
	int64 Frame = -1;
	bool bDisabled = false;
}

UCLASS(HideCategories = "Rendering Cooking Activation ComponentTick Physics Lod Collision")
class UIslandRedBlueStickyGrenadeDisableLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	private TArray<FIslandRedBlueStickyGrenadeDisableTemporalLogData> TemporalFrames;
	private AIslandRedBlueStickyGrenade Grenade;
	private const int MaxFrameCount = 100000;
	private int LoggedFrameCount = 0;

	TOptional<bool> OriginalDisableState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Grenade = Cast<AIslandRedBlueStickyGrenade>(Owner);
		LoggedFrameCount = 0;
		TemporalFrames.Empty(MaxFrameCount);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogRecordedFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		FIslandRedBlueStickyGrenadeDisableTemporalLogData TemporalFrameState;
		TemporalFrameState.Frame = LogFrameNumber;
		TemporalFrameState.bDisabled = Grenade.IsActorDisabled();
		
		int Index = LoggedFrameCount % MaxFrameCount;
		if (Index < TemporalFrames.Num())
			TemporalFrames[Index] = TemporalFrameState;	
		else
			TemporalFrames.Add(TemporalFrameState);

		LoggedFrameCount += 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		if(!OriginalDisableState.IsSet())
			OriginalDisableState.Set(Grenade.IsActorDisabled());

		FIslandRedBlueStickyGrenadeDisableTemporalLogData Data = BinaryFindIndex(LogFrameNumber);
		if(Data.bDisabled)
			Grenade.AddActorDisable(Grenade);
		else
			Grenade.RemoveActorDisable(Grenade);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		if(!OriginalDisableState.IsSet())
			return;

		if(OriginalDisableState.Value)
			Grenade.AddActorDisable(Grenade);
		else
			Grenade.RemoveActorDisable(Grenade);

		OriginalDisableState.Reset();
	}

	protected FIslandRedBlueStickyGrenadeDisableTemporalLogData BinaryFindIndex(int FrameNumberToFind) const
	{
		int IndexOffset = LoggedFrameCount % MaxFrameCount;

		int StartAbsIndex = Math::Max(0, LoggedFrameCount - MaxFrameCount);
		int EndAbsIndex = LoggedFrameCount - 1;

		while (EndAbsIndex >= StartAbsIndex) 
		{
			const int MiddleAbsIndex = StartAbsIndex + Math::IntegerDivisionTrunc((EndAbsIndex - StartAbsIndex), 2); 
			const int MiddleRealIndex = Math::WrapIndex(IndexOffset - (LoggedFrameCount - MiddleAbsIndex), 0, MaxFrameCount);

			const FIslandRedBlueStickyGrenadeDisableTemporalLogData& FrameData = TemporalFrames[MiddleRealIndex];
	
			if (FrameData.Frame == FrameNumberToFind)
			 	return TemporalFrames[MiddleRealIndex];
			
			if(FrameData.Frame < FrameNumberToFind)
				StartAbsIndex = MiddleAbsIndex + 1;
			else
				EndAbsIndex = MiddleAbsIndex - 1;
		}
		return FIslandRedBlueStickyGrenadeDisableTemporalLogData();
	}
}
#endif
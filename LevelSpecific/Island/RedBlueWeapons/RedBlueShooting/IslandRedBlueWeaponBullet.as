struct FIslandRedBlueWeaponBulletParams
{
	EIslandRedBlueWeaponHandType WeaponHand = EIslandRedBlueWeaponHandType::Left;
	float BulletInitialSpeed;
	float BulletSpeedAcceleration;
	float BulletSpeedMax;
	ECollisionChannel TraceChannel;
	float BulletDamageMultiplier;
	float BulletHomingInterpSpeed = -1.0;
	float BulletHomingInterpSpeedAccelerationDuration = 0.0;
	bool bDisengageHomingAfterPassingTarget = false;

	// Lerp towards actual target direction
	TOptional<FVector> ActualTargetDirection;
	float SnapToActualTargetDirectionDistance;
	float ActualTargetDirectionSmoothingDistance;
}

UCLASS(Abstract)
class AIslandRedBlueWeaponBullet : AHazeActor
{
	access BulletContinuousCollisionCheckerComponent = private, UIslandRedBlueContinuousBulletCollisionCheckingComponent;
	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UIslandPortalTravelerComponent PortalTraveler;
	default PortalTraveler.bIsProjectile = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueWeaponBulletDisableLoggerComponent DisableLoggerComp;
#endif

	const float MaxAliveTime = 3.0;
	// How far it needs to travel before being up to full size
	const float ScaleDistance = 30.0;

	FVector ShootDirection;
	private float Speed;
	private UIslandRedBlueTargetableComponent Targetable;
	private AHazePlayerCharacter PlayerOwner;
	private float TimeOfSpawn = -1.0;
	private float TimeOfImpact = -1.0;
	private EIslandRedBlueWeaponType WeaponType;

	private UHazeActorLocalSpawnPoolComponent SpawnPool;
	private FIslandRedBlueWeaponBulletParams BulletParams;
	private FHitResult TargetHit;
	
	access:ReadOnly FVector PreviousLocation;

	private TArray<AActor> IgnoreActors;
	private UIslandRedBlueWeaponUserComponent WeaponUserComp;
	private UPlayerAimingComponent AimComp;

	private FVector InitialScale;
	private float ScaleDuration;
	private float InitialDelta;
	private int SubstepCount;

	// Homing stuff
	private bool bHomingEnabled = false;
	private FHazeAcceleratedFloat AcceleratedHomingInterpSpeed;
	private FVector OriginalLocation;

	// Cone direction lerping stuff
	private FVector InitialShootDirection;
	private float DistanceMoved;
	bool bSetBezierPoints = false;
	private FVector BezierStart;
	private FVector BezierControlPoint;
	private FVector BezierEnd;
	private AActor LastReflectActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialScale = ActorScale3D;
	}

	void Initialize(FHitResult In_TargetHit, FVector In_ShoulderLocation, FVector In_ShootDirection, UIslandRedBlueTargetableComponent In_Targetable, FIslandRedBlueWeaponBulletParams In_BulletParams, EIslandRedBlueWeaponType In_WeaponType, UHazeActorLocalSpawnPoolComponent In_SpawnPool, AHazePlayerCharacter In_OwningPlayer, float In_TimeSinceShouldHaveShot)
	{
		SetActorControlSide(In_OwningPlayer);
		PlayerOwner = In_OwningPlayer;
		AimComp = UPlayerAimingComponent::Get(PlayerOwner);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(PlayerOwner);
		LastReflectActor = nullptr;

		BulletParams = In_BulletParams;
		TargetHit = In_TargetHit;
		ShootDirection = In_ShootDirection;
		if(TryConstrainShootDirectionTo2DConstraint(ShootDirection))
			SetShootDirection(ShootDirection);

		if(BulletParams.BulletHomingInterpSpeedAccelerationDuration <= 0.0)
			AcceleratedHomingInterpSpeed.SnapTo(BulletParams.BulletHomingInterpSpeed);
		else
			AcceleratedHomingInterpSpeed.SnapTo(SMALL_NUMBER);

		if(BulletParams.ActualTargetDirection.IsSet())
		{
#if TEST
			TEMPORAL_LOG(this)
				.DirectionalArrow("PreConstrainActualTargetDirection", ActorLocation, BulletParams.ActualTargetDirection.Value * 200.0, 5.f, 20.f)
			;
#endif

			TryConstrainShootDirectionTo2DConstraint(BulletParams.ActualTargetDirection.Value);
			InitialShootDirection = ShootDirection;
			DistanceMoved = 0.0;

#if TEST
			TEMPORAL_LOG(this)
				.DirectionalArrow("PostConstrainActualTargetDirection", ActorLocation, BulletParams.ActualTargetDirection.Value * 200.0, 5.f, 20.f)
			;
#endif
		}

		bSetBezierPoints = false;

		Speed = BulletParams.BulletInitialSpeed;
		float TotalAcceleration = BulletParams.BulletSpeedAcceleration * In_TimeSinceShouldHaveShot;
		Speed += TotalAcceleration * 0.5;
		Speed = Math::Clamp(Speed, 0.0, BulletParams.BulletSpeedMax);
		InitialDelta = Speed * In_TimeSinceShouldHaveShot;
		Speed += TotalAcceleration * 0.5;
		Speed = Math::Clamp(Speed, 0.0, BulletParams.BulletSpeedMax);
		
		SpawnPool = In_SpawnPool;
		WeaponType = In_WeaponType;
		TimeOfSpawn = Time::GetGameTimeSeconds() - In_TimeSinceShouldHaveShot;
		TimeOfImpact = -1.0;
		Targetable = In_Targetable;
		bHomingEnabled = Targetable != nullptr;
		PreviousLocation = ActorLocation;
		OriginalLocation = ActorLocation;

		PortalTraveler.TravelerType = IslandRedBlueWeapon::IsPlayerRed(PlayerOwner) ? EIslandTravelerType::Red : EIslandTravelerType::Blue;

		RemoveActorDisable(this);

		ScaleDuration = ScaleDistance / Speed; 
		SetActorScale3D(FVector(KINDA_SMALL_NUMBER));

		// Trace from the shoulder of the arm that was used to shoot with to the bullet location.
		// If we hit something the player is probably sticking their gun through a wall so we should kill the bullet instantly.
		if(TraceForHits(In_ShoulderLocation, ActorLocation, "Shoulder"))
			return;

		// If we are in sidescroller or top down the origin of the trace will be pretty much lined up with the muzzle so we don't need to ignore any actors!
		if(AimComp.GetCurrentAimingConstraintType() != EAimingConstraintType2D::None)
			return;

		FVector Origin = ActorLocation;
		FVector Destination = TargetHit.Location;
		if(!TargetHit.bBlockingHit)
			Destination = TargetHit.TraceEnd;

		FHazeTraceSettings Trace = Trace::InitChannel(BulletParams.TraceChannel);
		Trace.UseLine();
		Trace.IgnorePlayers();
		FHitResultArray BulletHits = Trace.QueryTraceMulti(Origin, Destination);

#if TEST
		TEMPORAL_LOG(this)
			.HitResults("TargetHit", TargetHit, FHazeTraceShape::MakeLine())
			.HitResults("IgnoreActors Trace", BulletHits, ActorLocation, TargetHit.Location, FHazeTraceShape::MakeLine())
		;
#endif

		// Ignore any actors that aren't the pre traced actor
		// In the below situation, if the player stands on the edge and aims with the camera on point A the gun will be at a lower angle than
		// the camera and hit the ledge (B) instead. So we trace again from the bullet location to the target location to see if we hit any actors on the way and if so, ignore these
		// │ A /___________  \┌─┐
		// │   \	       	 /└─┘
		// └──────┐ B 	 O
		//   	  │	  🔫/|\
		//   	  │    	 │
		// 		  │	  	/ \
		// 		  └─────────
		for(FHitResult Current : BulletHits.BlockHits)
		{
			if(Current.Actor == In_TargetHit.Actor)
				continue;

			if(In_Targetable != nullptr && Current.Actor == In_Targetable.Owner)
				continue;

			IgnoreActors.Add(Current.Actor);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Time::GetGameTimeSince(TimeOfSpawn) > MaxAliveTime)
		{
			Kill();
			return;
		}

		FVector Delta = FVector::ZeroVector;
		Speed += BulletParams.BulletSpeedAcceleration * DeltaTime * 0.5;
		Speed = Math::Clamp(Speed, 0.0, BulletParams.BulletSpeedMax);
		float DeltaDistance = (Speed * DeltaTime) + InitialDelta;
		Speed += BulletParams.BulletSpeedAcceleration * DeltaTime * 0.5;
		Speed = Math::Clamp(Speed, 0.0, BulletParams.BulletSpeedMax);

		if(bHomingEnabled)
			HandleHoming(DeltaTime);

		if(BulletParams.ActualTargetDirection.IsSet())
			HandleConeDirectionLerping(Delta, DeltaDistance);

		Delta += ShootDirection * DeltaDistance;
		InitialDelta = 0.0;

		if(!Delta.IsNearlyZero())
		{
			FVector Origin = Collision.WorldLocation;
			PreviousLocation = ActorLocation;
			TraceForHits(Origin, Origin + Delta, "Tick");
		}
		
		float ScaleAlpha = Math::GetPercentageBetweenClamped(0, ScaleDuration, Time::GetGameTimeSince(TimeOfSpawn));
		FVector NewScale = Math::Lerp(FVector(KINDA_SMALL_NUMBER), InitialScale, ScaleAlpha);
		SetActorScale3D(NewScale);

#if TEST
		TEMPORAL_LOG(this)
		.Value("Targetable", Targetable)
		.Value("Homing Enabled", bHomingEnabled)
		.Value("Speed", Speed)
		.DirectionalArrow("ShootDirection", ActorLocation, ShootDirection * 200.0, 5.f, 20.f)
		;
#endif
	}

	private void HandleHoming(float DeltaTime)
	{
		if(BulletParams.BulletHomingInterpSpeedAccelerationDuration > 0.0)
		{
			AcceleratedHomingInterpSpeed.AccelerateTo(BulletParams.BulletHomingInterpSpeed, BulletParams.BulletHomingInterpSpeedAccelerationDuration, DeltaTime);
		}

		FVector NewShootDirection = (Targetable.WorldLocation - ActorLocation).GetSafeNormal();
		TryConstrainShootDirectionTo2DConstraint(NewShootDirection);
		NewShootDirection = Math::QInterpTo(ShootDirection.ToOrientationQuat(), NewShootDirection.ToOrientationQuat(), DeltaTime, AcceleratedHomingInterpSpeed.Value).ForwardVector;

		if(Targetable.IsDisabled() || NewShootDirection.IsNearlyZero() || 
			NewShootDirection.DotProduct(ActorForwardVector) < 0.0)
		{
			bHomingEnabled = false;
		}

		if(BulletParams.bDisengageHomingAfterPassingTarget && (OriginalLocation - Targetable.WorldLocation).GetSafeNormal().DotProduct(ActorLocation - Targetable.WorldLocation) < 0.0)
		{
			bHomingEnabled = false;
		}

		if(bHomingEnabled)
		{
			SetShootDirection(NewShootDirection);
			BulletParams.ActualTargetDirection.Reset();
		}
	}

	/** This is for when shooting in a cone in sidescroller,
	* it should lerp towards the actual shoot direction after a while so that the cone doesn't get too wide and it gets hard to hit stuff far away.
	*/
	private void HandleConeDirectionLerping(FVector& Delta, float& DeltaDistance)
	{
		float StartDistance = BulletParams.SnapToActualTargetDirectionDistance - BulletParams.ActualTargetDirectionSmoothingDistance;
		float PreviousDistanceMoved = DistanceMoved;
		DistanceMoved += DeltaDistance;
		
		if(DistanceMoved > StartDistance)
		{
			float Remainder = DistanceMoved - StartDistance;
			FVector Origin = ActorLocation;

			if(PreviousDistanceMoved < StartDistance)
			{
				Delta += ShootDirection * (DeltaDistance - Remainder);
				Origin += Delta;

				// This is the location of the bullet just before it starts lerping
				FVector FinalStraightLocation = Origin;
				// This is the location where the straight line starts
				FVector StraightDirectionOrigin = FinalStraightLocation + ShootDirection * BulletParams.ActualTargetDirectionSmoothingDistance;

				BezierStart = FinalStraightLocation;
				BezierControlPoint = StraightDirectionOrigin;
				BezierEnd = StraightDirectionOrigin + BulletParams.ActualTargetDirection.Value * BulletParams.ActualTargetDirectionSmoothingDistance;
				bSetBezierPoints = true;
			}

			DeltaDistance = Remainder;

			// Debug::DrawDebugPoint(BezierStart, 3.0, FLinearColor::Purple, 0.5, true);
			// Debug::DrawDebugPoint(BezierControlPoint, 3.0, FLinearColor::LucBlue, 0.5, true);
			// Debug::DrawDebugPoint(BezierEnd, 3.0, FLinearColor::DPink, 0.5, true);

			float BezierLength = BezierCurve::GetLength_1CP(BezierStart, BezierControlPoint, BezierEnd);
			if(Remainder > BezierLength)
			{
				Delta += BezierEnd - Origin;
				DeltaDistance -= BezierLength;
				SetShootDirection(BulletParams.ActualTargetDirection.Value);
				BulletParams.ActualTargetDirection.Reset();
			}
			else
			{
				float Alpha = Remainder / BezierLength;
				FVector TargetLocation = BezierCurve::GetLocation_1CP_ConstantSpeed(BezierStart, BezierControlPoint, BezierEnd, Alpha);
				Delta += TargetLocation - Origin;
				DeltaDistance = 0.0;
				FVector NewShootDirection = FQuat::Slerp(InitialShootDirection.ToOrientationQuat(), BulletParams.ActualTargetDirection.Value.ToOrientationQuat(), Alpha).ForwardVector;
				SetShootDirection(NewShootDirection);

#if TEST
				TEMPORAL_LOG(this)
					.DirectionalArrow("ActualTargetDirection", ActorLocation, BulletParams.ActualTargetDirection.Value * 200.0, 5.f, 20.f)
					.Point("BezierStart", BezierStart, 15.f, FLinearColor::Green)
					.Point("BezierControlPoint", BezierControlPoint, 15.f, FLinearColor::Yellow)
					.Point("BezierEnd", BezierEnd, 15.f, FLinearColor::Red)
				;
#endif
			}
		}
	}

	bool TryConstrainShootDirectionTo2DConstraint(FVector& Direction)
	{
		EAimingConstraintType2D ConstraintType = AimComp.GetCurrentAimingConstraintType();
		
		switch(ConstraintType)
		{
			case EAimingConstraintType2D::Plane:
			{
				FVector PlaneNormal = AimComp.Get2DConstraintPlaneNormal();
				Direction = Direction.ConstrainToPlane(PlaneNormal).GetSafeNormal();
				return true;
			}
			case EAimingConstraintType2D::Spline:
			{
				UHazeSplineComponent Spline = AimComp.Get2DConstraintSpline();
				FTransform SplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
				FVector LocalDirection = SplineTransform.InverseTransformVectorNoScale(Direction);
				LocalDirection.Y = 0.0;
				Direction = SplineTransform.TransformVectorNoScale(LocalDirection).GetSafeNormal();
				return true;
			}
			default:
				return false;
		}
	}

	access:BulletContinuousCollisionCheckerComponent
	bool TraceForHits(FVector Origin, FVector Destination, FString TraceTag, bool bRecursive = false)
	{
		if(!bRecursive)
			SubstepCount = 0;

		FHazeTraceSettings Trace = Trace::InitChannel(BulletParams.TraceChannel);
		Trace.UseLine();
		Trace.SetReturnPhysMaterial(true);
		Trace.SetTraceComplex();
		Trace.IgnoreActors(IgnoreActors);
		FHitResultArray Hits = Trace.QueryTraceMulti(Origin, Destination);

		bool bResult = false;
		for(int i = 0; i < Hits.BlockHits.Num(); i++)
		{
			FHitResult Hit = Hits.BlockHits[i];
			UIslandRedBlueReflectComponent ReflectComp;
			bool bShouldGetReflected = false;
			bool bShouldGetKilled = false;
			AIslandPortal Portal;
			if(!CurrentHitIsValid(Hit, bShouldGetKilled, bShouldGetReflected, ReflectComp, Portal))
				continue;

			TArray<UIslandRedBlueImpactResponseComponent> ImpactResponses;
			Hit.Actor.GetComponentsByClass(UIslandRedBlueImpactResponseComponent, ImpactResponses);
			TArray<UIslandRedBlueImpactResponseComponent> ValidResponses;

			for(auto Response : ImpactResponses)
			{
				if(Response != nullptr && Response.CanApplyImpact(PlayerOwner, Hit))
				{
					WeaponUserComp.ApplyImpact(ShootDirection, Response, Hit, BulletParams.BulletDamageMultiplier);
					ValidResponses.Add(Response);
				}
			}

			// Teleport bullet to other side of portal!
			if(Portal != nullptr)
			{
				FVector Delta;
				PortalTeleportBullet(Portal, Hit.ImpactPoint, Hit.TraceEnd, Delta);
#if TEST
				FString AppendString = "";
				if(bRecursive)
					AppendString += f" (Substep: {SubstepCount})";
				TEMPORAL_LOG(this)
					.Point(f"Post Teleport Location{AppendString}", ActorLocation, 20.f, FLinearColor::Red)
					.DirectionalArrow(f"Post Teleport Direction{AppendString}", ActorLocation, ShootDirection * 100.0, 2.f, 100.f)
				;
#endif
				FVector NewOrigin = ActorLocation;
				++SubstepCount;
				if(SubstepCount < 3)
					TraceForHits(NewOrigin, NewOrigin + Delta, TraceTag + "_Portal", true);
				bResult = true;
				break;
			}

			if(bShouldGetKilled)
			{
				TriggerHitEffect(Hit, ValidResponses);
				TimeOfImpact = Time::GameTimeSeconds;
				Kill();
				bResult = true;
				break;
			}

			if(bShouldGetReflected)
			{
				FVector NewDir = Math::GetReflectionVector(ShootDirection, Hit.ImpactNormal);
				LastReflectActor = Hit.Actor;

				if(ShouldReflectedBulletBeConstrained(Hit))
					TryConstrainShootDirectionTo2DConstraint(NewDir);

				SetShootDirection(NewDir);
				BulletParams.ActualTargetDirection.Reset();
				bHomingEnabled = false;

				ActorLocation = Hit.ImpactPoint + Hit.ImpactNormal * 0.125;
#if TEST
				FString AppendString = "";
				if(bRecursive)
					AppendString += f" (Substep: {SubstepCount})";
				TEMPORAL_LOG(this)
					.Point(f"Post Reflection Location{AppendString}", ActorLocation, 20.f, FLinearColor::Red)
					.DirectionalArrow(f"Post Reflection Direction{AppendString}", ActorLocation, ShootDirection * 100.0, 2.f, 100.f)
					.HitResults(f"Reflect Hit{AppendString}", Hit, FHazeTraceShape::MakeLine())
				;
#endif

				if(ReflectComp != nullptr)
					ReflectComp.OnBulletReflect.Broadcast(this, Hit.Actor, Hit.ImpactPoint);

				auto AIHealthComp = UBasicAIHealthComponent::Get(Hit.Actor);
				if(AIHealthComp != nullptr)
				{	
					FIslandRedBlueWeaponOnBulletImpactParams Params;
					Params.BulletLocation = ActorLocation;
					Params.ImpactPoint = Hit.ImpactPoint;
					Params.ImpactNormal = Hit.ImpactNormal;
					Params.PhysMat = Hit.PhysMaterial;
					Params.ResponseComponents = ValidResponses;
					Params.WeaponType = WeaponType;		

					auto Weapon = BulletParams.WeaponHand == EIslandRedBlueWeaponHandType::Left ? WeaponUserComp.GetLeftWeapon() : WeaponUserComp.GetRightWeapon();
					UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletReflectedAI(Weapon, Params);
				}

				++SubstepCount;
				float DeltaDist = Destination.Distance(Origin);
				DeltaDist *= (1.0 - Hit.Time);
				FVector NewOrigin = ActorLocation;
				FVector NewDestination = NewOrigin + ShootDirection * DeltaDist;
				bResult = true;

				if(SubstepCount < 3)
					TraceForHits(NewOrigin, NewDestination, TraceTag, true);
				break;
			}
			
			devError("Not implemented");
			bResult = true;
			break;
		}

		if(!bResult)
			ActorLocation = Destination;

#if TEST
		FString Tag = TraceTag;
		if(bRecursive)
			Tag += f"_Substep_{SubstepCount}";

		TEMPORAL_LOG(this)
			.HitResults(f"TraceForHits() Hits ({Tag})", Hits, Origin, Destination, FHazeTraceShape::MakeLine())
		;

		if(!bRecursive)
			TEMPORAL_LOG(this).Point(f"Final Location ({Tag})", ActorLocation, 20.f);

		for(int i = 0; i < IgnoreActors.Num(); i++)
		{
			AActor Actor = IgnoreActors[i];
			TEMPORAL_LOG(this).Value(f"2#Ignore Actors ({Tag});Actor {i + 1}", Actor);
		}
#endif

		return bResult;
	}

	private bool ShouldReflectedBulletBeConstrained(FHitResult Hit)
	{
		EAimingConstraintType2D ConstraintType = AimComp.GetCurrentAimingConstraintType();
		if(ConstraintType == EAimingConstraintType2D::None)
			return false;

		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		if(ForceField == nullptr)
			return true;
		
		if(!ForceField.bIsSphereForceField)
			return true;
		
		FVector ImpactToForceField = ForceField.ActorLocation - Hit.ImpactPoint;
		if(Hit.ImpactNormal.DotProduct(ImpactToForceField) < 0.0)
			return true;

		return false;
	}

	private FHitResult GetSphereHitFromHit(FHitResult Hit)
	{
		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		if(ForceField == nullptr)
			return Hit;

		if(!ForceField.bIsSphereForceField)
			return Hit;

		float Radius = ForceField.GetSphereRadius();
		FVector Center = ForceField.ActorLocation;

		float TraceLength = Hit.TraceStart.Distance(Hit.TraceEnd);

		FLineSphereIntersection Intersection = Math::GetLineSegmentSphereIntersectionPoints(Hit.TraceStart, Hit.TraceEnd, Center, Radius);
		if(!Intersection.bHasIntersection)
			return Hit;

		FHitResult OutHit = Hit;
		FVector Point = Intersection.MinIntersection;
		bool bCameFromInside = OutHit.TraceStart.Distance(Center) < Radius;
		OutHit.ImpactPoint = Point;
		OutHit.Location = Point;
		OutHit.ImpactNormal = (Point - Center).GetSafeNormal();
		if(bCameFromInside)
			OutHit.ImpactNormal = -OutHit.ImpactNormal;
		OutHit.Normal = OutHit.ImpactNormal;
		OutHit.Distance = OutHit.TraceStart.Distance(Point);
		OutHit.Time = OutHit.Distance / TraceLength;
		return OutHit;
	}

	void PortalTeleportBullet(AIslandPortal Portal, FVector ImpactPoint, FVector TraceEnd, FVector& Delta)
	{
		FVector Start;
		FVector End;
		PortalTraveler.GetProjectileLocationOnOtherSide(Portal, ImpactPoint, TraceEnd, Start, End);
		ActorLocation = Start;
		Delta = (End - Start);
		ShootDirection = Delta.GetSafeNormal();
		TryConstrainShootDirectionTo2DConstraint(ShootDirection);
		SetShootDirection(ShootDirection);

		if(BulletParams.ActualTargetDirection.IsSet())
		{
			InitialShootDirection = PortalTraveler.GetDirectionOnOtherSide(Portal, InitialShootDirection);
			BulletParams.ActualTargetDirection.Set(PortalTraveler.GetDirectionOnOtherSide(Portal, BulletParams.ActualTargetDirection.Value));

			if(bSetBezierPoints)
			{
				BezierStart = PortalTraveler.GetPointOnOtherSide(Portal, BezierStart);
				BezierControlPoint = PortalTraveler.GetPointOnOtherSide(Portal, BezierControlPoint);
				BezierEnd = PortalTraveler.GetPointOnOtherSide(Portal, BezierEnd);
			}
		}

		IgnoreActors.AddUnique(Portal.DestinationPortal);
		for(AActor IgnoredActor : Portal.DestinationPortal.ActorsToIgnoreWhenEnteringPortal)
		{
			IgnoreActors.AddUnique(IgnoredActor);
		}

		FIslandPortalBulletEnterEffectParams Params;
		Params.OriginPortal = Portal;
		Params.DestinationPortal = Portal.DestinationPortal;
		Params.Bullet = this;
		UIslandPortalEffectHandler::Trigger_OnBulletEnter(Portal, Params);
	}

	void TriggerHitEffect(const FHitResult& Hit, const TArray<UIslandRedBlueImpactResponseComponent>& ValidResponses)
	{
		AIslandRedBlueForceField ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		TArray<FIslandRedBlueWeaponBulletForceFieldEffectHandlerInfo> ForceFieldBulletHoles;

		if(ForceField != nullptr)
		{
			for(int i = 0; i < ForceField.HoleData.Num(); i++)
			{
				if (!ForceField.HoleData[i].bIsValidHole)
					continue;
				if(ForceField.IsPointInsideHole(ForceField.HoleData[i], Hit.ImpactPoint))
				{
					FIslandRedBlueWeaponBulletForceFieldEffectHandlerInfo BulletHole;
					BulletHole.BulletHoleLocation = ForceField.GetHoleWorldLocation(ForceField.HoleData[i]);
					BulletHole.BulletHoleRadius = ForceField.HoleData[i].HoleRadius;
					BulletHole.bHoleWasJustCreated = ForceField.HoleData[i].HoleCreatedFrame == GFrameNumber;
					ForceFieldBulletHoles.Add(BulletHole);
				}
			}
		}

		FIslandRedBlueWeaponOnBulletImpactParams Params;
		Params.BulletLocation = ActorLocation;
		Params.ImpactPoint = Hit.ImpactPoint;
		Params.ImpactNormal = Hit.ImpactNormal;
		Params.PhysMat = Hit.PhysMaterial;
		Params.ResponseComponents = ValidResponses;
		Params.WeaponType = WeaponType;

		FIslandRedBlueWeaponForceFieldEffectHandlerInfo ForceFieldInfo;
		ForceFieldInfo.ForceFieldActor = ForceField;
		ForceFieldInfo.HitForceFieldBulletHoles = ForceFieldBulletHoles;
		ForceFieldInfo.bCurrentBulletCanMakeHoles = ForceField != nullptr && IslandRedBlueWeapon::PlayerCanHitShieldType(PlayerOwner, ForceField.ForceFieldType) && !ForceField.bBulletsShouldReflectOnSurface;
		ForceFieldInfo.bForceFieldReflectsBullets = ForceField != nullptr && ForceField.bBulletsShouldReflectOnSurface;
		Params.ForceFieldInfo = ForceFieldInfo;

		UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpact(this, Params);

		auto Weapon = BulletParams.WeaponHand == EIslandRedBlueWeaponHandType::Left ? WeaponUserComp.GetLeftWeapon() : WeaponUserComp.GetRightWeapon();

		// This is the most generic way to figure out if we hit an AI to my knowledge, since bosses are sometimes just a AHazeCharacter so we can't cast to ABasicAICharacter for example.
		auto AIHealthComp = UBasicAIHealthComponent::Get(Hit.Actor);
		if(AIHealthComp != nullptr || Hit.Actor.ActorHasTag(n"TreatAsAIForImpacts"))
		{
			FIslandRedBlueWeaponOnBulletImpactAIParams AIParams;
			AIParams.HitActor = Hit.Actor;
			AIParams.BulletLocation = ActorLocation;
			AIParams.ImpactPoint = Hit.ImpactPoint;
			AIParams.ImpactNormal = Hit.ImpactNormal;
			AIParams.PhysMat = Hit.PhysMaterial;
			AIParams.WeaponType = WeaponType;
			UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpactAI(this, AIParams);
			UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpactAI(Weapon, AIParams);
		}
		else
		{
			FIslandRedBlueWeaponOnBulletImpactAIParams NonAIParams;
			NonAIParams.HitActor = Hit.Actor;
			NonAIParams.BulletLocation = ActorLocation;
			NonAIParams.ImpactPoint = Hit.ImpactPoint;
			NonAIParams.ImpactNormal = Hit.ImpactNormal;
			NonAIParams.PhysMat = Hit.PhysMaterial;
			NonAIParams.WeaponType = WeaponType;
			UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpactNonAI(this, NonAIParams);
			UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpactNonAI(Weapon, NonAIParams);

			// Only fire the general event for Audio on Weapon if not hitting AI
			UIslandRedBlueWeaponBulletEffectHandler::Trigger_OnBulletImpact(Weapon, Params);
		}

		auto WeaponUser = UIslandRedBlueWeaponUserComponent::Get(PlayerOwner);
		WeaponUser.AddImpactFlash(Hit.ImpactPoint + Hit.ImpactNormal * 50);
	}

	void Kill()
	{
		AddActorDisable(this);

		if(SpawnPool != nullptr)
			SpawnPool.UnSpawn(this);
		
		TimeOfSpawn = -1.0;
		IgnoreActors.Empty();

#if TEST
		TEMPORAL_LOG(this).Value("Killed", true);
#endif
	}

	bool CurrentHitIsValid(FHitResult Hit, bool&out bShouldGetKilled, bool&out bShouldGetReflected, UIslandRedBlueReflectComponent& OutReflectComponent, AIslandPortal&out OutPortal)
	{
		bShouldGetKilled = true;
		bShouldGetReflected = false;
		if(!Hit.bBlockingHit)
			return false;

		auto ForceField = Cast<AIslandRedBlueForceField>(Hit.Actor);
		if(ForceField != nullptr)
			return CurrentForceFieldHitIsValid(Hit, ForceField, bShouldGetKilled, bShouldGetReflected);
			
		auto ReflectComp = UIslandRedBlueReflectComponent::Get(Hit.Actor);
		if(ReflectComp != nullptr && ReflectComp.ShouldReflectFor(PlayerOwner, Hit.Component) && Hit.Actor != LastReflectActor)
		{
			OutReflectComponent = ReflectComp;
			bShouldGetReflected = true;
			bShouldGetKilled = false;
			return true;
		}

		auto Portal = Cast<AIslandPortal>(Hit.Actor);
		if(Portal != nullptr && PortalTraveler.CanProjectileEnterPortal(Portal, Hit.TraceStart, Hit.TraceEnd))
		{
			OutPortal = Portal;
			bShouldGetKilled = false;
		}
		return true;
	}

	bool CurrentForceFieldHitIsValid(FHitResult Hit, AIslandRedBlueForceField ForceField, bool&out bShouldGetKilled, bool&out bShouldGetReflected)
	{
		if(ForceField.IsPointInsideHoles(Hit.ImpactPoint))
			return false;

		if(ForceField.bBulletsShouldReflectOnSurface && (ForceField.bIsSphereForceField || ForceField != LastReflectActor))
		{
			bShouldGetReflected = true;
			bShouldGetKilled = false;
		}

		return true;
	}

	void SetShootDirection(FVector NewDirection)
	{
		ShootDirection = NewDirection;
		ActorRotation = FRotator::MakeFromXZ(ShootDirection, FVector::UpVector);
	}

	float GetTimeSinceImpact() const property
	{
		if (TimeOfImpact < 0.0)
			return BIG_NUMBER;
		return Time::GetGameTimeSince(TimeOfImpact);
	}
}

#if TEST
struct FIslandRedBlueWeaponBulletDisableTemporalLogData
{
	int64 Frame = -1;
	bool bDisabled = false;
}

UCLASS(HideCategories = "Rendering Cooking Activation ComponentTick Physics Lod Collision")
class UIslandRedBlueWeaponBulletDisableLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	private TArray<FIslandRedBlueWeaponBulletDisableTemporalLogData> TemporalFrames;
	private AIslandRedBlueWeaponBullet Bullet;
	private const int MaxFrameCount = 100000;
	private int LoggedFrameCount = 0;

	TOptional<bool> OriginalDisableState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Bullet = Cast<AIslandRedBlueWeaponBullet>(Owner);
		LoggedFrameCount = 0;
		TemporalFrames.Empty(MaxFrameCount);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogRecordedFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		FIslandRedBlueWeaponBulletDisableTemporalLogData TemporalFrameState;
		TemporalFrameState.Frame = LogFrameNumber;
		TemporalFrameState.bDisabled = Bullet.IsActorDisabled();
		
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
			OriginalDisableState.Set(Bullet.IsActorDisabled());

		FIslandRedBlueWeaponBulletDisableTemporalLogData Data = BinaryFindIndex(LogFrameNumber);
		if(Data.bDisabled)
			Bullet.AddActorDisable(Bullet);
		else
			Bullet.RemoveActorDisable(Bullet);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		if(!OriginalDisableState.IsSet())
			return;

		if(OriginalDisableState.Value)
			Bullet.AddActorDisable(Bullet);
		else
			Bullet.RemoveActorDisable(Bullet);

		OriginalDisableState.Reset();
	}

	protected FIslandRedBlueWeaponBulletDisableTemporalLogData BinaryFindIndex(int FrameNumberToFind) const
	{
		int IndexOffset = LoggedFrameCount % MaxFrameCount;

		int StartAbsIndex = Math::Max(0, LoggedFrameCount - MaxFrameCount);
		int EndAbsIndex = LoggedFrameCount - 1;

		while (EndAbsIndex >= StartAbsIndex) 
		{
			const int MiddleAbsIndex = StartAbsIndex + Math::IntegerDivisionTrunc((EndAbsIndex - StartAbsIndex), 2); 
			const int MiddleRealIndex = Math::WrapIndex(IndexOffset - (LoggedFrameCount - MiddleAbsIndex), 0, MaxFrameCount);

			const FIslandRedBlueWeaponBulletDisableTemporalLogData& FrameData = TemporalFrames[MiddleRealIndex];
	
			if (FrameData.Frame == FrameNumberToFind)
			 	return TemporalFrames[MiddleRealIndex];
			
			if(FrameData.Frame < FrameNumberToFind)
				StartAbsIndex = MiddleAbsIndex + 1;
			else
				EndAbsIndex = MiddleAbsIndex - 1;
		}
		return FIslandRedBlueWeaponBulletDisableTemporalLogData();
	}
}
#endif
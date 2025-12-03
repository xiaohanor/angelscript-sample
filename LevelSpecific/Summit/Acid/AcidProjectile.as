
struct FAcidProjectileParams
{
	TSubclassOf<AAcidProjectile> ProjectileClass;
	FVector Origin;
	float Speed = 0.0;
	float Gravity = 0.0;
	float LifeTime = 0.0;
	float Range = 0.0;

	TSubclassOf<AAcidPuddle> PuddleClass;
	float PuddleRadius = 0.0;
	float PuddleDuration = 0.0;

	FVector StartScale(1.0, 1.0, 1.0);
	FVector EndScale(1.0, 1.0, 1.0);
	float ScaleUpDuration = 0.0;

	float TraceRadius = 0.0;
	float SplashRadius = 0.0;

	float Damage = 0.0;

	FVector Target;
	USceneComponent TargetRelativeTo;

	AHazePlayerCharacter FiringPlayer;
};

UCLASS(Abstract)
class AAcidProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UAcidManagerComponent AcidManager;
	UTeenDragonAcidSprayComponent SprayComp;
	FAcidProjectileParams ProjectileParams;

	FVector Velocity;
	FVector Gravity;
	FVector DirToTarget;
	float LifeTime;
	float CoveredDistance = 0.0;
	float CoveredTime = 0.0;
	float DistanceUntilDisappearing;

	UTeenDragonAcidSpraySettings SpraySettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	void Init(FAcidProjectileParams Params)
	{
		auto Dragon = Params.FiringPlayer;

		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(Dragon);

		ProjectileParams = Params;
		LifeTime = Time::GameTimeSeconds + Params.LifeTime;
		SetActorLocation(Params.Origin);

		SprayComp = UTeenDragonAcidSprayComponent::Get(Dragon);

		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Params.Origin, Params.Target, Params.Gravity, Params.Speed);

		Gravity = FVector(0.0, 0.0, -Params.Gravity);

		CoveredDistance = 0.0;
		CoveredTime = 0.0;

		float FlyTime = 0;
		Trajectory::TrajectoryTimeToReachHeight(
				Velocity.DotProduct(FVector::UpVector),
				Params.Gravity,
				Params.Target.Z - Params.Origin.Z,
				FlyTime
			);
		FlyTime *= 2.0;
		FlyTime = Math::Min(FlyTime, SpraySettings.ProjectileLiftTime);

		// the particle is doing some non physics slow down below so lets just approximate that
		FlyTime *= 0.95;

		DirToTarget = (Params.Target - Params.Origin).GetSafeNormal();

		SprayComp.SprayEffect.SetNiagaraVariableVec3("GP_Origin", Params.Origin);
		SprayComp.SprayEffect.SetNiagaraVariableVec3("GP_Target", Params.Target);
		SprayComp.SprayEffect.SetNiagaraVariableVec3("GP_Velocity", Velocity);
		SprayComp.SprayEffect.SetNiagaraVariableVec3("GP_Gravity", Gravity);
		SprayComp.SprayEffect.SetNiagaraVariableFloat("GP_Lifetime", FlyTime);

		SprayComp.TopDownSprayEffect.SetNiagaraVariableVec3("GP_Origin", Params.Origin);
		SprayComp.TopDownSprayEffect.SetNiagaraVariableVec3("GP_Target", Params.Target);
		SprayComp.TopDownSprayEffect.SetNiagaraVariableVec3("GP_Velocity", Velocity);
		SprayComp.TopDownSprayEffect.SetNiagaraVariableVec3("GP_Gravity", Gravity);
		SprayComp.TopDownSprayEffect.SetNiagaraVariableFloat("GP_Lifetime", FlyTime);

		DistanceUntilDisappearing = SpraySettings.AcidSprayRange / SpraySettings.ProjectileDropOffAlpha;

		SetActorScale3D(Params.StartScale);
	}

	void ProjectileImpact(FHitResult Hit, bool bHitMetal = false)
	{
		if (ProjectileParams.PuddleRadius > 0.0
			&& ProjectileParams.PuddleDuration > 0.0)
		{
			FAcidPuddleParams PuddleParams;
			PuddleParams.PuddleClass = ProjectileParams.PuddleClass;
			PuddleParams.Location = Hit.ImpactPoint;
			PuddleParams.PuddleNormal = Hit.Normal;
			PuddleParams.Radius = ProjectileParams.PuddleRadius;
			PuddleParams.Duration = ProjectileParams.PuddleDuration;

			Acid::PlaceAcidPuddle(PuddleParams);

			if (ProjectileParams.FiringPlayer != nullptr)
			{
				SprayComp.SendAnalyticalColllisionDataToNiagara(Hit, Velocity);

				FTeenDragonAcidProjectileImpactParams ImpactParams;
				ImpactParams.ImpactComponent = Hit.Component;
				ImpactParams.ImpactLocation = Hit.ImpactPoint;
				ImpactParams.ImpactNormal = Hit.ImpactNormal;
				UTeenDragonAcidSprayEventHandler::Trigger_AcidProjectileImpact(ProjectileParams.FiringPlayer, ImpactParams);
			}
		}

		AcidManager.ReturnToPool(this);

		TArray<UAcidResponseComponent> ResponseComps;
		if (Hit.Actor != nullptr)
		{
			if (!Hit.Component.HasTag(n"NonAcidable"))
				Hit.Actor.GetComponentsByClass(ResponseComps);
		}

		if (ProjectileParams.SplashRadius != 0.0)
		{
			FHazeTraceSettings Trace;
			Trace.IgnoreActor(this);
			Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
			Trace.UseSphereShape(
				ProjectileParams.SplashRadius * ActorScale3D.GetMax()
			);

			auto Overlaps = Trace.QueryOverlaps(Hit.ImpactPoint);
			for (auto Overlap : Overlaps)
			{
				if (Overlap.Actor == nullptr)
					continue;
				if (Overlap.Component.HasTag(n"NonAcidable"))
					continue;

				TArray<UAcidResponseComponent> ActorAcidComps;
				Overlap.Actor.GetComponentsByClass(ActorAcidComps);

				for (auto OverlapAcidComp : ActorAcidComps)
					ResponseComps.AddUnique(OverlapAcidComp);
			}
		}

		if(Game::Mio.HasControl())
		{
			for (auto ResponseComp : ResponseComps)
			{
				if (ResponseComp.Shape.IsZeroSize() 
				|| ResponseComp.Shape.GetWorldDistanceToShape(ResponseComp.WorldTransform, Hit.ImpactPoint) <= 1.0)
				{
					SprayComp.AddAcidHitEvent(ResponseComp, ProjectileParams.Damage, Hit.ImpactPoint);

					if(bHitMetal)
					{
						/* 
						 * We are moving the metal melting code to SummitMeltComp (or AcidResponseComp) 
						 * 
						 * Ideally we would pipe this through the AcidHitEvents above, 
						 * but Fredrik needs to review that first.  
						 * 
						 * //Sydney
						 * 
						 */
						// auto MeltComp = USummitMeltComponent::Get(ResponseComp.Owner);
						// if(MeltComp != nullptr)
						// {
						// 	SprayComp.CopyOverAssetsToMeltComp(MeltComp);
						// 	MeltComp.ProcessMetalHit(Hit, Velocity.GetSafeNormal());
						// }

						SprayComp.ProcessMetalHit(Hit, Velocity.GetSafeNormal());
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector WantedPosition;
		FRotator WantedRotation;

		WantedPosition = ActorLocation;
		WantedPosition += Velocity * DeltaSeconds;
		WantedRotation = FRotator::MakeFromX(Velocity);
		Velocity += Gravity * DeltaSeconds; 
		
		FVector Delta = WantedPosition - ActorLocation;
		CoveredDistance += Delta.DotProduct(DirToTarget);
		CoveredTime += DeltaSeconds;

		// If we've moved too far, just remove it
		if(CoveredDistance > DistanceUntilDisappearing)
			AcidManager.ReturnToPool(this);

		// If we have exceeded our life time
		// if (Time::GameTimeSeconds > LifeTime)
		// 	AcidManager.ReturnToPool(this);

		// Scale up the projectile as we cover more time
		if (ProjectileParams.ScaleUpDuration > 0.0)
		{
			float ScaleAlpha = Math::Clamp(CoveredTime / ProjectileParams.ScaleUpDuration, 0.0, 1.0);
			SetActorScale3D(Math::Lerp(ProjectileParams.StartScale, ProjectileParams.EndScale, ScaleAlpha));
		}

		// Add gravity when passed drop off point
		if(CoveredDistance > SpraySettings.AcidSprayRange)
			Velocity += FVector::DownVector * SpraySettings.ProjectileDropOffExtraGravity * DeltaSeconds;

		// Actually do the move, and trace to see if we hit anything
		if (!WantedPosition.Equals(ActorLocation))
		{

			if(CoveredTime > SpraySettings.ProjectileCollisionGraceTime)
			{
				FHazeTraceSettings Trace;
				Trace.IgnoreActor(this);
				Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);

				if (ProjectileParams.TraceRadius == 0.0)
				{
					Trace.UseLine();
				}
				else
				{
					Trace.UseSphereShape(
						ProjectileParams.TraceRadius * ActorScale3D.GetMax()
					);
				}

				FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, WantedPosition);

				bool bWasImpact = false;
				FVector ComplexHitLocation;
				FVector ComplexHitNormal;
				FName ComplexHitBoneName;
				FHitResult ComplexHitResult;
				bool bHitComplex = false;

				if(Hit.bBlockingHit)
				{
					const bool bPotentialMetalHit = Hit.Actor.IsA(ANightQueenMetal) 
									|| (HasMeltingComponent(Hit) 
									&& (Hit.Component.IsA(UStaticMeshComponent) || Hit.Component.IsA(UHazeSkeletalMeshComponentBase)));
					
					if(bPotentialMetalHit)
					{
						bHitComplex = Hit.Component.LineTraceComponent(ActorLocation, WantedPosition, true, false, false
						, ComplexHitLocation, ComplexHitNormal, ComplexHitBoneName, ComplexHitResult);

						bWasImpact = bHitComplex;							
					}
					// wasn't metal, don't need complex trace
					else
					{
						bWasImpact = true;
					}
				}
				
				if (bWasImpact)
				{
					SetActorLocationAndRotation(Hit.ImpactPoint, WantedRotation);

					if(bHitComplex)
						ProjectileImpact(ComplexHitResult, true);
					else
						ProjectileImpact(Hit);
				}
				else
				{
					SetActorLocationAndRotation(WantedPosition, WantedRotation);
				}
			}
			else
			{
				SetActorLocationAndRotation(WantedPosition, WantedRotation);
			}
		}
	}

	bool HasMeltingComponent(FHitResult Hit) const
	{
		auto MeltComponent = USummitMeltComponent::Get(Hit.Actor);
		if(MeltComponent != nullptr)
			return true;

		auto MeltPartComp = USummitMeltPartComponent::Get(Hit.Actor);
		if(MeltPartComp != nullptr)
			return true;

		auto DecimatorTopDownMeltComp = USummitDecimatorTopdownMeltComponent::Get(Hit.Actor);
		if(DecimatorTopDownMeltComp != nullptr)
			return true;

		return false;
	}
};
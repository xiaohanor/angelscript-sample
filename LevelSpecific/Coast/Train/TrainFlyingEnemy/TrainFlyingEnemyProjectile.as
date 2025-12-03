UCLASS(Abstract, NotPlaceable)
class ATrainFlyingEnemyProjectile : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UTrainFlyingEnemySubmunition SubmunitionTemplate;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent TrailFX;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDecalComponent TelegraphDecal;

	UPROPERTY()
	UNiagaraSystem ImpactExplosion;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ImpactForceFeedback;

	UTrainFlyingEnemySettings Settings;

	AHazeActor Launcher;
	ACoastTrainCart TargetCart;
	FVector TargetCartOffset;

	FVector StartOffset;
	FVector DestinationOffset;
	FHazeRuntimeSpline Trajectory;
	float CurAlpha = 0.0;

	bool bDeployedSubmunitions = false;
	FRotator SubmunitionBaseRotation;
	TArray<UTrainFlyingEnemySubmunition> Submunitions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UTrainFlyingEnemySettings::GetSettings(Launcher);

		TelegraphDecal.AttachToComponent(TargetCart.RootComponent);
		TelegraphDecal.SetRelativeLocation(DestinationOffset);
		TelegraphDecal.SetRelativeScale3D(FVector(Settings.ProjectileExplosionLength, 2000.0, 256.0));

		Trajectory.AddPoint(StartOffset);
		Trajectory.AddPoint(((StartOffset + DestinationOffset) * 0.5) + FVector(0.0, 0.0, Settings.ProjectileTrajectoryHeight));
		Trajectory.AddPoint(DestinationOffset);

		// Should we use submunitions?
		SubmunitionTemplate.AddComponentVisualsBlocker(this);	
		SubmunitionBaseRotation = Mesh.RelativeRotation;
		if ((Settings.ProjectileSubmunitionDeployFraction < 1.0) && (Settings.ProjectileSubmunitionNumber > 1))
		{
			Submunitions.Reserve(Settings.ProjectileSubmunitionNumber);
			Submunitions.Add(SubmunitionTemplate);
			for (int iSubmunition = 1; iSubmunition < Settings.ProjectileSubmunitionNumber; iSubmunition++)
			{
				UTrainFlyingEnemySubmunition Submunition = UTrainFlyingEnemySubmunition::Create(this);
				Submunition.StaticMesh = SubmunitionTemplate.StaticMesh;
				Submunition.WorldScale3D = SubmunitionTemplate.WorldScale;
				for (int iMaterial = 0; iMaterial < SubmunitionTemplate.GetNumMaterials(); iMaterial++)
				{
					Submunition.SetMaterial(iMaterial, SubmunitionTemplate.GetMaterial(iMaterial));
				}
				Submunition.AddComponentVisualsBlocker(this);
				Submunitions.Add(Submunition);
			}
		}

		UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_Launch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurAlpha += DeltaSeconds / Settings.ProjectileTravelDuration;

		if (CurAlpha >= 1.0)
		{
			// Explode the projectile
			Explode();
			return;
		}

		FTransform CartPosition = TargetCart.CurrentPosition.WorldTransform;
		FVector NewOffset = Trajectory.GetLocation(CurAlpha);
		FVector NewTangent = Trajectory.GetDirection(CurAlpha);

		ActorLocation = CartPosition.TransformPosition(NewOffset);
		ActorRotation = FRotator::MakeFromX(CartPosition.TransformVector(NewTangent));

		if ((CurAlpha > Settings.ProjectileSubmunitionDeployFraction) && (Submunitions.Num() > 1))
		{
			if (!bDeployedSubmunitions)
			{
				for (UTrainFlyingEnemySubmunition Submunition : Submunitions)
				{
					Submunition.RemoveComponentVisualsBlocker(this);
					UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_SubmunitionLaunch(this,
						FTrainFlyingEnemyProjectileSubmunitionParams(Submunition, Submunition.WorldLocation, TargetCart));
				}
				TrailFX.AddComponentVisualsBlocker(this);
				Mesh.AddComponentVisualsBlocker(this);

				UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_DeploySubmunitions(this);
				bDeployedSubmunitions = true;
			}
			float DeployAlpha = (CurAlpha - Settings.ProjectileSubmunitionDeployFraction) / (1.0 - Settings.ProjectileSubmunitionDeployFraction);
			float Spread = -Settings.ProjectileSubmunitionSpread * 0.5 * DeployAlpha;
			float SpreadInterval = Settings.ProjectileSubmunitionSpread * DeployAlpha / float(Submunitions.Num() - 1);
			float PitchSpread = -Settings.ProjectileSubmunitionPitchSpread * DeployAlpha;
			float PitchSpreadInterval = Settings.ProjectileSubmunitionPitchSpread * 2.0 * DeployAlpha / float(Submunitions.Num() - 1); 
			SubmunitionBaseRotation = FRotator(90.0, 0.0, 0.0);
			for (UTrainFlyingEnemySubmunition Submunition : Submunitions)
			{
				FVector SpreadOffset = CartPosition.Rotation.RightVector * Spread;
				Submunition.WorldLocation = ActorLocation + SpreadOffset;
				Submunition.WorldRotation = FRotator(PitchSpread, 0.0, 0.0).Compose(SubmunitionBaseRotation.Compose(ActorRotation));
				Spread += SpreadInterval;
				PitchSpread += PitchSpreadInterval;				
			}
		}
	}

	void Explode()
	{
		FTransform CartPosition = TargetCart.CurrentPosition.WorldTransform;
		bool bDetonation = false;
		FVector Epicenter = CartPosition.TransformPosition(DestinationOffset);
		if (ImpactExplosion != nullptr)
		{
			if (Submunitions.Num() == 0)
			{
				// Main projectile explosion
				UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_SubmunitionImpactExplosion(this,
					FTrainFlyingEnemyProjectileSubmunitionParams(Mesh, Epicenter, TargetCart));
				bDetonation = true;	
			}
			else
			{
				// Separate explosions for each submunition
				float Spread = -Settings.ProjectileSubmunitionSpread * 0.5;
				float SpreadInterval = Settings.ProjectileSubmunitionSpread / float(Submunitions.Num() - 1);
				FHazeTraceSettings Trace;
				Trace.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);
				Trace.UseLine();
				FVector CenterLoc = CartPosition.TransformPosition(DestinationOffset);
				for (UTrainFlyingEnemySubmunition Submunition : Submunitions)
				{
					FVector DetonationLoc = CenterLoc + CartPosition.Rotation.RightVector * Spread;
					FHitResult Hit = Trace.QueryTraceSingle(DetonationLoc + FVector(0.0, 0.0, 20.0), DetonationLoc - FVector(0.0, 0.0, 40.0));
					if (Hit.bBlockingHit)
					{
						UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_SubmunitionImpactExplosion(this,
							FTrainFlyingEnemyProjectileSubmunitionParams(Submunition, Hit.ImpactPoint, TargetCart));
						bDetonation = true;
					}
					else
					{
						UTrainFlyingEnemyProjectileEffectEventHandler::Trigger_SubmunitionMissed(this,
							FTrainFlyingEnemyProjectileSubmunitionParams(Submunition, DetonationLoc, TargetCart));
					}
					Spread += SpreadInterval;
				}
			}
		}

		if (bDetonation)
		{
			FHazeShapeSettings Box;
			Box.InitializeAsBox(FVector(Settings.ProjectileExplosionLength + 20.0, 1500.0, 400.0));

			FTransform BoxTransform;
			BoxTransform.Location = Epicenter + (CartPosition.Rotation.UpVector * 300.0);
			BoxTransform.Rotation = CartPosition.Rotation;

			FVector OriginRelative = DestinationOffset - StartOffset;

			for (auto Player : Game::Players)
			{
				if (Box.IsPointInside(BoxTransform, Player.ActorCenterLocation))
				{
					auto LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);
					FVector LocalForce = Settings.ProjectileLaunchForce;

					// If the enemy is on the left of the train, launch to the right
					if (OriginRelative.Y < 0.0)
						LocalForce.Y *= -1.0;

					FTrainPlayerLaunchParams Launch;
					Launch.LaunchFromCart = TargetCart;
					Launch.ForceDuration = Settings.ProjectileLaunchForceDuration;
					Launch.FloatDuration = Settings.ProjectileLaunchFloatDuration;
					Launch.PointOfInterestDuration = Settings.ProjectileLaunchPointOfInterestDuration;
					Launch.Force = CartPosition.TransformVectorNoScale(LocalForce);
					LaunchComp.TryLaunch(Launch);

					Player.DamagePlayerHealth(Settings.ProjectileDamage);
				}
			}

			float InnerRadius = Settings.ProjectileExplosionLength * 2.0;
			float OuterRadius = InnerRadius * 15.0;

			// Cause a camera shake around the impact
			if (ImpactCameraShake != nullptr)
			{
				for (AHazePlayerCharacter Player : Game::GetPlayers())
					Player.PlayWorldCameraShake(ImpactCameraShake, this, Epicenter, InnerRadius, OuterRadius);
			}

			// Cause force feedback around the impact
			if (ImpactForceFeedback != nullptr)
			{
				ForceFeedback::PlayWorldForceFeedback(ImpactForceFeedback, Epicenter, true, n"TrainEnemyProjectile", InnerRadius, OuterRadius);
			}

			// Impact the train cart's suspension from the explosion
			FVector SuspensionForce = FVector(0.0, 0.0, -500.0);
			TargetCart.AddSuspensionImpulse(SuspensionForce);
		}
		DestroyActor();
	}
}

class UTrainFlyingEnemySubmunition : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";
}

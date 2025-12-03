UCLASS(Abstract, NotPlaceable)
class AWingsuitBossProjectile : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UWingsuitBossSubmunition SubmunitionTemplate;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent TrailFX;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDecalComponent TelegraphDecal;
	default TelegraphDecal.DecalSize = FVector::OneVector;

	UPROPERTY(DefaultComponent, Attach = TelegraphDecal)
	UDecalComponent TelegraphDecalExtra0;
	default TelegraphDecalExtra0.RelativeLocation = FVector(0.0, 2.0, 0.0);
	default TelegraphDecalExtra0.DecalSize = FVector::OneVector;

	UPROPERTY(DefaultComponent, Attach = TelegraphDecal)
	UDecalComponent TelegraphDecalExtra1;
	default TelegraphDecalExtra1.RelativeLocation = FVector(0.0, 4.0, 0.0);
	default TelegraphDecalExtra1.DecalSize = FVector::OneVector;

	UPROPERTY(DefaultComponent, Attach = TelegraphDecal)
	UDecalComponent TelegraphDecalExtra2;
	default TelegraphDecalExtra2.RelativeLocation = FVector(0.0, -2.0, 0.0);
	default TelegraphDecalExtra2.DecalSize = FVector::OneVector;

	UPROPERTY(DefaultComponent, Attach = TelegraphDecal)
	UDecalComponent TelegraphDecalExtra3;
	default TelegraphDecalExtra3.RelativeLocation = FVector(0.0, -4.0, 0.0);
	default TelegraphDecalExtra3.DecalSize = FVector::OneVector;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY()
	UNiagaraSystem ImpactExplosion;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UWingsuitBossSettings Settings;

	ACoastTrainCart TargetCart;

	FVector LaunchOffset;
	FVector DestinationOffset;
	float SideOffset;
	float CurAlpha = 0.0;
	bool bDisarmed = false;

	bool bDeployedSubmunitions = false;
	FRotator SubmunitionBaseRotation;
	TArray<UWingsuitBossSubmunition> Submunitions;

	int NumSpentSubMunitions = 0;
	bool bHasImpact;
	TArray<AHazePlayerCharacter> AvailableTargets;
	FVector CurveTangent;	
	FVector ApexControl;
	FVector DestControl;
	float Speed;
	FVector PrevOffset;
	float StartExpiringTime;
	bool bTelegraphing = false;

	TArray<UDecalComponent> TelegraphDecals;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SubmunitionTemplate.Initialize();	
		TrailFX.AddComponentVisualsBlocker(this);
		Mesh.AddComponentVisualsBlocker(this);
		bTelegraphing = false;
		
		GetComponentsByClass(TelegraphDecals);
		for (UDecalComponent Decal : TelegraphDecals)
		{
			Decal.AddComponentVisualsBlocker(this);
		}

		WingsuitBossProjectileDevToggles::DebugDraw.MakeVisible();
		WingsuitBossProjectileDevToggles::SkipPlayerPush.MakeVisible();
	}

	void Launch(ACoastTrainCart Cart, FVector StartOffset, FVector DestOffset, bool bLeft)
	{
		Settings = UWingsuitBossSettings::GetSettings(ProjectileComp.Launcher);

		CurAlpha = 0.0;
		TargetCart = Cart;
		LaunchOffset = StartOffset;
		DestinationOffset = DestOffset;
		SideOffset = (bLeft ? 1.0 : -1.0) * Settings.ProjectileTrajectoryWidth;
		ApexControl = (LaunchOffset * 0.5 + DestinationOffset * 0.5) + FVector(0.0, SideOffset, Settings.ProjectileTrajectoryHeight);
		DestControl = DestinationOffset + FVector(0.0, SideOffset * 0.15, 1000.0);
		Speed = BezierCurve::GetLength_2CP(LaunchOffset, ApexControl, DestControl, DestinationOffset) / Settings.ProjectileFlightDuration;
		PrevOffset = LaunchOffset;

		ActorLocation = Cart.ActorTransform.TransformPosition(LaunchOffset);
		CurveTangent = (ApexControl - LaunchOffset).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(Cart.ActorTransform.TransformVector(CurveTangent));

		// Offset decal backwards a bit since delayed submunitions may hit slightly behind where we aim
		FVector Lag = FVector(Settings.ProjectileSubmunitionLagInterval * 0.5, 0.0, 0.0);
		TelegraphDecal.AttachToComponent(TargetCart.MeshRootAbsoluteComp);
		TelegraphDecal.SetRelativeLocation(DestinationOffset - Lag); 
		TelegraphDecal.SetWorldScale3D(FVector(2000.0, Settings.ProjectileExplosionLength, Settings.ProjectileExplosionLength));
		TelegraphDecal.SetWorldRotation(FRotator::MakeFromZX(TargetCart.MeshRootAbsoluteComp.ForwardVector, FVector::UpVector));
		if (!bTelegraphing)
		{
			for (UDecalComponent Decal : TelegraphDecals)
			{
				Decal.RemoveComponentVisualsBlocker(this);
			}
		}
		bTelegraphing = true;

		TrailFX.RemoveComponentVisualsBlocker(this);
		Mesh.RemoveComponentVisualsBlocker(this);

		// Should we use submunitions?
		bDeployedSubmunitions = false;
		SubmunitionBaseRotation = Mesh.RelativeRotation;
		if ((Settings.ProjectileSubmunitionDeployFraction < 1.0) && (Settings.ProjectileSubmunitionNumber > 1))
		{
			Submunitions.Reserve(Settings.ProjectileSubmunitionNumber);
			if (Submunitions.Num() == 0)
				Submunitions.Add(SubmunitionTemplate);
			for (int iSubmunition = Submunitions.Num(); iSubmunition < Settings.ProjectileSubmunitionNumber; iSubmunition++)
			{
				UWingsuitBossSubmunition Submunition = UWingsuitBossSubmunition::Create(this, FName(this.Name + "Submunition" + iSubmunition));
				Submunition.StaticMesh = SubmunitionTemplate.StaticMesh;
				Submunition.WorldScale3D = SubmunitionTemplate.WorldScale;
				for (int iMaterial = 0; iMaterial < SubmunitionTemplate.GetNumMaterials(); iMaterial++)
				{
					Submunition.SetMaterial(iMaterial, SubmunitionTemplate.GetMaterial(iMaterial));
				}
				Submunition.Initialize();
				Submunitions.Add(Submunition);
			}
			// TODO: Currently we cannot tweak number of submunitions down, only up, fix if needed
		}

		NumSpentSubMunitions = 0;
		bHasImpact = false;
		AvailableTargets = Game::Players;
		StartExpiringTime = Time::GameTimeSeconds + Settings.ProjectileFlightDuration * 2.0; // Backup time in case we fail to hit anything

		FWingsuitBossProjectileLaunchParams LaunchParams;
		LaunchParams.Launcher = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);
		LaunchParams.LaunchLocation = ActorLocation; 
		UWingsuitBossProjectileEffectEventHandler::Trigger_Launch(this, LaunchParams);
		UWingsuitBossRocketEffectHandler::Trigger_OnRocketFired(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Settings == nullptr)
			return;

		// Note that we keep updating position while expiring so effects follow along with train and don't snap to a stop
		if (ShouldStartExpiring())
			StartExpiringTime = Time::GameTimeSeconds;
		if (Time::GameTimeSeconds > StartExpiringTime + 3.0)
			ProjectileComp.Expire();

		CurAlpha += DeltaTime / Settings.ProjectileFlightDuration;
		if (CurAlpha > 0.7)
		   	CurAlpha += (CurAlpha - 0.7) * 2.0 * DeltaTime; // Speed up at end to compensate for curve slowdown

		FTransform CartPosition = TargetCart.MeshRootAbsoluteComp.WorldTransform;
		FVector NewOffset;
		FVector WorldForward;
		float FollowCurveThreshold = 0.95;
		if (CurAlpha < FollowCurveThreshold)
		{
			// Move along curve
			NewOffset = BezierCurve::GetLocation_2CP(LaunchOffset, ApexControl, DestControl, DestinationOffset, CurAlpha);
			CurveTangent = BezierCurve::GetDirection_2CP(LaunchOffset, ApexControl, DestControl, DestinationOffset, CurAlpha);
			WorldForward = CartPosition.TransformVector(CurveTangent);
			if (DeltaTime > 0.0)
				Speed = CartPosition.TransformVector(NewOffset - PrevOffset).Size() / DeltaTime;
		}
		else
		{
			// Continue along ending tangent until all submunition is spent
			FVector LocalDir = CurveTangent.SlerpTowards(-FVector::UpVector, Math::EaseIn(0.0, 1.0, Math::Min(1.0, (CurAlpha - FollowCurveThreshold) * 0.25), 3.0));
			NewOffset = PrevOffset + LocalDir * Speed * DeltaTime;
			WorldForward = CartPosition.TransformVector(LocalDir);
		}
		ActorLocation = CartPosition.TransformPosition(NewOffset);
		ActorRotation = FRotator::MakeFromX(WorldForward);
		PrevOffset = NewOffset;

		if ((CurAlpha > Settings.ProjectileSubmunitionDeployFraction) && (Submunitions.Num() > 1))
		{
			if (!bDeployedSubmunitions)
			{
				for (UWingsuitBossSubmunition Submunition : Submunitions)
				{
					Submunition.Launch();
					UWingsuitBossProjectileEffectEventHandler::Trigger_SubmunitionLaunch(this,
						FWingsuitBossProjectileSubmunitionParams(Submunition, Submunition.WorldLocation, TargetCart));
				}

				// Set up lag increasing at edges for a nice V-formation
				float PrevLag = 0.0;
				for (int i = Math::IntegerDivisionTrunc(Submunitions.Num(), 2) - 1; i >= 0; i--)
				{
					Submunitions[i].Lag = PrevLag + Settings.ProjectileSubmunitionLagInterval * Math::RandRange(0.9, 1.1);
					Submunitions[Submunitions.Num()-i-1].Lag = Submunitions[i].Lag + Settings.ProjectileSubmunitionLagInterval * Math::RandRange(0.9, 1.1);
					PrevLag = Submunitions[Submunitions.Num()-i-1].Lag;
				}

				TrailFX.AddComponentVisualsBlocker(this);
				Mesh.AddComponentVisualsBlocker(this);

				UWingsuitBossProjectileEffectEventHandler::Trigger_DeploySubmunitions(this);
				bDeployedSubmunitions = true;
			}
			float DeployAlpha = Math::Min(1.0, (CurAlpha - Settings.ProjectileSubmunitionDeployFraction) / (1.0 - Settings.ProjectileSubmunitionDeployFraction));
			float Spread = -Settings.ProjectileSubmunitionSpread * 0.5 * DeployAlpha;
			float SpreadInterval = Settings.ProjectileSubmunitionSpread * DeployAlpha / float(Submunitions.Num() - 1);
			float PitchSpread = -Settings.ProjectileSubmunitionPitchSpread * DeployAlpha;
			float PitchSpreadInterval = Settings.ProjectileSubmunitionPitchSpread * 2.0 * DeployAlpha / float(Submunitions.Num() - 1); 
			for (UWingsuitBossSubmunition Submunition : Submunitions)
			{
				FVector SpreadOffset = CartPosition.Rotation.RightVector * Spread;
				FVector Lag = WorldForward * Submunition.Lag * DeployAlpha;
				Submunition.WorldLocation = ActorLocation + SpreadOffset - Lag;
				Submunition.WorldRotation = FRotator(PitchSpread, 0.0, 0.0).Compose(SubmunitionBaseRotation.Compose(ActorRotation));
				Spread += SpreadInterval;
				PitchSpread += PitchSpreadInterval;	

				if (!Submunition.bSpent)
				{
					FVector ImpactLocation;
					if ((CurAlpha > 0.95) && Submunition.ShouldExplode(ImpactLocation))
					{
						Submunition.Explode(ImpactLocation, TargetCart, TelegraphDecal.RelativeLocation.X, bDisarmed, Settings, DamageEffect, DeathEffect, AvailableTargets);
						NumSpentSubMunitions++;
						if (!bHasImpact)
							FirstImpact();
					}
					else if ((CurAlpha > 1.5) && Submunition.ShouldFizzle(TargetCart))
					{
						Submunition.Fizzle(TargetCart);
						NumSpentSubMunitions++;
					}
				}

				Submunition.PrevWorldLocation = Submunition.WorldLocation;	
			}
		}

		if (ShouldStopTelegraphing())
		{
			for (UDecalComponent Decal : TelegraphDecals)
			{
				Decal.AddComponentVisualsBlocker(this);
			}
			bTelegraphing = false;
		}

		if (WingsuitBossProjectileDevToggles::DebugDraw.IsEnabled())
		{
			BezierCurve::DebugDraw_2CP(CartPosition.TransformPosition(LaunchOffset), CartPosition.TransformPosition(ApexControl), CartPosition.TransformPosition(DestControl), CartPosition.TransformPosition(DestinationOffset), FLinearColor::Red, 5.0);				
			Debug::DrawDebugLine(TargetCart.ActorLocation, ActorLocation, FLinearColor::Yellow, 5.0);
		}
	}

	void FirstImpact()
	{
		FTransform CartPosition = TargetCart.MeshRootAbsoluteComp.WorldTransform;
		FVector Epicenter = CartPosition.TransformPosition(DestinationOffset);
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

	bool ShouldStartExpiring() const
	{
		if (Time::GameTimeSeconds > StartExpiringTime)
			return false; // Already expiring
		if (NumSpentSubMunitions < Submunitions.Num())
			return false;
		if (Submunitions.Num() == 0)
			return (CurAlpha > 1.0);
		return true;
	}

	bool ShouldStopTelegraphing() const
	{
		if (!bTelegraphing)
			return false;
		if (Time::GameTimeSeconds > StartExpiringTime + 0.1)
			return true;
		if (ActorLocation.Z < TargetCart.MeshRootAbsoluteComp.WorldLocation.Z - 800.0)
			return true;
		return false;
	}
}

class UWingsuitBossSubmunition : UStaticMeshComponent
{
	default CollisionProfileName = n"NoCollision";

	float Lag = 0.0;
	FVector PrevWorldLocation;
	bool bSpent;
	AHazeActor HazeOwner;

	void Initialize()
	{
		HazeOwner  = Cast<AHazeActor>(Owner);
		Lag = 0.0;
		bSpent = false;
		AddComponentVisualsBlocker(this);
	}

	void Launch()
	{
		Lag = 0.0;
		bSpent = false;
		RemoveComponentVisualsBlocker(this);
	}

	bool ShouldExplode(FVector& OutImpactLocation)
	{
		if (bSpent)
			return false;
		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.UseLine();
		FVector ProbeOffset = RightVector * 100.0;
		FHitResult Obstruction = Trace.QueryTraceSingle(PrevWorldLocation + ProbeOffset, WorldLocation + ProbeOffset);
		if (!Obstruction.bBlockingHit)
			return false;	
		OutImpactLocation = Obstruction.ImpactPoint;	
		return true;
	}

	bool ShouldFizzle(ACoastTrainCart TargetCart)
	{
		if (bSpent)
			return false;

		// Fizzle when far enough below target cart
		if (WorldLocation.Z < TargetCart.MeshRootAbsoluteComp.WorldLocation.Z - 1200.0)	
			return true;
		return false;
	}

	void Explode(FVector ImpactLocation, ACoastTrainCart TargetCart, float DangerPosAlongCart, bool bDisarmed, UWingsuitBossSettings Settings,
	 			 TSubclassOf<UDamageEffect> DamageEffect, TSubclassOf<UDeathEffect> DeathEffect, 
				 TArray<AHazePlayerCharacter>& InOutAvailableTargets)
	{
		bSpent = true;
		AddComponentVisualsBlocker(this);

		UWingsuitBossProjectileEffectEventHandler::Trigger_SubmunitionImpactExplosion(HazeOwner,
				FWingsuitBossProjectileSubmunitionParams(this, ImpactLocation, TargetCart));

		if (bDisarmed)
			return;

		// We always want to center danger zone on telegraph decal even if effect will be slightly off
		FTransform BoxTransform;
		FTransform CartTransform = TargetCart.MeshRootAbsoluteComp.WorldTransform;
		FVector ImpactLocal = CartTransform.InverseTransformPosition(ImpactLocation);
		ImpactLocal.X = DangerPosAlongCart + 20.0; // Shift slightly forward so back edge of danger zone is safer than front
		BoxTransform.Location = CartTransform.TransformPosition(ImpactLocal);
		BoxTransform.Rotation = CartTransform.Rotation;
		FHazeShapeSettings Box;
		Box.InitializeAsBox(FVector(Settings.ProjectileExplosionLength, (800.0 / Math::Max(1.0, float(Settings.ProjectileSubmunitionNumber))), 500.0));

		for (int i = InOutAvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = InOutAvailableTargets[i];
			if (!Box.IsPointInside(BoxTransform, Player.ActorCenterLocation))
				continue;

			// Player damage is replicated separately		
			Player.DamagePlayerHealth(Settings.ProjectileDamage, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
			
			// Player can only be hit by a single submunition
			InOutAvailableTargets.RemoveAt(i);
			
			if (WingsuitBossProjectileDevToggles::SkipPlayerPush.IsEnabled())
				continue;
			
			// Launch player away from train (also replicated separately)
			auto LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);
			FVector LocalForce = Settings.ProjectileLaunchForce;

			// If the enemy is on the left of the train, launch to the right
			FTransform CartPosition = TargetCart.MeshRootAbsoluteComp.WorldTransform;
			if (CartPosition.InverseTransformPosition(Player.ActorLocation).Y < 0.0)
				LocalForce.Y *= -1.0;

			FTrainPlayerLaunchParams Launch;
			Launch.LaunchFromCart = TargetCart;
			Launch.ForceDuration = Settings.ProjectileLaunchForceDuration;
			Launch.FloatDuration = Settings.ProjectileLaunchFloatDuration;
			Launch.PointOfInterestDuration = Settings.ProjectileLaunchPointOfInterestDuration;
			Launch.Force = CartPosition.TransformVectorNoScale(LocalForce);
			LaunchComp.TryLaunch(Launch);
		}
	}

	void Fizzle(ACoastTrainCart TargetCart)
	{
		bSpent = true;
		AddComponentVisualsBlocker(this);
		UWingsuitBossProjectileEffectEventHandler::Trigger_SubmunitionMissed(HazeOwner,
			FWingsuitBossProjectileSubmunitionParams(this, WorldLocation, TargetCart));
	}
}

namespace WingsuitBossProjectileDevToggles
{
	const FHazeDevToggleBool DebugDraw;
	const FHazeDevToggleBool SkipPlayerPush;
}
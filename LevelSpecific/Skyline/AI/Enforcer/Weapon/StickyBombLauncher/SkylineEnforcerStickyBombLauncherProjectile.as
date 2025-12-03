UCLASS(Abstract)
class ASkylineEnforcerStickyBombLauncherProjectile : AHazeActor
{
	private AHazeActor InternalOwner;

	AHazeActor GetOwner() property
	{
		return InternalOwner;
	}

	void SetOwner(AHazeActor InOwner) property
	{
		InternalOwner = InOwner;
		Settings = USkylineEnforcerStickyBombLauncherSettings::GetSettings(InternalOwner);
	}

	USkylineEnforcerStickyBombLauncherSettings Settings;
	float LandedTime;
	FHitResult LandedHitResult;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 0;
	default ProjectileComp.TraceType = ETraceTypeQuery::WorldGeometry;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USphereComponent DamageSphere;

	UPROPERTY(DefaultComponent)
	USceneComponent DangerZoneRoot;
	default DangerZoneRoot.RelativeLocation = FVector(0.0, 0.0, 10.0);

	UPROPERTY(DefaultComponent, Attach = "DangerZoneRoot")
	UStaticMeshComponent DangerZoneDisc;

	UPROPERTY(DefaultComponent, Attach = "DangerZoneRoot")
	UStaticMeshComponent DangerZoneTorus;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 2.0;

	UPROPERTY(EditAnywhere)
	float SlingSpeed = 5000.0;

	UPROPERTY(EditAnywhere)
	float GrabbedDrag = 1.0;

	UPROPERTY(EditAnywhere)
	float ThrownDrag = 1.0;

	// Set to 0 for no gravity
	UPROPERTY(EditAnywhere)
	float Gravity = 0.0;

	private FVector OriginalScale;
	private float CurrentScale = 0;

	ASkylineJetpackCombatZoneManager BillboardManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		OriginalScale = DangerZoneRoot.GetWorldScale();
		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();
	}

	UFUNCTION()
	private void OnReset()
	{
		LandedTime = 0;
		CurrentScale = 0;
		DangerZoneRoot.SetWorldScale3D(OriginalScale);
		DetachRootComponentFromParent(true);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Settings == nullptr)
			return;

		if (!ProjectileComp.bIsLaunched)
			return;			

		if(LandedTime != 0)
		{
			// Lerp the scale
			CurrentScale = Math::Min(1, CurrentScale + DeltaTime * 2.0);
			FVector Scale = FVector(CurrentScale, CurrentScale, CurrentScale);
			DangerZoneRoot.SetWorldScale3D(Scale);

			FSkylineEnforcerStickyBombImpactData Data;
			Data.HitResult = LandedHitResult;
			USkylineEnforcerStickyBombProjectileEffectHandler::Trigger_OnImpact(this, Data);

			if(Time::GetGameTimeSince(LandedTime) > Settings.StickyBombDuration)
			{
				USkylineEnforcerStickyBombProjectileEffectHandler::Trigger_OnExplode(this, Data);

				ProjectileComp.Expire();

				for(AHazePlayerCharacter Player: Game::Players)
				{
					if(!Player.ActorLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius))
						continue;
					auto PlayerHealthComp = UPlayerHealthComponent::Get(Player);
					if (PlayerHealthComp != nullptr)
						PlayerHealthComp.DamagePlayer(Settings.StickyBombDamagePlayer, nullptr, nullptr);
				}

				if (BillboardManager.FauxPhysicsRoot != nullptr)
					FauxPhysics::ApplyFauxImpulseToActorAt(BillboardManager.FauxPhysicsRoot, Owner.ActorCenterLocation, -BillboardManager.ActorUpVector * Settings.BillboardBombExplosionForce);
			}
			return;
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;
			if (Controller.HasControl() && ProjectileComp.IsSignificantImpact(Hit))	
			{
				// TODO: This is deprecated, remove after uxr
				if (IsObjectNetworked())
					CrumbImpact(Hit); 
				else
					LauncherCrumbImpact(Hit);
			}
			else
			{
				// Visual impact only
				LandedTime = Time::GetGameTimeSeconds();
				LandedHitResult = Hit;
				AttachToActor(BillboardManager.GetNearestIntactBillboardZone(ActorLocation), NAME_None, EAttachmentRule::KeepWorld);
				OnLocalImpact(Hit);
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		ProjectileComp.Impact(Hit);
		LandedTime = Time::GetGameTimeSeconds();
		LandedHitResult = Hit;
		AttachToActor(BillboardManager.GetNearestIntactBillboardZone(ActorLocation), NAME_None, EAttachmentRule::KeepWorld);
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);	
		LaunchingWeapon.CrumbProjectileImpact(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
		OnLocalImpact(Hit);
		LandedTime = Time::GetGameTimeSeconds();
		LandedHitResult = Hit;
		AttachToActor(BillboardManager.GetNearestIntactBillboardZone(ActorLocation), NAME_None, EAttachmentRule::KeepWorld);
	}
	
	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}


}
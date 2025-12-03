UCLASS(Abstract)
class ASkylineEnforcerBlobLauncherProjectile : AHazeActor
{
	private AHazeActor InternalOwner;

	AHazeActor GetOwner() property
	{
		return InternalOwner;
	}

	void SetOwner(AHazeActor InOwner) property
	{
		InternalOwner = InOwner;
		Settings = UEnforcerHoveringSettings::GetSettings(InternalOwner);
	}

	UEnforcerHoveringSettings Settings;
	int Division;
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
	UBasicAIProjectileLauncherComponent BlobLauncher;

	UPROPERTY(DefaultComponent)
	USphereComponent DamageSphere;

	// UPROPERTY(DefaultComponent)
	// UGravityWhipTargetComponent GravityWhipTargetComponent;

	// UPROPERTY(DefaultComponent)
	// UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

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

	FVector OriginalMeshScale;
	FHazeAcceleratedVector ScaleAcc;
	bool bGrabbed;
	bool bThrown;
	AActor Thrower;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");	
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");
		Movement = MovementComponent.SetupSweepingMovementData();
		OriginalMeshScale = Mesh.GetRelativeScale3D();
		ScaleAcc.Value = OriginalMeshScale;
	}

	UFUNCTION()
	private void OnReset()
	{
		LandedTime = 0;
		Division = 0;
		Mesh.SetRelativeScale3D(OriginalMeshScale);
		ScaleAcc.Value = OriginalMeshScale;
		bThrown = false;
		bGrabbed = false;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Settings == nullptr)
			return;

		if (!ProjectileComp.bIsLaunched)
			return;			

		if(bGrabbed)
		{
			Grabbed();
			if(bThrown)
				Thrown(DeltaTime);
			return;
		}

		if(LandedTime != 0)
		{
			Mesh.SetRelativeScale3D(FVector(3.0));
			if(HasControl() && (Division < Settings.BlobSplits))
				CrumbSplit();
			
			FBasicAiProjectileOnImpactData Data;
			Data.HitResult = LandedHitResult;
			UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
			ProjectileComp.Expire();

			for(AHazePlayerCharacter Player: Game::Players)
			{
				if(!Player.ActorLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius))
					continue;
				auto PlayerHealthComp = UPlayerHealthComponent::Get(Player);
				if (PlayerHealthComp != nullptr)
					PlayerHealthComp.DamagePlayer(Settings.BlobDamagePlayer, nullptr, nullptr);
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
				OnLocalImpact(Hit);
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	private void Grabbed()
	{
	}

	private void Thrown(float DeltaTime)
	{
		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			FVector Acceleration = Force * 1.0
								- MovementComponent.Velocity * (bThrown ? ThrownDrag : GrabbedDrag)
								+ FVector::UpVector * Gravity * (bThrown ? 1.0 : 0.0);
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);
		}	

		if(MovementComponent.Velocity.IsNearlyZero(DeltaTime))
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe);
		Trace.UseLine();
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + MovementComponent.Velocity * DeltaTime);	
		if(!Hit.bBlockingHit)
			return;

		UHazeTeam Team = HazeTeam::GetTeam(SkylineGeckoTags::SkylineGeckoTeam);

		if(Team != nullptr)
		{
			for(AHazeActor Member: Team.GetMembers())
			{
				if (Member == nullptr)
					continue;
				if(Member.ActorLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius * 1.5))
					USkylineGeckoBlobResponseComponent::GetOrCreate(Member).OnHit.Broadcast();
			}
		}

		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, Data);
		ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		ProjectileComp.Impact(Hit);
		LandedTime = Time::GetGameTimeSeconds();
		LandedHitResult = Hit;
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
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSplit()
	{
		if(!ensure(Division < Settings.BlobSplits))
			return;

		for(int i = 0; i < Settings.BlobDivision; i++)
		{
			LaunchSplit(((360.0 / Settings.BlobDivision) * i) + Math::RandRange(-Settings.BlobDivisionAngleRandomization/2, Settings.BlobDivisionAngleRandomization/2));
		}
	}

	private void LaunchSplit(float Degrees)
	{
		// Launch projectile at predicted location
		FVector WeaponLoc = BlobLauncher.WorldLocation;
		FVector Direction = ActorForwardVector.RotateAngleAxis(Degrees, ActorUpVector);
		float Range = Math::RandRange(Settings.BlobDivisionMinRange,Settings.BlobDivisionMaxRange);
		FVector TargetLoc = WeaponLoc + Direction * Range;
		FVector Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(BlobLauncher.LaunchLocation, TargetLoc, Settings.BlobGravity, Settings.BlobDivisionLaunchSpeed, ActorUpVector);
		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(Velocity, FRotator::ZeroRotator);
		auto Blob = Cast<ASkylineEnforcerBlobLauncherProjectile>(Projectile.Owner);
		Projectile.Gravity = Settings.BlobGravity;
		Projectile.UpVector = ActorUpVector;
		Blob.SetActorRotation(FRotator::MakeFromZ(ActorUpVector));
		Blob.Owner = Owner;
		Blob.Division = Division+1;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}

	UFUNCTION()
	void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
		Mesh.SetRelativeScale3D(OriginalMeshScale);
	}

	UFUNCTION()
	void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		bThrown = true;
		// GravityWhipTargetComponent.Disable(this);
		SetActorVelocity(Impulse.GetSafeNormal() * SlingSpeed);
	}
}
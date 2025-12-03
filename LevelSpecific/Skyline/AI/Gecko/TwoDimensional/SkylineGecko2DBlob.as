UCLASS(Abstract)
class ASkylineGecko2DBlob : AHazeActor
{
	private AHazeActor InternalOwner;

	AHazeActor GetOwner() property
	{
		return InternalOwner;
	}

	void SetOwner(AHazeActor InOwner) property
	{
		InternalOwner = InOwner;
		GeckoSettings = USkylineGeckoSettings::GetSettings(InternalOwner);
	}

	USkylineGeckoSettings GeckoSettings;
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

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileLauncherComponent BlobLauncher;

	UPROPERTY(DefaultComponent)
	USphereComponent DamageSphere;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

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
		GravityWhipTargetComponent.Enable(this);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(GeckoSettings == nullptr)
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
			if(HasControl() && (Division < GeckoSettings.BlobSplits))
				CrumbSplit(ProjectileComp.Target);
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
					PlayerHealthComp.DamagePlayer(GeckoSettings.BlobDamagePlayer, nullptr, nullptr);
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
		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			for (auto& Grab : GravityWhipResponseComponent.Grabs)
				Force += Grab.TargetComponent.ConsumeForce();

			FVector Acceleration = Force * 1.0
								- MovementComponent.Velocity * (bThrown ? ThrownDrag : GrabbedDrag)
								+ FVector::UpVector * Gravity * (bThrown ? 1.0 : 0.0);
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);
		}	
	}

	private void Thrown(float DeltaTime)
	{
		if(MovementComponent.Velocity.IsNearlyZero(DeltaTime))
			return;

		FHitResult Hit;
		UHazeTeam Team = HazeTeam::GetTeam(SkylineGeckoTags::SkylineGeckoTeam);
		if(Team != nullptr)
		{
			for(AHazeActor Gecko: Team.GetMembers())
			{
				if (Gecko == nullptr)
					continue;
				if (Gecko.IsActorDisabled())
					continue;
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Gecko);
				if ((HealthComp == nullptr) || HealthComp.IsDead())
					continue;
				
				// Sideview, so project projectile onto plane through gecko with Zoes view forward as normal
				FVector GeckoPlaneLoc = ActorLocation.PointPlaneProject(Gecko.ActorLocation, Game::Zoe.ViewRotation.Vector());
				if(Gecko.ActorLocation.IsWithinDist(GeckoPlaneLoc, DamageSphere.SphereRadius))
				{
					Hit.bBlockingHit = (true);
					Hit.Actor = Gecko;
					Hit.Location = ActorLocation;
					Hit.ImpactPoint = GeckoPlaneLoc;
					USkylineGeckoBlobResponseComponent::GetOrCreate(Gecko).OnHit.Broadcast();
				}
			}
		}

		if (!Hit.bBlockingHit)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe);
			Trace.UseLine();
			Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + MovementComponent.Velocity * DeltaTime);	
			if(!Hit.bBlockingHit)
				return;
		}

		// Hit!
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

	const float SplitDegreesRange = 150;
	const int BlobDivision = 6;
	const float BlobDivisionLaunchSpeed = 800.0;

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSplit(AHazeActor Target)
	{
		// TODO: Network so we can't split from both impact and whip grab
		for(int i = 0; i < BlobDivision; i++)
		{
			LaunchSplit(Target, (SplitDegreesRange * 0.5) - ((SplitDegreesRange / BlobDivision) * i)); 
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbGrabSplits(AHazeActor Target, UGravityWhipUserComponent Grabber)
	{
		// TODO: Network so we can't split from both impact and whip grab
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(this, FBasicAiProjectileOnImpactData());
		ProjectileComp.Expire();

		TArray<UGravityWhipTargetComponent> GrabbableSplits;
		for(int i = 0; i < BlobDivision; i++)
		{
			ASkylineGecko2DBlob SplitBlob = LaunchSplit(Target, (SplitDegreesRange * 0.5) - ((SplitDegreesRange / BlobDivision) * i)); 
			GrabbableSplits.Add(SplitBlob.GravityWhipTargetComponent);
		}
		Grabber.Grab(GrabbableSplits);
	}

	private ASkylineGecko2DBlob LaunchSplit(AHazeActor Target, float Degrees)
	{
		// Launch projectile at predicted location
		FVector ScatterAxis = ActorForwardVector;
		if (Target != nullptr)
		{
			auto SplineLockComp = UPlayerSplineLockComponent::Get(Target);
			if ((SplineLockComp != nullptr) && (SplineLockComp.CurrentSpline != nullptr))
			 	ScatterAxis = SplineLockComp.CurrentSpline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation).Rotation.RightVector;
			else
				ScatterAxis = ActorUpVector.CrossProduct((Target.ActorLocation - ActorLocation).ConstrainToPlane(Target.ActorUpVector).GetSafeNormal());
		}
		FVector Direction = ActorUpVector.RotateAngleAxis(Degrees, ScatterAxis);
		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(Direction * BlobDivisionLaunchSpeed, FRotator::ZeroRotator);
		auto Blob = Cast<ASkylineGecko2DBlob>(Projectile.Owner);
		Projectile.Gravity = Division == 0 ? GeckoSettings.BlobGravity : GeckoSettings.BlobGravity * 1.25;
		Projectile.UpVector = ActorUpVector;
		Blob.SetActorRotation(FRotator::MakeFromZ(ActorUpVector));
		Blob.Owner = InternalOwner;
		Blob.Division = Division+1;
		return Blob;
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
		if (UserComponent.HasControl() && (Division < GeckoSettings.BlobSplits))
			CrumbGrabSplits(ProjectileComp.Target, UserComponent);
	}

	UFUNCTION()
	void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		bThrown = true;
		GravityWhipTargetComponent.Disable(this);
		SetActorVelocity(Impulse.GetSafeNormal() * SlingSpeed);
	}
}
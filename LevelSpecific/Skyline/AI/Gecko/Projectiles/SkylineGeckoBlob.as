UCLASS(Abstract)
class ASkylineGeckoBlob : AHazeActor
{
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
	UBasicAINetworkedProjectileLauncherComponent BlobLauncher;

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

	private AHazeActor Owner;
	USkylineGeckoSettings Settings;

	float OutsideYawSign = 0.0;
	float SplitYaw = 0.0;
	int RemainingSplits = 0;
	FHitResult LandedHitResult;

	USimpleMovementData Movement;

	// After this time we automatically expire
	float InertTime = 2.0;

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
	bool bInert;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");
		Movement = MovementComponent.SetupSimpleMovementData();
		OriginalMeshScale = Mesh.GetRelativeScale3D();
		ScaleAcc.Value = OriginalMeshScale;
		SetInert();
		SetActorTickEnabled(false);
	}

	void Launch(UBasicAINetworkedProjectileLauncherComponent Launcher, int Splits, bool bOriginal)
	{
		BlobLauncher = Launcher;
		Owner = Cast<AHazeActor>(Launcher.Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		RemainingSplits = Splits;
		Mesh.SetRelativeScale3D(OriginalMeshScale);
		ScaleAcc.Value = OriginalMeshScale;
		bThrown = false;
		bGrabbed = false;
		GravityWhipTargetComponent.Enable(this);
		SplitYaw = Settings.BlobSplitYaw * 0.5;
		InertTime = Time::GameTimeSeconds + Settings.BlobBounceDuration;
		Mesh.RemoveComponentVisualsBlocker(this);
		RemoveActorCollisionBlock(this);
		SetActorTickEnabled(true);
		bInert = false;
		OutsideYawSign = 0.0;
		if (bOriginal)
			USkylineGeckoBlobEffectHandler::Trigger_OnLaunch(this);
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

		if (Time::GameTimeSeconds > InertTime)
		{
			if (!bInert && HasControl())
				CrumbExplode(); // We've been bouncing long enough
			if (Time::GameTimeSeconds > InertTime + Settings.BlobExpirationDelay)
				ProjectileComp.Expire();
			return;
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		FVector NewLoc = ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit);
		if (ShouldExplode(Hit))
		{
			SetActorLocation(NewLoc);
			CrumbExplode(); 
			return;
		}
		if (Hit.bBlockingHit)
		{
			// Bounce and/or split
			ProjectileComp.Velocity = ProjectileComp.Velocity.GetReflectionVector(Hit.ImpactNormal) * Settings.BlobBounceElasticity;
			ProjectileComp.Velocity.Z = Math::Min(1200.0, ProjectileComp.Velocity.Z); 
			NewLoc += ProjectileComp.Velocity * DeltaTime * (1.0 - Hit.Time);
			NewLoc += Hit.ImpactNormal * 0.1; // Make sure we don't get stuck in surface
			if (HasControl() && RemainingSplits > 0)
				CrumbSplit();
			USkylineGeckoBlobEffectHandler::Trigger_OnBounce(this, FGeckoBlobImpactData(Hit));
		}

		SetActorLocation(NewLoc);
	}

	bool ShouldExplode(FHitResult Hit)
	{
		if (Hit.bBlockingHit) 
		{
			if ((Hit.ImpactNormal.Z < 0.707) && HasControl())
				return true;	
			AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
			if ((HitPlayer != nullptr) && HitPlayer.HasControl())
				return true;
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > 0.5)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if(Player.ActorCenterLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius * 0.8))
					return true;
			}
		}
		return false;
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
					Hit.bBlockingHit = true;
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
		USkylineGeckoBlobEffectHandler::Trigger_OnImpactWhenThrownByWhip(this, FGeckoBlobImpactData(Hit));

		SetInert();
	}

	void CrumbExplode()
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(!Player.ActorLocation.IsWithinDist(ActorLocation, DamageSphere.SphereRadius))
				continue;
			auto PlayerHealthComp = UPlayerHealthComponent::Get(Player);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(Settings.BlobDamagePlayer, nullptr, nullptr);
		}
		SetInert();
	
		USkylineGeckoBlobEffectHandler::Trigger_OnExplode(this);
	}

	void SetInert()
	{
		bInert = true;
		bGrabbed = false;
		bThrown = false;
		InertTime = Time::GameTimeSeconds;
		Mesh.AddComponentVisualsBlocker(this);
		AddActorCollisionBlock(this);
		GravityWhipTargetComponent.Disable(this);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbSplit()
	{
		if (RemainingSplits == 0)
			return; // Already split from some other source

		// Spawn split
		FVector SplitVelocity = ProjectileComp.Velocity.RotateAngleAxis(-SplitYaw, FVector::UpVector);
		if (OutsideYawSign == Math::Sign(SplitYaw))
			SplitVelocity *= Settings.BlobSplitSlowdown; // Insize splits slow down
		ASkylineGeckoBlob SplitBlob = Split(SplitVelocity); 
		SplitBlob.SplitYaw = -SplitYaw * 0.8;
		SplitBlob.RemainingSplits = RemainingSplits - 1;
		SplitBlob.OutsideYawSign = OutsideYawSign;

		// We become the other split
		ProjectileComp.Velocity = ProjectileComp.Velocity.RotateAngleAxis(SplitYaw, FVector::UpVector);
		if (OutsideYawSign == -Math::Sign(SplitYaw))
			ProjectileComp.Velocity *= Settings.BlobSplitSlowdown; // Insize splits slow down
		SplitYaw *= 0.8;
		RemainingSplits--;

		if (OutsideYawSign == 0.0)
		{
			// Initial split;
			OutsideYawSign = 1.0;
			SplitBlob.OutsideYawSign = -1.0;	
		}

		USkylineGeckoBlobEffectHandler::Trigger_OnSplit(this);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbGrabSplits(AHazeActor Target, UGravityWhipUserComponent Grabber)
	{
		TArray<UGravityWhipTargetComponent> GrabbableSplits;
		GrabbableSplits.Add(GravityWhipTargetComponent);
		FVector ScatterAxis = ActorForwardVector;
		for(int i = 1; i < (1 << uint(RemainingSplits)); i++)
		{
			if (Target != nullptr)
				ScatterAxis = ActorUpVector.CrossProduct((Target.ActorLocation - ActorLocation).ConstrainToPlane(Target.ActorUpVector).GetSafeNormal());
			float ScatterAngle = 75.0 - (150.0 / RemainingSplits) * i;
			FVector Direction = ActorUpVector.RotateAngleAxis(ScatterAngle, ScatterAxis);
			ASkylineGeckoBlob SplitBlob = Split(Direction * 800.0); 
			SplitBlob.SplitYaw = ScatterAngle;
			SplitBlob.RemainingSplits = 0;
			GrabbableSplits.Add(SplitBlob.GravityWhipTargetComponent);
		}
		Grabber.Grab(GrabbableSplits);

		USkylineGeckoBlobEffectHandler::Trigger_OnGrabbedByWhip(this);
	}

	private ASkylineGeckoBlob Split(FVector Velocity)
	{
		UBasicAIProjectileComponent Projectile = BlobLauncher.Launch(Velocity, FRotator::ZeroRotator);
		auto Blob = Cast<ASkylineGeckoBlob>(Projectile.Owner);
		Projectile.Gravity = Settings.BlobGravity;
		Projectile.UpVector = ActorUpVector;
		Blob.SetActorRotation(FRotator::MakeFromZ(ActorUpVector));
		Blob.SetActorLocation(ActorLocation);
		Blob.Launch(BlobLauncher, 0, false);
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
		if (UserComponent.HasControl() && (RemainingSplits > 0))
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

UCLASS(Abstract)
class USkylineGeckoBlobEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSplit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBounce(FGeckoBlobImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnGrabbedByWhip() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpactWhenThrownByWhip(FGeckoBlobImpactData Data) {}
}

struct FGeckoBlobImpactData
{
	UPROPERTY()
	FHitResult HitResult;

	FGeckoBlobImpactData(FHitResult Impact)
	{
		HitResult = Impact;
	}
}
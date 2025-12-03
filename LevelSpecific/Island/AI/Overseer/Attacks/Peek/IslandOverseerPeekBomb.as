class AIslandOverseerPeekBomb : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffset;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;
	default ProjectileComp.Damage = 0.5;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 15.0;

	AAIIslandOverseer Overseer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"Launch");
		Overseer = TListedActors<AAIIslandOverseer>().GetSingle();
	}

	UFUNCTION()
	private void Launch(UBasicAIProjectileComponent Projectile)
	{
		FIslandOverseerPeekBombOnLaunchEventData Data = FIslandOverseerPeekBombOnLaunchEventData();
		Data.LaunchLocation = Projectile.Owner.ActorLocation;
		UIslandOverseerPeekBombEventHandler::Trigger_OnLaunch(this, Data);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(GetUpdatedMovementLocation(DeltaSeconds, Hit));
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
				OnLocalImpact(Hit);
				ProjectileComp.Expire();
				UIslandOverseerPeekBombEventHandler::Trigger_OnHit(this, FIslandOverseerPeekBombOnHitEventData(Hit));		
				UIslandOverseerEventHandler::Trigger_OnPeekBombImpact(Overseer, FIslandOverseerPeekBombOnHitEventData(Hit));		
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false, float SubStepDuration = BIG_NUMBER)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		FVector Delta = FVector::ZeroVector;

		// Perform substepping movement
		float RemainingTime = DeltaTime;
		for(; RemainingTime > SubStepDuration; RemainingTime -= SubStepDuration)
		{
			ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * SubStepDuration;
			ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * SubStepDuration;
			Delta += ProjectileComp.Velocity * SubStepDuration;
		}

		// Move the remaining fraction of a substep
		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * RemainingTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * RemainingTime;
		Delta += ProjectileComp.Velocity * RemainingTime;

		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
			Trace.UseSphereShape(Collision);
			Trace.IgnoreActors(ProjectileComp.AdditionalIgnoreActors);

			if (ProjectileComp.Launcher != nullptr)
			{	
				Trace.IgnoreActor(ProjectileComp.Launcher, ProjectileComp.bIgnoreDescendants);

				if (ProjectileComp.bIgnoreLauncherAttachParents)
				{
					AActor AttachParent = ProjectileComp.Launcher.AttachParentActor;
					while (AttachParent != nullptr)
					{
						Trace.IgnoreActor(AttachParent);
						AttachParent = AttachParent.AttachParentActor;
					}				
				}
			}
			OutHit = Trace.QueryTraceSingle(OwnLoc, OwnLoc + Delta);

			if (OutHit.bBlockingHit)
				return OutHit.ImpactPoint;
		}

		return OwnLoc + Delta;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		ProjectileComp.Impact(Hit);
		UIslandOverseerPeekBombEventHandler::Trigger_OnHit(this, FIslandOverseerPeekBombOnHitEventData(Hit));
		UIslandOverseerEventHandler::Trigger_OnPeekBombImpact(Overseer, FIslandOverseerPeekBombOnHitEventData(Hit));	
		Knockdown(Hit);
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);	
		LaunchingWeapon.CrumbProjectileImpact(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
		OnLocalImpact(Hit);
		ProjectileComp.Expire();
		UIslandOverseerPeekBombEventHandler::Trigger_OnHit(this, FIslandOverseerPeekBombOnHitEventData(Hit));
		UIslandOverseerEventHandler::Trigger_OnPeekBombImpact(Overseer, FIslandOverseerPeekBombOnHitEventData(Hit));
		Knockdown(Hit);
	}

	private void Knockdown(FHitResult Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if(Player != nullptr)
		{
			FStumble Kb;
			Kb.Move = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * 250;
			Kb.Duration = 0.75;
			Player.ApplyStumble(Kb);
		}
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}
}
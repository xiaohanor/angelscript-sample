
class AEnforcerShotgunProjectile : AHazeActor
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
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.CollisionProfileName = n"NoCollision";

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 2.4;

	FVector StartLocation;

	UEnforcerShotgunSettings Settings;

	void Fire(AHazeActor User)
	{
		StartLocation = ActorLocation;
		Settings = UEnforcerShotgunSettings::GetSettings(User);
		ProjectileComp.Damage = Settings.PlayerDamage;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		bool bIgnoreCollision = ActorLocation.IsWithinDist(StartLocation, Settings.IgnoreCollisionRange);
		FHitResult Hit;
		SetActorLocation(GetUpdatedMovementLocation(DeltaTime, Hit, bIgnoreCollision));
		if (Hit.bBlockingHit)
		{
			OnImpact(Hit);
			Impact(Hit);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(ProjectileComp.HazeOwner, Data);
		ProjectileComp.Expire();

		float Damage = ProjectileComp.Damage + Settings.AdditionalCloseDamage * (1 - Math::Min(1, StartLocation.Distance(ActorLocation) / Settings.AdditionalCloseDamageRange));
		BasicAIProjectile::DealDamage(Hit, Damage, ProjectileComp.DamageType, ProjectileComp.Launcher, FPlayerDeathDamageParams(Hit.ImpactPoint, 0.1));

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
		if(Player != nullptr && Player.ActorLocation.IsWithinDist(StartLocation, Settings.StumbleRange))
		{
			FStumble Stumble;
			Stumble.Move = (ActorLocation - StartLocation).GetSafeNormal2D() * 100;
			Stumble.Duration = 0.8;
			Player.ApplyStumble(Stumble);
		}
	}

	// Helper function for simple trace projectiles
	FVector GetUpdatedMovementLocation(float DeltaTime, FHitResult& OutHit, bool bIgnoreCollision = false)
	{
		FVector OwnLoc = ProjectileComp.Owner.ActorLocation;
		
		ProjectileComp.Velocity -= ProjectileComp.UpVector * ProjectileComp.Gravity * DeltaTime;
		ProjectileComp.Velocity -= ProjectileComp.Velocity * ProjectileComp.Friction * DeltaTime;
		FVector Delta = ProjectileComp.Velocity * DeltaTime;
		if (Delta.IsNearlyZero())
			return OwnLoc;

		if (!bIgnoreCollision)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
			Trace.UseCapsuleShape(Collision);
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
			{
				if ((Settings.ProjectileWidth > 0.0) && !OutHit.Actor.IsA(AHazePlayerCharacter))
				{
					// Found center hit, see if sides are blocked as well
					// Trace from an earlier ok position out towards sides, so we won't be able to tunnel through stuff.
					FVector EarlierLoc = OwnLoc - ActorForwardVector * 50.0;
					float FractionInterval = 1.0;
					for (float Fraction = -0.5; Fraction < 0.51; Fraction += FractionInterval)
					{
						FVector SideOffset = ActorRightVector * Fraction * Settings.ProjectileWidth;
						FHitResult SideHit = Trace.QueryTraceSingle(EarlierLoc, OwnLoc + Delta + SideOffset);
						if (!SideHit.bBlockingHit)
						{
							// This side was clear, allow projectile passage
							OutHit = SideHit;
							return OwnLoc + Delta;
						}
					}
				}
				return OutHit.ImpactPoint;
			}
		}

		return OwnLoc + Delta;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}

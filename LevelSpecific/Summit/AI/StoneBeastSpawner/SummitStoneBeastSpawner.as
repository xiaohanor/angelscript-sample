event void FOnStoneBeastSpawnerDestroyed();

UCLASS(Abstract)
class ASummitStoneBeastSpawner : AHazeActor
{
	UPROPERTY()
	FOnStoneBeastSpawnerDestroyed OnStoneBeastSpawnerDestroyed;
	default SetActorTickInterval(0.2);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent Collision;
	default Collision.CapsuleRadius = 250.0;
	default Collision.CapsuleHalfHeight = 350.0;
	default Collision.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Collision)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	//UBasicAINetworkedProjectileLauncherComponent SpawnLauncher;
	UBasicAIProjectileLauncherComponent SpawnLauncherino; // TODO: Fix networked spawner prepare problem

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent SwordResponseComp;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatTargetComponent SwordTargetComp;
	default SwordTargetComp.bCanRushTowards = false;
	default SwordTargetComp.RelativeLocation = FVector(0,0, 100);

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegistratorComp;

	UPROPERTY(EditAnywhere)
	float SpawnMaxRange = 1000.0;

	UPROPERTY(EditAnywhere)
	float SpawnMinRange = 550.0;

	UPROPERTY(EditAnywhere)
	float SpawnArcAngle = 90.0;

	UPROPERTY(EditAnywhere)
	float SpawnArcYawOffset = 0.0;

	UPROPERTY(EditAnywhere)
	ACrystalSpikeRuptureManager SpikeRuptureManager;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitStoneBeastSpawnerVisualizationComponent VisComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastSpawnerRuptureCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneBeastSpawnerRegenerationCapability");

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActorSpawnerBase> Spawners;
	default Spawners.Add(nullptr);

	UPROPERTY(EditInstanceOnly)
	TArray<ASummitStoneBeastSpawner> StartSpawningWhenDead;
	default StartSpawningWhenDead.Add(nullptr);

	//Kill all AI within a large radius when destroyed - jank-ish solution for now
	UPROPERTY(EditAnywhere)
	bool bKillAllAIOnDeath;

	UPROPERTY(EditAnywhere)
	float ZOffset = -800;

	UPROPERTY(EditAnywhere)
	float RuptureDelayTime = 0.0;

	bool bIsSpawning = false;
	
	UPROPERTY(EditAnywhere)
	USummitStoneBeastSpawnerSettings DefaultSettings;

	USummitStoneBeastSpawnerSettings Settings;

	TArray<ASummitStoneBeastSpawnerProjectile> Projectiles;

	// Some other spawners may be blocking part of our arc
	TArray<ASummitStoneBeastSpawner> ArcBlockers;
	FVector ArcDirection;
	float ArcAngle;
	
	FVector TargetLocation;
	bool bStartRupture;
	float RuptureSpeed = 1600.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(DefaultSettings);
		Settings = USummitStoneBeastSpawnerSettings::GetSettings(this);
		SwordResponseComp.OnHit.AddUFunction(this,n"OnSwordHit");
		
		TargetLocation = ActorLocation;
		ActorLocation += FVector(0,0,ZOffset);
		//SpawnLauncher.PrepareProjectiles(1);

		UpdateArc();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update arc whenever a blocker has been destroyed
		for (int i = 0; i < ArcBlockers.Num(); i++)
		{
			if (ArcBlockers[i].HealthComp.IsAlive())
				continue;
			UpdateArc();
			break;
		}
	}

	TPerPlayer<float> HackInvulnerabilityTimes;

	UFUNCTION(NotBlueprintCallable)
	private void OnSwordHit(UDragonSwordCombatUserComponent CombatComp, FDragonSwordHitData HitData, AHazeActor Instigator)
	{
		// // Invulnerable when not spawning so we don't accidentally hit through another spawner
		// if (!bIsSpawning)
		// 	return;

		// Hack to not take multiple damage from one sword strike
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Instigator);
		if (Player == nullptr)
			Player = Game::Mio;
		if (HackInvulnerabilityTimes[Player] > Time::GameTimeSeconds)
			return;
		HackInvulnerabilityTimes[Player] = Time::GameTimeSeconds + 0.5;
		// End hack, remove when sword handles this instead

		HealthComp.TakeDamage(Settings.DamageFromSword, EDamageType::MeleeSharp, Cast<AHazeActor>(CombatComp.Owner));
		if (HealthComp.IsAlive())
			CrumbDie();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDie()
	{
		StopSpawning();

		if (bKillAllAIOnDeath)
		{
			Damage::AIRadialDamageToTeam(ActorLocation, 5000.0, 1.0, this, AITeams::Default);
		}
		
		for (ASummitStoneBeastSpawner Spawner : StartSpawningWhenDead)
		{
			if (Spawner == nullptr)
				continue;
			Spawner.StartSpawning();	
		}

		USummitStoneBeastSpawnerEffectHandler::Trigger_OnDeath(this, FStoneBeastSpawnerParams(ActorLocation));		
		AddActorDisable(this);
		HealthComp.OnDie.Broadcast(this);
		OnStoneBeastSpawnerDestroyed.Broadcast();
	}

	UFUNCTION()
	void StartSpawning()
	{
		bIsSpawning = true;
		for (AHazeActorSpawnerBase Spawner : Spawners)
		{
			if (Spawner == nullptr)
				continue;	
			Spawner.OnPostSpawn.AddUFunction(this, n"OnSpawn");		
			Spawner.SpawnerComp.ActivateSpawner(this);
		}	
	}

	UFUNCTION()
	void StopSpawning()
	{
		bIsSpawning = false;
		for (AHazeActorSpawnerBase Spawner : Spawners)
		{
			if (Spawner == nullptr)
				continue;	
			Spawner.OnPostSpawn.UnbindObject(this);		
			Spawner.SpawnerComp.DeactivateSpawner(this);
		}
	}

	UFUNCTION()
	void ActivateRupture()
	{
		bStartRupture = true;
		USummitStoneBeastSpawnerEffectHandler::Trigger_OnRupture(this, FStoneBeastSpawnerParams(TargetLocation));
	}

	UFUNCTION()
	private void OnSpawn(AHazeActor SpawnedActor)
	{
		SpawnedActor.AddActorDisable(this);
		if (HasControl())
			CrumbLaunchSpawnProjectile(SpawnedActor, GetSpawnLocation());

		// Get ready for next spawn
		//SpawnLauncher.PrepareProjectiles(1);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchSpawnProjectile(AHazeActor SpawnedActor, FVector SpawnLoc)
	{
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(SpawnLauncherino.LaunchLocation, SpawnLoc, Settings.SpawnProjectileGravity, Settings.SpawnProjectileLaunchApex);
		UBasicAIProjectileComponent Projectile = SpawnLauncherino.Launch(LaunchVelocity);
		ASummitStoneBeastSpawnerProjectile SpawnerProjectile = Cast<ASummitStoneBeastSpawnerProjectile>(Projectile.Owner);	
		SpawnerProjectile.LaunchSpawn(SpawnedActor, SpawnLoc);

		// Place actor immediately so position will be taken into account when spawning any further AIs	
		// Rethink this if we get to many netmsgs	
		SpawnedActor.TeleportActor(SpawnLoc, ActorRotation, this); 
	}

	FVector GetSpawnLocation()
	{
		FVector Loc = GetRandomLocation();
		Loc = GetDispersedLocation(Loc);
		if (!Pathfinding::FindNavmeshLocation(Loc, SpawnMaxRange, SpawnMaxRange, Loc))
		{
			// Could not find any location on navmesh, plonk spawn down as close as possible in center of arc.
			Loc = ActorLocation + ArcDirection * SpawnMinRange;
		}
		return Loc; 
	}

	FVector GetDispersedLocation(FVector Loc)
	{
		UHazeTeam AITeam = HazeTeam::GetTeam(AITeams::Default);
		if (!IsValid(AITeam))
			return Loc;

		FVector DispersedLoc = Loc;
		TArray<AHazeActor> AIs = AITeam.GetMembers();
		TArray<FVector> Repulsors;
		for (AHazeActor AI : AIs)
		{
			if (AI.ActorLocation.IsWithinDist2D(DispersedLoc, SpawnMaxRange))
				Repulsors.Add(AI.ActorLocation);
		}
		if (Repulsors.Num() > 0)
		{
			float PushRadius = (SpawnMaxRange - SpawnMinRange) * Math::Min(1.0, 5.0 / float(Repulsors.Num()));
			for (int RepulsionIteration = 0; RepulsionIteration < 3; RepulsionIteration++)
			{
				DispersedLoc = GetRepulsedLocation(DispersedLoc, Repulsors, PushRadius);
			}
		}
		return DispersedLoc;
	}

	FVector GetRepulsedLocation(FVector Loc, const TArray<FVector>& Repulsors, float PushRadius, bool bDebugDraw = false)
	{
		FVector Push = FVector::ZeroVector;
		for (FVector Repulsor : Repulsors)
		{
			if (Repulsor.IsWithinDist2D(Loc, PushRadius))
			{
				FVector Away = Loc - Repulsor;
				Away.Z = 0.0;
				float Dist = Math::Max(1.0, Away.Size2D());
				Push += (Away / Dist) * (PushRadius - Dist); // Push to outside radius
			}
		}
		
		if (!Push.IsZero())
		{
			Push = Push.GetClampedToMaxSize2D((SpawnMaxRange - SpawnMinRange) * 0.1);	
			if (bDebugDraw)
				Debug::DrawDebugLine(Loc, Loc + Push, FLinearColor::Yellow, 2, 10);
		}
		
		FVector RepulsedLoc = Loc + Push;
		FVector Unclamped = RepulsedLoc;
		RepulsedLoc = ClampToArc(RepulsedLoc);
		RepulsedLoc = ClampBeforeSpikes(RepulsedLoc);
		if (bDebugDraw)
			Debug::DrawDebugLine(Unclamped, RepulsedLoc, FLinearColor::Green, 4, 10);
		
		return RepulsedLoc;
	}

	FVector GetRandomLocation()
	{
		float Range = Math::RandRange(SpawnMinRange, SpawnMaxRange);
		float Angle = Math::RandRange(-ArcAngle * 0.5, ArcAngle * 0.5);
		return ClampBeforeSpikes(ActorLocation + ArcDirection.RotateAngleAxis(Angle, ActorUpVector) * Range);
	}

	FVector ClampToArc(FVector Loc)
	{
		FVector ClampedLoc = Loc;
		FVector Origin = ActorLocation;
		if (ClampedLoc.IsWithinDist(Origin, SpawnMinRange))
			ClampedLoc = Origin + (ClampedLoc - Origin).GetSafeNormal2D() * SpawnMinRange;
		if (!ClampedLoc.IsWithinDist(Origin, SpawnMaxRange))
			ClampedLoc = Origin + (ClampedLoc - Origin).GetSafeNormal2D() * SpawnMaxRange;
		FVector LocDir = (ClampedLoc - Origin).GetSafeNormal2D();
		float ArcDot = ArcDirection.DotProduct(LocDir);
		if (ArcDot < Math::Cos(Math::DegreesToRadians(ArcAngle * 0.5)))
		{
			float ClosestEdgeYaw = ArcAngle * 0.5;
			if (LocDir.DotProduct(ArcDirection.CrossProduct(FVector::UpVector)) > 0.0)
				ClosestEdgeYaw *= -1.0;
			FVector EdgeDir = ArcDirection.RotateAngleAxis(ClosestEdgeYaw, FVector::UpVector); 
			ClampedLoc = Math::ProjectPositionOnInfiniteLine(Origin, EdgeDir, ClampedLoc);
		}
		return ClampedLoc;
	}

	FVector ClampBeforeSpikes(FVector Loc)
	{
		// Never spawn behind spikes
		FVector BeforeLoc = Loc;
		
		if (SpikeRuptureManager == nullptr)
			return Loc;

		FTransform SpikeTransform = SpikeRuptureManager.PlayerFollowingSpline.Spline.GetWorldTransformAtSplineDistance(SpikeRuptureManager.CurrentSplineDistance);
		FVector SpikeFwd = SpikeTransform.Rotation.ForwardVector;
		FVector SpikeSafeLimit = SpikeTransform.TransformPositionNoScale(FVector(400.0, 0.0, 0.0));
		if (SpikeFwd.DotProduct(BeforeLoc - SpikeSafeLimit) < 0.0)
		{
			// In among or too near spikes, move!
			BeforeLoc = Math::ProjectPositionOnInfiniteLine(SpikeSafeLimit, SpikeTransform.Rotation.RightVector, BeforeLoc);
		}
		return BeforeLoc;
	}

	UFUNCTION()
	void UpdateArc()	
	{
		// If unobstructed, arc is simply this:
		ArcDirection = ActorForwardVector.RotateAngleAxis(SpawnArcYawOffset, FVector::UpVector); 
		ArcAngle = SpawnArcAngle;

		if (!Settings.SpawnProjectileBlockedByOtherSpawners)
			return;

		// Check if any other spawners are obstructing our arc and constrain arc appropriately.
		float CosHalfArc = Math::Cos(Math::DegreesToRadians(ArcAngle * 0.5));
		ArcBlockers.Empty(ArcBlockers.Num());
		FVector OwnLoc = ActorLocation;
		float OwnHeight = ActorLocation.Z;
		TListedActors<ASummitStoneBeastSpawner> StoneBeastSpawners;
		for (ASummitStoneBeastSpawner Other : StoneBeastSpawners)
		{
			if (Other == this)
				continue;
			if (!IsValid(Other))
				continue;
			if (Other.HealthComp.IsDead())
				continue;		
			FVector OtherLoc = Other.Collision.WorldLocation;
			float OtherRadius = Other.Collision.CapsuleRadius * Math::Max(Other.Collision.WorldScale.X, Other.Collision.WorldScale.Y);
			if (!OtherLoc.IsWithinDist2D(OwnLoc, SpawnMaxRange + OtherRadius))
				continue; // Far away
			float OtherHalfHeight = Other.Collision.CapsuleHalfHeight * Other.Collision.WorldScale.Z;
			if (OwnHeight < Other.Collision.WorldLocation.Z - OtherHalfHeight - 200.0)
				continue; // Below
			if (OwnHeight > Other.Collision.WorldLocation.Z + OtherHalfHeight + 200.0)
				continue; // Above

			// Might be close enough, check if cylinder around other intersects with arc sides.
			// Two lines from arc start will touch the edges of the cylinder surrounding the other spawner
			// Intersection of line starting at origin, y = vx and circle (with center at dx,dy) (x-dx)2 + (y-dy)2 = r2 
			// gives a discriminant (the stuff under the sqrt) of (-2vdy -2dx)2 - 4(1 + v2)(dx2 + dy2 - r2). 
			// When this is zero we have line touching the outside of the circle as both solutions are the same. 
			// Thus, solving for v, the line directions are 
			// v = (-dxdy +- Sqrt(dx2dy2 - (r2 - dx2)(r2 - dy2))) / (r2 - dx2)
			float Dx = (OtherLoc.X - OwnLoc.X); 
			float Dy = (OtherLoc.Y - OwnLoc.Y);
			float Dx2 = Math::Square(Dx);
			float Dy2 = Math::Square(Dy);
			float Radius2 = Math::Square(OtherRadius);
			float Discriminant = (Dx2 * Dy2) - ((Radius2 - Dx2) * (Radius2 - Dy2)); // Note that this is the discriminant when solving for v
			if (Discriminant < 0.0)
				continue; // Own location is inside, assume we will be able to launch free of this other spawner
			
			// Now find the directions touching the left and right side of the other cylinder
			float SqrtDiscriminant = Math::Sqrt(Discriminant);				
			FVector LeftDir = FVector(1.0, (-Dx*Dy + SqrtDiscriminant) / (Radius2 - Dx2), 0.0).GetSafeNormal2D();
			FVector RightDir = FVector(1.0, (-Dx*Dy - SqrtDiscriminant) / (Radius2 - Dx2), 0.0).GetSafeNormal2D();
			if (LeftDir.DotProduct(OtherLoc - OwnLoc) < 0.0)
				LeftDir *= -1.0;
			if (RightDir.DotProduct(OtherLoc - OwnLoc) < 0.0)
				RightDir *= -1.0;
			float LeftDot = LeftDir.DotProduct(ArcDirection);
			float RightDot = RightDir.DotProduct(ArcDirection);
			float NewAngle = ArcAngle;
			if ((LeftDot > CosHalfArc) && (LeftDot > RightDot))
			{
				// Left is inside arc and closest to the center line; shift arc to the left of left direction
				NewAngle = Math::Abs(FRotator::NormalizeAxis(LeftDir.Rotation().Yaw - (ArcDirection.Rotation().Yaw - 0.5 * ArcAngle)));
				ArcDirection = ArcDirection.RotateAngleAxis((NewAngle - ArcAngle) * 0.5,FVector::UpVector); // Rotate to the left since ArcAngle > NewAngle
			}
			else if (RightDot > CosHalfArc)
			{
				// Right is inside arc and closest to the center line; shift arc to the right of right direction
				NewAngle = Math::Abs(FRotator::NormalizeAxis(RightDir.Rotation().Yaw - (ArcDirection.Rotation().Yaw + 0.5 * ArcAngle)));
				ArcDirection = ArcDirection.RotateAngleAxis((ArcAngle - NewAngle) * 0.5,FVector::UpVector); // Rotate to the right since ArcAngle > NewAngle
			}
			if (ArcAngle != NewAngle)
			{
				// Arc was obstructed, so is being narrowed
				ArcBlockers.Add(Other);
				ArcAngle = NewAngle;
				CosHalfArc = Math::Cos(Math::DegreesToRadians(NewAngle * 0.5));				
			}
		}
	}

	UFUNCTION(DevFunction)
	void TestStartSpawning()
	{
		StartSpawning();
	}

	UFUNCTION(DevFunction)
	void TestSpawnLocs()
	{
		UpdateArc();

		TArray<FVector> Locs;
		for (int i = 0; i < 10; i++)
		{
			FVector Loc = GetRandomLocation();
			if (Locs.Num() > 0)
			{
				float PushRadius = (SpawnMaxRange - SpawnMinRange) * Math::Min(1.0, 5.0 / float(Locs.Num()));
				for (int PushIteration = 0; PushIteration < 3; PushIteration ++)
				{
					Loc = GetRepulsedLocation(Loc, Locs, PushRadius, true);
				}
			}

			FVector PathLoc = Loc;
			if (!Pathfinding::FindNavmeshLocation(Loc, SpawnMaxRange, SpawnMaxRange, PathLoc))
				PathLoc = ActorLocation + ArcDirection * SpawnMinRange;
			Debug::DrawDebugLine(Loc, PathLoc, FLinearColor::LucBlue, 4, 10);					

			Locs.Add(PathLoc);
			Debug::DrawDebugSphere(Locs.Last(), 10, 4, FLinearColor::Red, 5, 10);
		}

		Debug::DrawDebugArc(SpawnArcAngle, ActorLocation, SpawnMaxRange, ActorForwardVector.RotateAngleAxis(SpawnArcYawOffset, FVector::UpVector), FLinearColor::Red, 3.0, FVector::UpVector, 16, SpawnMinRange, true, 10);
		Debug::DrawDebugArc(ArcAngle, ActorLocation, SpawnMaxRange, ArcDirection, FLinearColor::Yellow, 5.0, FVector::UpVector, 16, SpawnMinRange, true, 10);
	}
}

#if EDITOR
class USummitStoneBeastSpawnerVisualizationComponent : UActorComponent
{
}

class USummitStoneBeastSpawnerVisualizationComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitStoneBeastSpawnerVisualizationComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		if (Component == nullptr)
			return;

        ASummitStoneBeastSpawner Spawner = Cast<ASummitStoneBeastSpawner>(Component.Owner);
        if (!ensure(Spawner != nullptr))
            return;

		FVector ArcDir = Spawner.ActorForwardVector.RotateAngleAxis(Spawner.SpawnArcYawOffset, FVector::UpVector);
		DrawArc(Spawner.ActorLocation + FVector(0,0,450), Spawner.SpawnArcAngle, Spawner.SpawnMaxRange, ArcDir, FLinearColor::Yellow, 5.0, FVector::UpVector, 16, Spawner.SpawnMinRange);

		for (AHazeActorSpawnerBase ControlledSpawner : Spawner.Spawners)
		{
			if (ControlledSpawner == nullptr)
				continue;
			DrawDashedLine(Spawner.ActorLocation, ControlledSpawner.ActorLocation, FLinearColor::Yellow, 20.0, 3.0);
		}		

		for (ASummitStoneBeastSpawner Successor : Spawner.StartSpawningWhenDead)
		{
			if (Successor == nullptr)
				continue;
			DrawArrow(Spawner.ActorLocation, Successor.ActorLocation, FLinearColor::LucBlue, 20.0, 4.0);
		}		
    }   
} 
#endif
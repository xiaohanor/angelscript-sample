enum EWingsuitBossMineMoveState
{
	MoveUpToShootLocation,
	Shoot,
	Floating,
	Stationary
}

UCLASS(Abstract)
class AWingsuitBossMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Sphere;
	default Sphere.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Niagara;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SplashEffect;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditAnywhere)
	TArray<AActor> CollisionIgnoreActors;

	bool bHasBeenShot;

	private UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	private FVector CurrentVelocity;
	private FRotator TargetRotation;
	private AHazePlayerCharacter CurrentTarget;
	private UWingsuitBossMineLauncher ShootComponent;
	private UWingsuitBossMineLauncher Launcher;
	private EWingsuitBossMineMoveState CurrentMoveState;
	private FHazeAcceleratedVector AcceleratedRelativeLocation;
	private UWingsuitBossSettings Settings;
	private float CurrentShootDelay;
	private float TimeOfSpawn;
	private float TimeOfLand;
	private TArray<AHazePlayerCharacter> PlayersToTryHitting;
	private bool bCurrentlyDetonating = false;
	private float TimeOfDetonation;
	private UCoastWaterskiWaveCollisionContainerComponent WaveCollisionContainerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaveCollisionContainerComp = UCoastWaterskiWaveCollisionContainerComponent::GetOrCreate(Game::Mio);
		AddActorDisable(this);
	}

	void SpawnProjectile(AHazePlayerCharacter In_CurrentTarget, UHazeActorNetworkedSpawnPoolComponent In_SpawnPool, UWingsuitBossMineLauncher In_Launcher, UWingsuitBossMineLauncher In_ShootComponent, UWingsuitBossSettings In_Settings)
	{
		AttachToComponent(In_Launcher, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		ActorLocation = In_Launcher.ShootLocation;
		ActorRotation = In_Launcher.ShootRotation;
		CurrentTarget = In_CurrentTarget;
		Launcher = In_Launcher;
		ShootComponent = In_ShootComponent;
		SpawnPool = In_SpawnPool;
		CurrentMoveState = EWingsuitBossMineMoveState::MoveUpToShootLocation;
		AcceleratedRelativeLocation.SnapTo(ActorRelativeLocation);
		Settings = In_Settings;
		RemoveActorDisable(this);
		TimeOfSpawn = Time::GetGameTimeSeconds();
		PlayersToTryHitting.Add(Game::Mio);
		PlayersToTryHitting.Add(Game::Zoe);
		bCurrentlyDetonating = false;
		bHasBeenShot = false;

		Niagara.Activate(true);
		UWingsuitBossMineEffectHandler::Trigger_OnMineSpawned(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CurrentMoveState == EWingsuitBossMineMoveState::MoveUpToShootLocation)
		{
			FVector RelativeLocationOfShootLocation = Launcher.WorldTransform.InverseTransformPosition(ShootComponent.WorldLocation);

			FVector RelativeLocation = AcceleratedRelativeLocation.SpringTo(RelativeLocationOfShootLocation, Settings.ProjectileSpringUpToShootPointStiffness, Settings.ProjectileSpringUpToShootPointDamping, DeltaTime);

			ActorRelativeLocation = RelativeLocation;

			if(HasControl() && LifeTime > CurrentShootDelay)
			{
				CrumbStartShooting(CurrentTarget.IsPlayerDead() ? CurrentTarget.OtherPlayer : CurrentTarget);
			}
		}
		else if(CurrentMoveState == EWingsuitBossMineMoveState::Shoot)
		{
			ActorRotation = Math::RInterpShortestPathTo(ActorRotation, TargetRotation, DeltaTime, 5.0);
			CurrentVelocity -= FVector::UpVector * (Settings.ProjectileGravityAfterShot * DeltaTime);
			FVector PreviousLocation = ActorLocation;
			ActorLocation += CurrentVelocity * DeltaTime;
			ActorLocation += FVector::UpVector * (Settings.ProjectileGravityAfterShot * 0.5 * Math::Square(DeltaTime));

			FHazeTraceSettings Trace = Trace::InitProfile(n"BlockAllDynamic");
			Trace.UseSphereShape(Sphere.SphereRadius);

			Trace.IgnoreActor(Launcher.Owner);
			Trace.IgnoreActor(Launcher.Owner.AttachParentActor);

			if(OceanWaves::GetOceanWavePaint().TargetLandscape != nullptr)
			{
				Trace.IgnoreActor(OceanWaves::GetOceanWavePaint().TargetLandscape);
			}

			for(UCoastWaterskiWaveCollisionComponent Comp : WaveCollisionContainerComp.WaveCollisionComponents)
			{
				Trace.IgnoreActor(Comp.Owner);
			}

			if (CollisionIgnoreActors.Num() > 0)
				Trace.IgnoreActors(CollisionIgnoreActors);

			FHitResult Hit = Trace.QueryTraceSingle(PreviousLocation, ActorLocation);

			if(Hit.bBlockingHit && (LifeTime > CurrentShootDelay + 0.8))
			{
				CurrentMoveState = EWingsuitBossMineMoveState::Stationary;
				StartDetonating();
				return;
			}

			FCoastWaterskiWaveData WaveData = CoastWaterski::GetWaveData(ActorLocation, this);

			if(ActorLocation.Z <= WaveData.PointOnWave.Z)
			{
				ActorLocation = WaveData.PointOnWave;
				CurrentMoveState = EWingsuitBossMineMoveState::Floating;
				Niagara::SpawnOneShotNiagaraSystemAtLocation(SplashEffect, ActorLocation);
				TimeOfLand = Time::GetGameTimeSeconds();
				UWingsuitBossMineEffectHandler::Trigger_OnMineHitWater(this);
			}
		}
		else if(CurrentMoveState == EWingsuitBossMineMoveState::Floating)
		{
			FCoastWaterskiWaveData WaveData = CoastWaterski::GetWaveData(ActorLocation, this);

			ActorLocation = WaveData.PointOnWave;

			float MinSqrDist = MAX_flt;
			AHazePlayerCharacter ClosestPlayer;
			for(AHazePlayerCharacter Player : Game::Players)
			{
				float SqrDist = Player.ActorLocation.DistSquared(ActorLocation);
				if(SqrDist < MinSqrDist)
				{
					MinSqrDist = SqrDist;
					ClosestPlayer = Player;
				}
			}

			if(MinSqrDist < Math::Square(Settings.ProjectileDistanceFromPlayerToDetonate) && !bCurrentlyDetonating)
			{
				StartDetonating();
			}
		}
		else if(CurrentMoveState == EWingsuitBossMineMoveState::Stationary)
		{

		}
		else
			devError("Forgot to add case");

		if(bCurrentlyDetonating)
		{
			if(HasControl())
				Detonate();

			float TimeSinceDetonation = Time::GetGameTimeSince(TimeOfDetonation);
			if(TimeSinceDetonation > Settings.ProjectilePlayerDamageDuration)
				Kill();
		}
	}

	void StartDetonating()
	{
		bCurrentlyDetonating = true;
		AddActorVisualsBlock(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionEffect, ActorLocation);
		OnExploded();
		TimeOfDetonation = Time::GetGameTimeSeconds();
		UWingsuitBossMineEffectHandler::Trigger_OnMineExploded(this);
	}

	void Detonate()
	{
		FCollisionShape SphereShape = FCollisionShape::MakeSphere(Sphere.SphereRadius);

		for(int i = PlayersToTryHitting.Num() - 1; i >= 0; --i)
		{
			AHazePlayerCharacter Player = PlayersToTryHitting[i];

			FCollisionShape PlayerShape = FCollisionShape::MakeCapsule(
		Player.CapsuleComponent.GetUnscaledCapsuleRadius(),
		Player.CapsuleComponent.GetUnscaledCapsuleHalfHeight());

			if(Overlap::QueryShapeOverlap(PlayerShape, Player.CapsuleComponent.WorldTransform, SphereShape, ActorTransform))
			{
				CrumbDamage(Player, Settings.ProjectilePlayerDamage);
				PlayersToTryHitting.RemoveAt(i);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnExploded(){}

	UFUNCTION(CrumbFunction)
	private void CrumbStartShooting(AHazePlayerCharacter PlayerTarget)
	{
		DetachFromActor();
		CurrentTarget = PlayerTarget;
		CurrentMoveState = EWingsuitBossMineMoveState::Shoot;
				
		auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(CurrentTarget);
		
		FVector TargetLocation = WaterskiComp.WaveData.PointOnWave + CurrentTarget.ActorVelocity.VectorPlaneProject(FVector::UpVector) * Settings.ProjectileShootArcDuration + PlayerTarget.ActorForwardVector * Settings.ProjectileFrontOfPlayerOffset;
		float HorizontalDist = ActorLocation.DistXY(TargetLocation);
		CurrentVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetLocation, Settings.ProjectileGravityAfterShot, HorizontalDist / Settings.ProjectileShootArcDuration);
		TargetRotation = FRotator::MakeFromZX(FVector::UpVector, CurrentVelocity);
		bHasBeenShot = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDamage(AHazePlayerCharacter Player, float Damage)
	{
		Player.DamagePlayerHealth(Damage);
	}

	void Kill()
	{
		RemoveActorVisualsBlock(this);
		AddActorDisable(this);
		SpawnPool.UnSpawn(this);
		Niagara.DeactivateImmediate();
	}

	float GetLifeTime() const property
	{
		return Time::GetGameTimeSince(TimeOfSpawn);
	}
}
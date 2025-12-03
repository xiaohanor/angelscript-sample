UCLASS(Abstract)
class AWingsuitBotProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.RelativeScale3D = FVector(FVector::OneVector * 4.0);

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams IdleAnimation;
	default IdleAnimation.bLoop = true;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams ActivateAnimation;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams ActivatedAnimation;
	default IdleAnimation.bLoop = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SpawnVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	AHazeActor WingsuitBossOwner;

	FHazeAcceleratedVector AcceleratedVelocity;
	FHazeAcceleratedRotator AcceleratedRotator;
	FHazeAcceleratedFloat AccScale;

	FRotator InitialRotation;

	const float MaxRotationAmount = 30.0;
	const float RandomVelocitySize = 1500.0;
	const float InitialScale = 0.2;
	const float ExplosionDuration = 5.0;

	bool bExploding = false;
	float TimeOfExplosion;
	float TargetScale;
	float TimeOfSpawn;
	TPerPlayer<bool> DamagedByExplosion;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		TargetScale = ActorScale3D.X;
	}

	void Init(AHazeActor Owner, UHazeActorNetworkedSpawnPoolComponent In_SpawnPool)
	{
		WingsuitBossOwner = Owner;
		auto Launcher = UWingsuitBossMineLauncher::Get(WingsuitBossOwner);
		FVector RandomVelocity = Launcher.RightVector * Math::RandRange(-RandomVelocitySize, RandomVelocitySize);
		RandomVelocity += Launcher.UpVector * Math::RandRange(-RandomVelocitySize, RandomVelocitySize);
		AcceleratedVelocity.SnapTo(WingsuitBossOwner.GetRawLastFrameTranslationVelocity() * 0.7 + RandomVelocity);
		AcceleratedRotator.SnapTo(FRotator(Math::RandRange(-MaxRotationAmount, MaxRotationAmount), Math::RandRange(-MaxRotationAmount, MaxRotationAmount), Math::RandRange(-MaxRotationAmount, MaxRotationAmount)));

		// We do this since when rotations are sent over the network they seem to be unwinded, since we use this rotation as angular velocity that will be wack
		FVector VectorizedRot = FVector(AcceleratedRotator.Value.Pitch, AcceleratedRotator.Value.Yaw, AcceleratedRotator.Value.Roll);
		if(HasControl())
			CrumbInit(Owner, AcceleratedVelocity.Value, VectorizedRot, Math::RandRange(0.3, 0.8), Math::RandomRotator(true), In_SpawnPool);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbInit(AHazeActor Owner, FVector In_AcceleratedVelocity, FVector In_AcceleratedRotator, float In_RandomAnimationDelay, FRotator RandomRotation, UHazeActorNetworkedSpawnPoolComponent In_SpawnPool)
	{
		WingsuitBossOwner = Owner;
		bExploding = false;
		SpawnPool = In_SpawnPool;
		DamagedByExplosion[0] = false;
		DamagedByExplosion[1] = false;
		Mesh.SetHiddenInGame(false);
		TimeOfSpawn = Time::GetGameTimeSeconds();
		AccScale.SnapTo(InitialScale);
		ActorRotation = RandomRotation;
		ActorScale3D = FVector::OneVector * AccScale.Value;
		AcceleratedVelocity.SnapTo(In_AcceleratedVelocity);
		FRotator Rot = FRotator(In_AcceleratedRotator.X, In_AcceleratedRotator.Y, In_AcceleratedRotator.Z);
		AcceleratedRotator.SnapTo(Rot);
		InitialRotation = AcceleratedRotator.Value;
		RemoveActorDisable(this);
		Mesh.PlaySlotAnimation(IdleAnimation);
		Timer::SetTimer(this, n"StartAnimation", In_RandomAnimationDelay, false);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnVFX, ActorLocation);

		UWingsuitBotProjectileEffectHandler::Trigger_OnMineSpawned(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(Time::GetGameTimeSince(TimeOfSpawn) > 10.0)
			{
				CrumbUnSpawn();
				return;
			}

			if(bExploding && Time::GetGameTimeSince(TimeOfExplosion) > ExplosionDuration)
			{
				CrumbUnSpawn();
				return;
			}
		}

		if(!bExploding && Game::GetDistanceSquaredFromLocationToClosestPlayer(ActorLocation) < Math::Square(1000.0))
		{
			TriggerExplosion();
		}

		// Debug::DrawDebugSphere(ActorLocation, 1000);

		if(bExploding)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(DamagedByExplosion[Player])
					continue;

				float DistSquared = Player.ActorLocation.DistSquared(ActorLocation);
				if(DistSquared > Math::Square(1000.0))
					continue;

				Player.DamagePlayerHealth(0.5);
				DamagedByExplosion[Player] = true;
			}
			return;
		}

		AccScale.AccelerateTo(TargetScale, 1.0, DeltaSeconds);
		ActorScale3D = FVector::OneVector * AccScale.Value;
		AcceleratedVelocity.AccelerateTo(FVector::ZeroVector, 2, DeltaSeconds);
		AcceleratedRotator.AccelerateTo(InitialRotation * 0.2, 2, DeltaSeconds);
		ActorLocation += AcceleratedVelocity.Value * DeltaSeconds;
		ActorQuat = (AcceleratedRotator.Value.Quaternion() * DeltaSeconds) * ActorQuat;
	}

	void TriggerExplosion()
	{
		TimeOfExplosion = Time::GetGameTimeSeconds();
		bExploding = true;
		Mesh.SetHiddenInGame(true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
		UWingsuitBotProjectileEffectHandler::Trigger_OnMineExploded(this);
		OnExploded();
	}

	UFUNCTION(BlueprintEvent)
	void OnExploded(){}

	UFUNCTION()
	private void StartAnimation()
	{
		Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"OnBlendingOut"), ActivateAnimation);
	}

	UFUNCTION()
	private void OnBlendingOut()
	{
		Mesh.PlaySlotAnimation(ActivatedAnimation);
	}

	UFUNCTION(CrumbFunction)
	void CrumbUnSpawn()
	{
		AddActorDisable(this);
		SpawnPool.UnSpawn(this);
	}
}
UCLASS(Abstract)
class ASketchbookBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BobSceneComponent;

	UPROPERTY(DefaultComponent, Attach = BobSceneComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	USketchbookDrawableObjectComponent DrawableComp;

	UPROPERTY(DefaultComponent)
	USketchbookBossJumpComponent JumpComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent ProjectileSpawnPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USketchbookArrowResponseComponent ArrowResponseComp;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USketchbookBowAutoAimComponent ArrowAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = ArrowAutoAimComp)
	UHazeRawVelocityTrackerComponent RawVelocityTrackerComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AHazeActor> ProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	ESketchbookBossChoice BossType;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	FText HealthBarDesc;

	USketchbookBossComponent BossComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent KnockBackCollisionComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect KnockDownForceFeedback;

	default KnockBackCollisionComp.SphereRadius = 150;
	default KnockBackCollisionComp.RelativeLocation = FVector(0,0,150);

	ASketchbookSentence BossText;

	AHazePlayerCharacter CurrentTargetPlayer;

	float IdleTimer = 0;

	bool bEnteredArena = false;
	bool bCrushedText = false;

	FVector StartLocation;
	float ArenaFloorZ;

	private FQuat StartRotation;
	private FQuat TargetRotation;
	private float RotationDiff;

	private float RotateStep = 10;
	float RotationStartTime = 0;
	float RotationDuration = 0;

	int BossNumber = 0;

	bool bIsKilled = false;

	UPROPERTY(EditDefaultsOnly)
	float DeathTime = 1;

	UFUNCTION(BlueprintPure)
	bool HasEnteredArena() const
	{
		return bEnteredArena;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentTargetPlayer = Game::GetZoe();
		StartLocation = ActorLocation;
		TargetRotation = ActorQuat;
		ArrowResponseComp.OnHitByArrow.AddUFunction(this, n"OnHitByArrow");
		KnockBackCollisionComp.OnComponentBeginOverlap.AddUFunction(this,n"OnOverlap");
		BossComp = USketchbookBossComponent::Get(this);
		ArenaFloorZ = SketchbookBoss::GetSketchbookBossFightManager().ArenaFloorZ;

		ResetStencilValue();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		FVector PlayerLocation = Player.GetActorLocation();
		FVector Knockback = (PlayerLocation - GetActorLocation());
		
		if(PlayerLocation.Y < GetArenaRightSide() - 100 || PlayerLocation.Y > GetArenaLeftSide() + 100)
		{
			Knockback.Y = (StartLocation.Y - PlayerLocation.Y);
		}

		Knockback.Normalize();
		Knockback *= 1250;

		if(ActorVerticalVelocity.Z > 0)
		{
			Knockback += FVector::UpVector * ActorVerticalVelocity.Z * 20;
		}

		Player.ApplyKnockdown(Knockback, 2.5);
		Player.DamagePlayerHealth(0.0, FPlayerDeathDamageParams(), DamageEffect);
		CurrentTargetPlayer = Player;
		Player.PlayForceFeedback(KnockDownForceFeedback, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RotationDuration == 0)
			return;

		float Duration = Time::GetRealTimeSince(RotationStartTime);

		float Alpha = Math::Clamp(Duration / RotationDuration, 0, 1);
		FRotator NewRotation = Math::LerpShortestPath(StartRotation.Rotator(), TargetRotation.Rotator(), Alpha);

		float NewYaw = Math::RoundToInt(NewRotation.Yaw / RotateStep) * RotateStep;

		SetActorRotation(FRotator(NewRotation.Pitch, NewYaw, NewRotation.Roll));
	}

	void RotateTowards(FQuat Target, float InterpSpeed = 160)
	{
		StartRotation = ActorQuat;
		RotationStartTime = Time::RealTimeSeconds;

		FQuat AdjustedTarget = Target * FQuat(FVector::UpVector, PI);

		RotationDiff = AdjustedTarget.Rotator().GetManhattanDistance(ActorRotation);
		if(RotationDiff > 180)
			RotationDiff -= 180;

		RotationDuration = RotationDiff / InterpSpeed;
		TargetRotation = AdjustedTarget;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for(auto Actor : AttachedActors)
		{
			if (Actor.RootComponent != nullptr && Actor.RootComponent.IsAttachedTo(this))
				Actor.DestroyActor();
		}
	}

	void StartMainAttackSequence()
	{
		BossComp.StartMainAttackSequence();
	}

	void EndMainAttackSequence()
	{
		if(SketchbookBoss::GetSketchbookBossFightManager() == nullptr)
			return;
		
		BossComp.EndMainAttackSequence();

		if(BossNumber == 0 && !SketchbookBoss::UnkillableBoss.IsEnabled())
			SketchbookBoss::GetSketchbookBossFightManager().EndPhase();
	}

	UFUNCTION()
	private void OnHitByArrow(FSketchbookArrowHitEventData ArrowHitData, FVector ArrowLocation)
	{
		if(!ArrowHitData.bHasControl)
			return;

		SketchbookBoss::GetSketchbookBossFightManager().CrumbTakeDamage();

		Mesh.CustomDepthStencilValue = 15;
		Timer::SetTimer(this, n"ResetStencilValue", 0.2);
	}

	UFUNCTION()
	void ResetStencilValue()
	{
		Mesh.CustomDepthStencilValue = 9;
	}

	void Idle(float IdleTime)
	{
		IdleTimer = IdleTime;
	}

	float GetArenaRightSide() const
	{
		return StartLocation.Y + SketchbookBoss::Settings::ArenaHalfWidth;
	}

	float GetArenaLeftSide() const
	{
		return StartLocation.Y - SketchbookBoss::Settings::ArenaHalfWidth;
	}

	const ESketchbookBossPhase GetPhase() const
	{
		return BossComp.CurrentPhase;
	}

};
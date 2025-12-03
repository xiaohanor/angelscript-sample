class AMeltdownBossPhaseThreeOgreAttackIntro : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponce;
	default GlitchResponce.bShouldLeadTargetByActorVelocity = true;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.bApplyKnockbackImpulse = true;
	default DamageTrigger.HorizontalKnockbackStrength = 900.0;
	default DamageTrigger.VerticalKnockbackStrength = 1200.0;
	default DamageTrigger.KnockbackForwardDirectionBlend = 0.5;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UHealthBarInWorldComponent HealthBarComp;
	default HealthBarComp.MaxHealth = 5.0;
	default HealthBarComp.CurrentHealth = 5.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> OgreCameraShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect OgreForceFeedbck;

	UPROPERTY()
	UAnimSequence TumblingAnimation;
	UPROPERTY()
	UAnimSequence FallingAnimation;
	UPROPERTY()
	TArray<UAnimSequence> LandingAnimation;
	UPROPERTY()
	TArray<UAnimSequence> RunningAnimation;

	UPROPERTY()
	float Speed = 1400.0;
	UPROPERTY()
	float Acceleration = 200.0;
	UPROPERTY()
	float FallSpeed = -2200.0;
	UPROPERTY()
	float TurnRate = 30.0;
	UPROPERTY()
	float Lifetime = 5.0;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	AHazePlayerCharacter TargetPlayer;
	FVector ArenaLocation;
	float CurrentSpeed;

	float PosOscilation = 4.0;
	float NegOscilation = -4.0;
	AMeltdownPhaseThreeBoss Rader;

	private float LastDamagedByPlayerTime = 0.0;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;
	private FVector OriginalLaunchLocation;
	private bool bRunning = false;
	private bool bLanded = false;
	private bool bDroppedOffArena = false;
	private float DropOffSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AutoAim.Disable(this);
		GlitchResponce.OnGlitchHit.AddUFunction(this, n"OnHit");
		UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_Spawn(this);
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_HitByPlayerAttack(this, Impact);

		LastDamagedByPlayerTime = Time::GameTimeSeconds;
		HealthBarComp.CurrentHealth -= Impact.Damage;
		if (HealthBarComp.CurrentHealth <= 0)
		{
			UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_DestroyedByPlayerAttack(this);
			DestroyActor();
		}
	}

	void StartFalling()
	{
		PlaySlotAnimation(Animation = TumblingAnimation, bLoop = true);
		SetActorVelocity(FVector::ZeroVector);
	}

	void DropOffArena()
	{
		bRunning = false;
		bDroppedOffArena = true;
		PlaySlotAnimation(Animation = TumblingAnimation, bLoop = true);
		UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_FallingOffPlatform(this);
	}

	UFUNCTION()
	private void Landed()
	{
		bLanded = true;
		AutoAim.Enable(this);
		Mesh.SetRelativeRotation(FRotator(0, 0, 0));

		UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_LandedOnGround(this);
		PlaySlotAnimation(
			Animation = LandingAnimation[Math::RandRange(0, LandingAnimation.Num() - 1)],
			OnBlendingOut = FHazeAnimationDelegate(this, n"StartRunning"));

		bRunning = true;
		// Timer = Math::RandRange(-0.3, 0.0);
		Timer = 0.0;
		CurrentSpeed = Speed;

		// OriginalLaunchDirection = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal2D();
		// ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);

		OriginalLaunchDirection = ActorForwardVector;
		OriginalLaunchLocation = ActorLocation;
	}

	UFUNCTION()
	private void StartRunning()
	{
		PlaySlotAnimation(
			Animation = RunningAnimation[Math::RandRange(0, RunningAnimation.Num() - 1)],
			bLoop = true, PlayRate = 1.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Rader.IsDead())
		{
			DestroyActor();
			return;
		}

		if (!bLanded)
		{
			FVector Location = ActorLocation;
			Location.Z += FallSpeed * DeltaSeconds;

			if (Location.Z <= ArenaLocation.Z)
			{
				Location.Z = ArenaLocation.Z;
				Landed();
			}

			SetActorLocation(Location);
		}
		else if (bRunning)
		{
			FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal2D();
			FVector OriginalTargetVector = (TargetPlayer.ActorLocation - OriginalLaunchLocation).GetSafeNormal2D(); 
			float DistanceToPlayer = TargetPlayer.ActorLocation.Dist2D(ActorLocation);
			if (TargetVector.DotProduct(OriginalTargetVector) > 0
				&& DistanceToPlayer > 800.0
				&& !TargetPlayer.IsPlayerDead())
			{
				ActorRotation = Math::RInterpConstantShortestPathTo(
					ActorRotation,
					FRotator::MakeFromX(TargetVector),
					DeltaSeconds,
					TurnRate,
				);
			}

			if (Timer >= 0.0)
			{
				if (LastDamagedByPlayerTime != 0.0 && Time::GetGameTimeSince(LastDamagedByPlayerTime) < 0.25)
					CurrentSpeed = 200.0;
				else if (CurrentSpeed < Speed)
					CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, Speed, DeltaSeconds, Speed * 4.0);

				ActorLocation += ActorForwardVector * (CurrentSpeed * DeltaSeconds + Acceleration * 0.5 * Math::Square(DeltaSeconds));
				CurrentSpeed += Acceleration * DeltaSeconds;
			}

			SetActorVelocity(ActorForwardVector * CurrentSpeed);
			Timer += DeltaSeconds;

			if (ActorLocation.Dist2D(ArenaLocation) > 2350 && Timer > 1.0)
				DropOffArena();

			for(AHazePlayerCharacter Player : Game::Players)
				{
					if(ActorLocation.Dist2D(Player.ActorLocation) < 900)
					{
//						Player.PlayWorldCameraShake(OgreCameraShake,this, ActorLocation, 450, 900, 10);
						Player.SetFrameForceFeedback(Math::Sin(Time::GameTimeSeconds * PosOscilation),Math::Sin(Time::GameTimeSeconds * NegOscilation),0.0,0.0,0.5);
					}

					
				}

		}
		else if (bDroppedOffArena)
		{
			float Gravity = 3000.0;
			FVector Location = ActorLocation;
			Location += ActorForwardVector * CurrentSpeed * DeltaSeconds;
			Location.Z -= DropOffSpeed * DeltaSeconds + Gravity * 0.5 * Math::Square(DeltaSeconds);

			CurrentSpeed *= Math::Pow(0.5, DeltaSeconds);
			DropOffSpeed += Gravity * DeltaSeconds;

			SetActorLocation(Location);
			
			Timer += DeltaSeconds;
			if (Timer > Lifetime)
			{
				UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler::Trigger_Despawn(this);
				if (bDestroyOnExpire)
					DestroyActor();
				else
					AddActorDisable(this);
			}
		}
	}
};

UCLASS(Abstract)
class UMeltdownBossPhaseThreeOgreAttackIntroEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LandedOnGround() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByPlayerAttack(FMeltdownGlitchImpact GlitchImpact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyedByPlayerAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Despawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FallingOffPlatform() {}
}
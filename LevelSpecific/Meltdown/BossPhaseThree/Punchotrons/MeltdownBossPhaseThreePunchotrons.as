class AMeltdownBossPhaseThreePunchotrons : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UDamageTriggerComponent BaseDamageTrigger;
	default BaseDamageTrigger.bApplyKnockbackImpulse = true;
	default BaseDamageTrigger.HorizontalKnockbackStrength = 900.0;
	default BaseDamageTrigger.VerticalKnockbackStrength = 1200.0;
	default BaseDamageTrigger.KnockbackForwardDirectionBlend = 0.5;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = LeftHand)
	UDamageTriggerComponent LeftBladeDamageTrigger;
	default LeftBladeDamageTrigger.bApplyKnockbackImpulse = true;
	default LeftBladeDamageTrigger.HorizontalKnockbackStrength = 900.0;
	default LeftBladeDamageTrigger.VerticalKnockbackStrength = 1200.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightHand)
	UDamageTriggerComponent RightBladeDamageTrigger;
	default RightBladeDamageTrigger.bApplyKnockbackImpulse = true;
	default RightBladeDamageTrigger.HorizontalKnockbackStrength = 900.0;
	default RightBladeDamageTrigger.VerticalKnockbackStrength = 1200.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UHealthBarInWorldComponent HealthBarComp;
	default HealthBarComp.MaxHealth = 10.0;
	default HealthBarComp.CurrentHealth = 10.0;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UAutoAimTargetComponent AutoAim;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent NearMissTrigger;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> NearMissShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect NearMissFeedback;

	UPROPERTY(EditAnywhere)
	UAnimSequence LeftMHAnimation;
	UPROPERTY(EditAnywhere)
	UAnimSequence RightMHAnimation;

	UPROPERTY()
	float InitialSpeed = 1800.0;
	UPROPERTY()
	float Acceleration = 1200.0;
	UPROPERTY()
	float TurnRate = 5.0;
	UPROPERTY()
	float Lifetime = 3.0;
	UPROPERTY()
	float Gravity = 9000.0;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent GlitchResponce;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;
	

	FVector StartScale;
	FVector MovementDirection;

	FVector Startlocation;
	float VerticalVelocity = 0.0;
	bool bLanded = false;

	AMeltdownPhaseThreeBoss Rader;

	UPROPERTY()
	FVector EndScale;

	FHazeTimeLike StartAnim;
	default StartAnim.Duration = 1.0;
	default StartAnim.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Startlocation = ActorLocation;

		GlitchResponce.OnGlitchHit.AddUFunction(this, n"OnHit");

		NearMissTrigger.OnPlayerEnter.AddUFunction(this, n"OnNearMiss");
	}

	UFUNCTION()
	private void OnNearMiss(AHazePlayerCharacter Player)
	{
		Player.PlayCameraShake(NearMissShake,this);
		Player.PlayForceFeedback(NearMissFeedback,false,false,this);
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_HitByPlayerAttack(this, Impact);
		HealthBarComp.CurrentHealth -= Impact.Damage;
		if (HealthBarComp.CurrentHealth <= 0)
		{
			UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_DestroyedByPlayerAttack(this);
			DestroyActor();
		}
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		MovementDirection = OriginalLaunchDirection;
		VerticalVelocity = 2000;

		UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_Thrown(this);

		Punchotron();
	}


	UFUNCTION(BlueprintEvent)
	void Punchotron()
	{

	}

	UFUNCTION(BlueprintCallable)
	void StartMoving()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Rader.IsDead())
		{
			DestroyActor();
			return;
		}

		if (!bLaunched)
			return;

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		if (TargetVector.DotProduct(OriginalLaunchDirection) > 0 && TurnRate > 0)
		{
			MovementDirection = Math::VInterpNormalRotationTo(
				MovementDirection,
				TargetVector,
				DeltaSeconds,
				TurnRate,
			);
		}

		FVector Movement = MovementDirection * (InitialSpeed + Acceleration * Timer) * DeltaSeconds;

		VerticalVelocity -= Gravity * DeltaSeconds;
		Movement.Z += VerticalVelocity * DeltaSeconds;

		FVector NewLocation = ActorLocation + Movement;
		NewLocation.Z = Math::Max(NewLocation.Z, Rader.ActorLocation.Z);
		VerticalVelocity = (NewLocation.Z - ActorLocation.Z) / DeltaSeconds;

		if (!bLanded && NewLocation.Z <= Rader.ActorLocation.Z)
		{
			UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_LandedOnGround(this);
			bLanded = true;
		}

		ActorLocation = NewLocation;
		ActorRotation = Math::RInterpConstantShortestPathTo(
			ActorRotation,
			FRotator::MakeFromXZ(MovementDirection, FVector::UpVector),
			DeltaSeconds, 500
		);
		
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			UMeltdownBossPhaseThreePunchotronsEffectHandler::Trigger_Despawn(this);
			DestroyActor();
		}
	}

};

UCLASS(Abstract)
class UMeltdownBossPhaseThreePunchotronsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Thrown() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LandedOnGround() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByPlayerAttack(FMeltdownGlitchImpact GlitchImpact) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyedByPlayerAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Despawn() {}
}

UCLASS(Abstract)
class AMeltdownPileOfPunchotrons : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	void Show()
	{
		UMeltdownPileOfPunchotronsEffectHandler::Trigger_Spawn(this);
	}

	void Hide()
	{
		UMeltdownPileOfPunchotronsEffectHandler::Trigger_Depleted(this);
		DestroyActor();
	}
}

UCLASS(Abstract)
class UMeltdownPileOfPunchotronsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Depleted() {}
}
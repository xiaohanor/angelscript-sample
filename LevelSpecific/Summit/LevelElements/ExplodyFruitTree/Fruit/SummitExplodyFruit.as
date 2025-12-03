asset SummitExplodyFruitGravitySettings of UMovementGravitySettings
{
	GravityAmount = 4000.0;
}

event void SummitExplodyFruitEvent(ASummitExplodyFruit ExplodingFruit);

class ASummitExplodyFruit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorComp;
	default SyncedActorComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitExplodeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitGrowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitAttachedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitCapability");

	UPROPERTY(DefaultComponent, Attach = SphereComp)
	USceneComponent CenterScaleRoot;

	UPROPERTY(DefaultComponent, Attach = CenterScaleRoot)
	USceneComponent TopScaleRoot;

	UPROPERTY(DefaultComponent, Attach = TopScaleRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MeshComp.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitExplodyFruitDummyComponent DummyComp;
#endif
	
	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float RollImpactMinSpeed = 1800.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float HorizontalImpulseScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float VerticalImpulseScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float AngularVelocityMultiplier = 0.75;

	/** How much it aims towards where the roll direction was and away from player
	 * Time axle: 0->1 normalized angle between roll direction and vector from player
	 * Value axle: 0->1 how much it should aim in the direction of the vector from the player 
	 */
	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	FRuntimeFloatCurve AimCurve;
	default AimCurve.AddDefaultKey(0.0, 0.0);
	default AimCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Roll Impact")
	float AngleAtWhichAimIsFullyVectorFromPlayer = 50.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float HorizontalSpeedGroundDeceleration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float RotationMultiplier = 0.5;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionRadius = 1700.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float FuseDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float LitScaleUpMagnitude = 0.05;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionScaleUpPulseFrequencyStart = 1.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	float ExplosionScaleUpPulseFrequencyEnd = 20.0;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	TArray<UNiagaraSystem> ExplosionEffects;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "Explosion")
	UMaterialInstance FuseLitMaterial;

	UPROPERTY(EditAnywhere, Category = "Growing Back")
	float FruitGrowTime = 2.0;

	UMaterialInterface StartMaterial;

	TOptional<float> TimeLastHitByAcid;
	float TimeLastSpawned;
	float TimeLastExploded = -MAX_flt;

	SummitExplodyFruitEvent OnExploded;

	FVector AngularVelocity;

	TOptional<float> TimeToExplodeFromAdjacentExplosion;
	TOptional<USummitExplodyFruitTreeAttachment> CurrentAttachment;

	bool bIsEnabled = true;
	bool bIsAttached = false;
	bool bIsGrowing = false;
	bool bIsInitialFruit = true;
	bool bHasHitDespawnVolume = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		StartMaterial = MeshComp.GetMaterial(0);

		ApplyDefaultSettings(SummitExplodyFruitGravitySettings);

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		float SpeedAtHit = Math::Max(Params.SpeedAtHit, RollImpactMinSpeed);

		FVector DirFromPlayer = (ActorLocation - Params.PlayerInstigator.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float AngleBetween = Math::RadiansToDegrees(DirFromPlayer.AngularDistance(Params.RollDirection));
		float Alpha = Math::Clamp(AngleBetween / AngleAtWhichAimIsFullyVectorFromPlayer, 0.0, 1.0);
		Alpha = AimCurve.GetFloatValue(Alpha);
		FVector AimDir = FQuat::Slerp(Params.RollDirection.ToOrientationQuat(), DirFromPlayer.ToOrientationQuat(), Alpha).ForwardVector;

		FVector Impulse = AimDir * SpeedAtHit * HorizontalImpulseScale
			+ FVector::UpVector * SpeedAtHit * VerticalImpulseScale;

		AngularVelocity += Impulse.CrossProduct(FVector::UpVector) * AngularVelocityMultiplier;
		MoveComp.AddPendingImpulse(Impulse);

		TEMPORAL_LOG(Params.PlayerInstigator, "Explody Fruit")
			.DirectionalArrow("Dir From Player", ActorLocation, DirFromPlayer * 500, 10, 500, FLinearColor::White)
			.DirectionalArrow("Roll Direction", ActorLocation, Params.RollDirection * 500, 10, 500, FLinearColor::Black)
			.DirectionalArrow("Aim Dir", ActorLocation, AimDir * 500, 10, 500, FLinearColor::Red)
			.Value("Alpha", Alpha)
			.Value("Angle", AngleBetween)
		;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAcidHit(FAcidHit Hit)
	{
		if(bIsGrowing)
			return;

		if(TimeLastHitByAcid.IsSet())
			return;

		TimeLastHitByAcid.Set(Time::GameTimeSeconds);
		MeshComp.SetMaterial(0, FuseLitMaterial);
	}

	void Reset()
	{
		TimeLastHitByAcid.Reset();
		MeshComp.SetMaterial(0, StartMaterial);
		CenterScaleRoot.RelativeRotation = FRotator::ZeroRotator;
	}
};

#if EDITOR
class USummitExplodyFruitDummyComponent : UActorComponent {};
class USummitExplodyFruitComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitExplodyFruitDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitExplodyFruitDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto Fruit = Cast<ASummitExplodyFruit>(Comp.Owner);
		if(Fruit == nullptr)
			return;
		
		SetRenderForeground(false);

		FVector ExplosionOrigin = Fruit.CenterScaleRoot.WorldLocation;
		DrawWireSphere(ExplosionOrigin, Fruit.ExplosionRadius, FLinearColor::Red, 10, 24, false);
		DrawWorldString("Explosion Radius", ExplosionOrigin + FVector::UpVector * (Fruit.ExplosionRadius + 50), FLinearColor::Red, 1.5, 5000);
	}
}
#endif
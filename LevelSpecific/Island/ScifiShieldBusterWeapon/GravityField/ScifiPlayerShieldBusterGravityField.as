class AScifiPlayerShieldBusterGravityField : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EffectMesh;
	default EffectMesh.CollisionProfileName = n"OverlapAllDynamic";
	default EffectMesh.GenerateOverlapEvents = true;
	UPROPERTY(DefaultComponent)
	USphereComponent Visualizer;  // Finds objects that should be affected by gravity field
	default Visualizer.GenerateOverlapEvents = false;
	default Visualizer.CollisionProfileName = n"NoCollision";
	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;  // Reacts to Shield buster impact
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"TriggerOnlyPlayer";
	default Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default Collision.SetCollisionObjectType(ECollisionChannel::ECC_WorldStatic);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterImpactResponseComponent ImpactResponse;

	UPROPERTY(DefaultComponent)
	UScifiShieldBusterTargetableComponent Target;

	// Gravity Field Components from all nearby actors that should be affected by the gravity field
	TArray<UScifiPlayerShieldBusterGravityFieldComponent> NearbyActorComponents;

	UPROPERTY(EditInstanceOnly)
	float Range = 100.0;

	// Gravity Effect. Shooting the target increases the effect (Max 1.0)
	// The effect stays at max effect (1.0) for a short duration before it starts decreasing again
	// If it doesn't reach 1.0, it immediately starts decreasing
	float GravityEffect = 0.0;
	UPROPERTY(EditInstanceOnly)
	float GravityEffectIncreasePerImpact = 0.25;
	UPROPERTY(EditInstanceOnly)
	float GravityEffectDecreasePerSecond = 0.1;
	UPROPERTY(EditInstanceOnly)
	float StickAtMaxEffectDuration = 3.0;
	float StickTimer = 0.0;
	float ShrinkSpeed = 0.0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Visualizer.SphereRadius = Range;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnEndOverlap");
		ImpactResponse.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	void OnImpact(AHazePlayerCharacter Instigator, UScifiShieldBusterTargetableComponent TargetComponent)
	{
		ActorTickEnabled = true;
		GravityEffect = Math::Clamp(GravityEffect+GravityEffectIncreasePerImpact, 0.0, 1.0);
		if(GravityEffect >= 1.0-SMALL_NUMBER)
		{
			GravityEffect = 1.0;
			StickTimer = StickAtMaxEffectDuration;
		}
		ShrinkSpeed = 0.0;
	}

	UFUNCTION()
	private void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto FoundComponent = UScifiPlayerShieldBusterGravityFieldComponent::Get(OtherActor);
		if(FoundComponent != nullptr)
		{
			NearbyActorComponents.Add(FoundComponent);
			FoundComponent.GravityFiendActivate();
		}
		
	}

	UFUNCTION()
	private void OnEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto FoundComponent = UScifiPlayerShieldBusterGravityFieldComponent::Get(OtherActor);
		if(FoundComponent != nullptr)
		{	
			FoundComponent.TryToDeactivate();
			NearbyActorComponents.Remove(FoundComponent);
		}				
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(StickTimer > 0)
		{
			StickTimer -= DeltaSeconds;
			if(StickTimer <= 0)
			{
				StickTimer = 0.0;
				ShrinkSpeed = 0.0;
			}
		}

		else
		{
			ShrinkSpeed += Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(0.005, 5.0), ShrinkSpeed) *DeltaSeconds; 
			GravityEffect = Math::Clamp(GravityEffect-(GravityEffectDecreasePerSecond*DeltaSeconds*ShrinkSpeed), 0.0, 1.0);
			if(GravityEffect <= 0.0+SMALL_NUMBER)
			{
				GravityEffect = 0.0;
				ActorTickEnabled = false;
			}
		}

		float MeshScale = GravityEffect*20 + 1;
		EffectMesh.SetWorldScale3D(FVector(MeshScale, MeshScale, MeshScale));

	}
}


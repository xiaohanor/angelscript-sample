class ASkylineSentryBossPulseTurret : AWhipSlingableObject
{

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryBossPulseTurretShootCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryBossPulseTurretRiseCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineSentryBossAlignMovementCapability");

	UPROPERTY(DefaultComponent)
	USkylineSentryBossAlignmentComponent AlignmentComp;

	UPROPERTY(DefaultComponent)
	USkylineSentryBossSphericalMovementComponent SphericalMoveComp;


	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineSentryBossPulse> PulseClass;

	UPROPERTY(EditAnywhere)
	float Radius = 500.0;

	UPROPERTY(EditAnywhere)
	float MaxTravelDistance = 0.0;

	UPROPERTY(EditAnywhere)
	float InitialPulseSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	float PulseAcceleration = 100.0;

	UPROPERTY(EditAnywhere)
	float FireInterval = 1.0;

	bool bHasRisen;

	UPROPERTY()
	UNiagaraSystem DestructionNiagaraSystem;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		GravityWhipTargetComponent.AttachToComponent(MeshRoot);
		GravityWhipTargetComponent.Disable(this);


		if (AttachmentRootActor != nullptr)
			ActorRotation = FRotator::MakeFromZ((ActorLocation - AttachmentRootActor.ActorLocation).SafeNormal);	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AlignmentComp.bIsMoving = false;

		if (AttachmentRootActor != nullptr)
		{
			auto RadiusComponent = USkylineSentryBossRadiusComponent::Get(AttachmentRootActor);
			if (RadiusComponent != nullptr)
				Radius = RadiusComponent.Radius;
		}
	}

	void Shoot()
	{
		auto Pulse = SpawnActor(PulseClass, bDeferredSpawn = true);

		Pulse.PulseScaleComponent.Radius = Radius;
		Pulse.PulseScaleComponent.Origin = AttachmentRootActor;
		Pulse.MaxTravelDistance = MaxTravelDistance;
		Pulse.Speed = InitialPulseSpeed;

		FTransform SpawnTransform;
		SpawnTransform.Location = AttachmentRootActor.ActorLocation + (ActorLocation - AttachmentRootActor.ActorLocation).SafeNormal * Pulse.PulseScaleComponent.Radius;
		FinishSpawningActor(Pulse, SpawnTransform);
	}


	void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents) override
	{
		Super::OnGrabbed(UserComponent, TargetComponent, OtherComponents);

		ActorLocation = MeshRoot.WorldLocation;
		MeshRoot.WorldLocation = ActorLocation;

	
		BlockCapabilities(n"PulseTurretRise", this);
		BlockCapabilities(n"PulseTurretShoot", this);
		BlockCapabilities(n"AlignMovement", this);
	}

	void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent,
				  FHitResult HitResult, FVector Impulse) override
	{
		Super::OnThrown(UserComponent, TargetComponent, HitResult, Impulse);
		
		USkylineSentryBossForceFieldResponseComponent::Create(this);
		
	}

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionNiagaraSystem, ActorLocation, ActorRotation);
	}
}
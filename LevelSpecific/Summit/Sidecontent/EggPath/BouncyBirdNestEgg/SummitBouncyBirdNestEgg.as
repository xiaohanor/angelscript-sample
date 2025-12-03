asset SummitBouncyBirdNestEggGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2000.0;
}

class ASummitBouncyBirdNestEgg : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent SphereCollisionComp;
	default SphereCollisionComp.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitBouncyBirdNestEggMovementCapability);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionCapabilityClass = USummitBouncyBirdNestEggInteractionCapability;
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.MovementSettings = FMoveToParams::NoMovement();

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchImpulseUpwards = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchImpulseSideways = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AngularVelocityMultiplier = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationMultiplier = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ExplosionSphereRadius = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bExplodeOnContact = false;

	FVector AngularVelocity;

	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.SetupShapeComponent(SphereCollisionComp);
		ApplyDefaultSettings(SummitBouncyBirdNestEggGravitySettings);
	}

	void GetLaunched(ASummitBouncyBirdNest BouncyBirdNest)
	{
		DetachFromActor(EDetachmentRule::KeepWorld);

		FVector Impulse;
		FVector BasketToEggDelta = (ActorLocation - BouncyBirdNest.MiddleOfBasketRoot.WorldLocation).ConstrainToPlane(FVector::UpVector);
		if(BouncyBirdNest.bLaunchToOtherNest)
		{
			FVector TargetLocation = BouncyBirdNest.CatchingOtherNest.MiddleOfBasketRoot.WorldLocation + BasketToEggDelta;
			Impulse = Trajectory::CalculateVelocityForPathWithHeight(ActorLocation, TargetLocation, SummitBouncyBirdNestEggGravitySettings.GravityAmount, BouncyBirdNest.EggLaunchHeight);
		}
		else
		{
			FVector ImpulseDir = BasketToEggDelta.GetSafeNormal();

			Impulse 
				= FVector::UpVector * LaunchImpulseUpwards
				+ ImpulseDir * LaunchImpulseSideways;
		}
		
		AddMovementImpulse(Impulse);

		AngularVelocity += Impulse.CrossProduct(FVector::UpVector) * AngularVelocityMultiplier;

		TEMPORAL_LOG(this)
			.DirectionalArrow("Impulse", ActorLocation, Impulse, 10, 40)
		;

		MoveComp.AddMovementIgnoresActor(this, BouncyBirdNest);
		Timer::SetTimer(this, n"ClearIgnoreBirdNest", 0.2);

		bIsActive = true;
	}

	UFUNCTION()
	private void ClearIgnoreBirdNest()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
	}

	void Explode()
	{
		USummitBouncyBirdNestEggEventHandler::Trigger_OnEggExploded(this);
		AddActorDisable(this);
	}
};
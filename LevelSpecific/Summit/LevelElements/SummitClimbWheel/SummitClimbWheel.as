UCLASS(Abstract)
class ASummitClimbWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateRoot;
	default TranslateRoot.bConstrainX = true;
	default TranslateRoot.bConstrainZ = true;
	default TranslateRoot.bConstrainY = true;
	default TranslateRoot.MaxY = 2000;
	default TranslateRoot.MinY = -2000;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateRoot;
	default RotateRoot.LocalRotationAxis = FVector(1.0, 0.0, 0.0);
	default RotateRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitClimbWheelRotationCapability");

	// Force applied by the climbing player for rotation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float RotationClimbWeightForce = 1000.0;

	// Force applied when a player is standing on the platform for rotation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float RotationPlatformWeightForce = 400.0;

	// Impulse applied when a player first lands on the platform for rotation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float RotationLandImpulse = 1000.0;

	// Force applied by the climbing player for translation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float TranslationClimbWeightForce = 1000.0;

	// Force applied when a player is standing on the platform for translation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float TranslationPlatformWeightForce = 400.0;

	// Impulse applied when a player first lands on the platform for translation
	UPROPERTY(EditAnywhere, Category = "Climb Wheel")
	float TranslationLandImpulse = 1000.0;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	bool bIsRotating = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Put the platform upright again
		PlatformRoot.WorldRotation = TranslateRoot.WorldRotation;

		TEMPORAL_LOG(this)
			.Value("Rotate Root Velocity", RotateRoot.Velocity)
		;

		if(!bIsRotating)
		{
			if(!Math::IsNearlyZero(RotateRoot.Velocity, 0.1))
			{
				USummitClimbWheelEventHandler::Trigger_OnStartedMoving(this);
				bIsRotating = true;
			}
		}
		else
		{
			if(Math::IsNearlyZero(RotateRoot.Velocity, 0.1))
			{
				USummitClimbWheelEventHandler::Trigger_OnStoppedMoving(this);
				bIsRotating = false;
			}
		}
	}
};

class USummitClimbWheelRotationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASummitClimbWheel Wheel;
	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MioMovementComp;
	bool bIsOnPlatform = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitClimbWheel>(Owner);
		MioMovementComp = UPlayerMovementComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DragonComp == nullptr)
			DragonComp = UPlayerTailBabyDragonComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DirToPlatform = (Wheel.PlatformRoot.WorldLocation - Wheel.RootComponent.WorldLocation).GetSafeNormal();
		FVector DirToZoe = (Game::Zoe.ActorCenterLocation - Wheel.RootComponent.WorldLocation).GetSafeNormal();

		// If the dragon is climbing here, apply a force from that
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang
			&& DragonComp.AttachmentComponent != nullptr
			&& DragonComp.AttachmentComponent.Owner == Owner)
		{
			Wheel.RotateRoot.ApplyForce(
				Game::Zoe.ActorCenterLocation,
				-FVector::UpVector * Wheel.RotationClimbWeightForce,
			);

			Wheel.TranslateRoot.ApplyForce(Wheel.TranslateRoot.WorldLocation, 
					DirToZoe * Wheel.TranslationClimbWeightForce);
		}

		// If the other player is standing on the platform
		bool bNewOnPlatform = false;
		auto GroundComp = MioMovementComp.GetGroundContact().Component;
		if (GroundComp != nullptr && GroundComp.IsAttachedTo(Wheel.PlatformRoot))
			bNewOnPlatform = true;

		if (bNewOnPlatform)
		{
			if (!bIsOnPlatform)
			{
				Wheel.RotateRoot.ApplyImpulse(
					Wheel.PlatformRoot.WorldLocation,
					-FVector::UpVector * Wheel.RotationLandImpulse,
				);

				Wheel.TranslateRoot.ApplyImpulse(Wheel.TranslateRoot.WorldLocation, 
					DirToPlatform * Wheel.TranslationLandImpulse);
			}

			Wheel.RotateRoot.ApplyForce(
				Wheel.PlatformRoot.WorldLocation,
				-FVector::UpVector * Wheel.RotationPlatformWeightForce,
			);

			Wheel.TranslateRoot.ApplyForce(Wheel.TranslateRoot.WorldLocation, 
					DirToPlatform * Wheel.TranslationPlatformWeightForce);
		}
		bIsOnPlatform = bNewOnPlatform;
	}
};
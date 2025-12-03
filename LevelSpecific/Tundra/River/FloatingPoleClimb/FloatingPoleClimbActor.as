class ATundraFloatingPoleClimbActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.SphereRadius = 75.0;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent Mesh;
	
	UPROPERTY(DefaultComponent, Attach=Mesh)
	UCableComponent Cable;
	default Cable.bAttachEnd = false;
	default Cable.CableLength = 250.0;

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UTundraFloatingPoleClimbTargetable Targetable;

	UPROPERTY(DefaultComponent)
	UTundraFloatingPoleClimbMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPos;
	default CrumbSyncedActorPos.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default CrumbSyncedActorPos.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"TundraFloatingPoleClimbMovementCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UFloatingPoleClimbActorVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleActor;

	UPROPERTY(EditInstanceOnly)
	ATundraFloatingPoleClimbCableFloaterActor OptionalCableFloater;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsForZoeOnPole;

	UPROPERTY(EditAnywhere)
	float CameraSettingsZoeBlendTime = 0.5;

	UPROPERTY(EditAnywhere)
	EHazeCameraPriority CameraSettingsZoePriority = EHazeCameraPriority::Default;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AirFriction = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WaterFriction = 1.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float CablePullForceMultiplier = 2.0;

	// Force will only increase until cable is this long, if longer the force will be unchanged
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxCableAdditionalLength = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float CableMaxLengthUntilReleasing = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationInterpSpeed = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BuoyancyMaxAcceleration = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BaseGravityAcceleration = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PolePlayerAdditionalGravityAcceleration = 1200.0;

	// How much player's weight will rotate the pole (0 if player is at the lowest height of the pole, this if at highest)
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PolePlayerMaxRotationAngle = 30.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SwaySpringStiffness = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SwaySpringDamping = 0.8;

	bool bCurrentlyAttached = false;
	AHazePlayerCharacter CablePlayer;
	TSet<AHazePlayerCharacter> ClimbingPlayers;
	FHazeAcceleratedQuat AcceleratedQuat;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(PoleActor == nullptr)
			return;

		PoleActor.AttachToComponent(Mesh, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(OptionalCableFloater != nullptr)
		{
			Cable.SetAttachEndToComponent(OptionalCableFloater.Mesh, NAME_None);
			Cable.bAttachEnd = true;
			OptionalCableFloater.AttachedFloatingPole = this;
		}

		PoleActor.OnStartPoleClimb.AddUFunction(this, n"OnStartPoleClimb");
		PoleActor.OnStopPoleClimb.AddUFunction(this, n"OnStopPoleClimb");
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector CableEndPosition = Cable.Particles[Cable.Particles.Num() - 1].Position;
		Targetable.WorldLocation = CableEndPosition;
	}

	UFUNCTION()
	private void OnStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		ClimbingPlayers.Add(Player);

		FTundraFloatingPolePoleEffectParams Params;
		Params.Player = Player;
		UTundraFloatingPoleClimbEffectHandler::Trigger_PlayerAttachToPole(this, Params);

		if(!Player.IsZoe())
			return;

		Player.ApplyCameraSettings(CameraSettingsForZoeOnPole, CameraSettingsZoeBlendTime, this, CameraSettingsZoePriority);
	}

	UFUNCTION()
	private void OnStopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		ClimbingPlayers.Remove(Player);

		FTundraFloatingPolePoleEffectParams Params;
		Params.Player = Player;
		UTundraFloatingPoleClimbEffectHandler::Trigger_PlayerJumpFromPole(this, Params);

		if(!Player.IsZoe())
			return;

		Player.ClearCameraSettingsByInstigator(this);
	}

	bool IsPlayerClimbing(AHazePlayerCharacter Player) const
	{
		return ClimbingPlayers.Contains(Player);
	}

	// Will return the current sway speed in degrees per second.
	UFUNCTION()
	float AudioGetCurrentSwaySpeed() const
	{
		float Speed = AcceleratedQuat.VelocityAxisAngle.Size();
		return Math::RadiansToDegrees(Speed);
	}

	// Will return the amount of units between the floater actor and the floating pole.
	UFUNCTION()
	float AudioGetCurrentRopeLength() const
	{
		if(OptionalCableFloater == nullptr)
			return 0.0;

		FVector FloaterToPole = (Collision.WorldLocation - OptionalCableFloater.ActorLocation);
		float CurrentDistance = FloaterToPole.Size();
		return CurrentDistance;
	}

	// Will return the angle in degrees between world up and floating pole's up.
	UFUNCTION()
	float AudioGetCurrentAngleOfPole() const
	{
		float AngleOffset = FVector::UpVector.GetAngleDegreesTo(ActorUpVector);
		return AngleOffset;
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UFloatingPoleClimbActorVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}
#endif
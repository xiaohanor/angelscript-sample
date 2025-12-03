/**
 * Drone related data available on the player
 */

UCLASS(Abstract, HideCategories = "ComponentTick ComponentReplication Activation Variable Cooking Tags AssetUserData Collision")
class UDroneComponent : UActorComponent
{
	access Resolver = private, UDroneMovementResolver;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SprintCameraSettings;

	AHazePlayerCharacter Player = nullptr;

	USphereComponent CollisionComponent;
	UShapeComponent OriginalShapeComponent;

	// Dashing

	UPROPERTY(Category = "Movement|Dashing")
	UCurveFloat DashCurve;

	UPROPERTY(Category = "Movement|Dashing")
	TSubclassOf<UCameraShakeBase> DashShake;

	UPROPERTY(Category = "Movement|Dashing")
	UHazeCameraSpringArmSettingsDataAsset DashCameraSetting;

	uint DashFrame = 0;
	bool bIsDashing = false;

	UPROPERTY(Category = "Health")
	UPlayerHealthSettings DroneHealthSettings;

	UPlayerMovementComponent MoveComp;

	UDroneMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		MoveComp = UPlayerMovementComponent::Get(Owner);

		MovementSettings = UDroneMovementSettings::GetSettings(Player);
	}

	void PossessDrone()
	{
		auto MovementComponent = UPlayerMovementComponent::Get(Player);

		// We are still using the original collision shape to handle all overlaps
		OriginalShapeComponent = MovementComponent.GetShapeComponent();
		OriginalShapeComponent.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		// Since this is a ball, we need to have a sphere collision centered on the players location
		// else the movement will not behave correctly
		CollisionComponent = USphereComponent::Create(Player, n"DroneCollision");
		CollisionComponent.SetCollisionProfileName(n"PlayerCharacter");
		CollisionComponent.AttachToComponent(Player.RootOffsetComponent);

		CreateDroneMeshComponent();
		Player.CapsuleComponent.OverrideCapsuleSize(CollisionComponent.SphereRadius, CollisionComponent.SphereRadius, this);
		Player.CapsuleComponent.SetRelativeLocation(FVector::ZeroVector);

		// Setup the movement component to now use the new sphere component
		// with the origin in the middle of the shape
		MovementComponent.SetupShapeComponent(CollisionComponent);

		// hide for now. We'll switch out the static mesh with a skelMesh later
		Player.Mesh.SetHiddenInGame(true);
		Player.Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		// UMovementSweepingSettings::SetGroundedTraceDistance(
		// 	Player,
		// 	// FMovementSettingsValue::MakePercentage(1.0),
		// 	FMovementSettingsValue::MakeValue(1.0),		// allows the ball to go up stairs and other slopes
		// 	this,
		// 	EHazeSettingsPriority::Gameplay
		// );

		Player.TeleportActor(Player.GetActorLocation() + (FVector::UpVector * CollisionComponent.SphereRadius), Player.GetActorRotation(), this);

		auto TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");

		Player.ApplySettings(DroneHealthSettings, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION()
	private void OnTeleported()
	{
		// When we teleport, always move the player up slightly as to not intersect with the ground
		Player.SetActorLocation(Player.ActorLocation + (FVector::UpVector * CollisionComponent.SphereRadius));
	}

	void CreateDroneMeshComponent()
	{
		check(false);	// Implement in parent
	}

	UFUNCTION(BlueprintPure)
	UMeshComponent GetDroneMeshComponent() const
	{
		check(false);	// Implement in parent
		return nullptr;
	}

	void ApplyOutline()
	{
		check(false);	// Implement in parent
	}

	void UnpossessDrone()
	{
		Player.Mesh.SetHiddenInGame(false);
		Player.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		//UMovementSweepingSettings::ClearGroundedTraceDistance(Player, this, EHazeSettingsPriority::Gameplay);
		
		GetDroneMeshComponent().DestroyComponent(Player);
		CollisionComponent.DestroyComponent(Player);

		// Restore original capsule collider
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
		OriginalShapeComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		auto MovementComponent = UPlayerMovementComponent::Get(Player);
		MovementComponent.SetupShapeComponent(OriginalShapeComponent);

		Player.ClearSettingsByInstigator(this);
	}

	void ClearOutline()
	{
		check(false);	// Implement in parent
	}

	bool IsPossessed() const
	{
		return GetDroneMeshComponent() != nullptr;
	}

	UFUNCTION(BlueprintPure)
	FVector GetDroneCenterLocation() const property
	{
		if(IsPossessed())
			return GetDroneMeshComponent().GetWorldLocation();
		else
			return Player.GetActorCenterLocation();
	}

	FVector GetMoveInput(FVector MovementInput, FVector WorldUp) const
	{
		const FVector ControlRot = Player.ControlRotation.Vector();
		FVector Forward = ControlRot.VectorPlaneProject(WorldUp).GetSafeNormal();
		//Debug::DrawDebugDirectionArrow(Player.ActorLocation, Forward, 100.0, 5.0, FLinearColor::Red);
		FVector Right = WorldUp.CrossProduct(Forward).GetSafeNormal();
		//Debug::DrawDebugDirectionArrow(Player.ActorLocation, Right, 100.0, 5.0, FLinearColor::Green);
		Forward *= Forward.DotProduct(MovementInput);
		Right *= Right.DotProduct(MovementInput);
		FVector MoveInput = Forward + Right;
		return MoveInput;
	}

	bool IsDashing() const
	{
		return bIsDashing;
	}

	bool WasDashingLastFrame() const
	{
		return DashFrame == Time::FrameNumber - 1;
	}

	FVector GetSlopeDirection() const
	{
		const FVector SlopePlane = MoveComp.GroundContact.ImpactNormal;

		// First project on to global up, then the slope plane.
		// This should give a vector pointing down the slope
		FVector SlopeDir = SlopePlane.ProjectOnTo(FVector::UpVector).GetSafeNormal();
		SlopeDir = SlopeDir.VectorPlaneProject(SlopePlane).GetSafeNormal();

		return -SlopeDir;
	}
}
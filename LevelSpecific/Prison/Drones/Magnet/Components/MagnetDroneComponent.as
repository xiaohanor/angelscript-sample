#if !RELEASE
namespace DevToggleMagnetDrone
{
	// Display zones and auto aims while playing
	const FHazeDevToggleBool DrawShapes;
	const FHazeDevToggleBool DrawValidatedUp;
	const FHazeDevToggleBool DebugMagnetConstraints;
};
#endif

 /**
  * Drone magnet data on the player
  */
UCLASS(Abstract)
class UMagnetDroneComponent : UDroneComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<AMagnetDroneVisuals> MagnetDroneVisualsClass;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UMagnetDroneSettings DefaultSettings;

	UPROPERTY(Category = "Movement")
	UDroneMovementSettings MagnetDroneMovementSettings;

	AMagnetDroneVisuals MagnetDroneVisuals;

	UMaterialInstanceDynamic DynamicMat;

	UCameraShakeBase ShakeInstance_Canceled;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	UPoseableMeshComponent DroneMesh;

	UPointLightComponent PointLight;

	bool bIsMagnetic = false;

	UMagnetDroneSettings Settings;

	private UPlayerAimingComponent AimComp;
	private UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Settings = UMagnetDroneSettings::GetSettings(Player);

		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);

		Player.ApplyDefaultSettings(DefaultSettings);

#if !RELEASE
		DevToggleMagnetDrone::DrawShapes.MakeVisible();
		DevToggleMagnetDrone::DrawValidatedUp.MakeVisible();
		DevToggleMagnetDrone::DebugMagnetConstraints.MakeVisible();

		TEMPORAL_LOG(this, Owner, "MagnetDrone");
#endif
	}

	FRotator CalculateDesiredRotation() const
	{
		// Get the desired move rotation from the velocity, or actor rotation.
		if(!MoveComp.Velocity.IsZero())
			return FRotator::MakeFromZX(Player.MovementWorldUp, MoveComp.Velocity);
		else
			return Player.GetActorRotation();
	}

	void CreateDroneMeshComponent() override
	{
		MagnetDroneVisuals = SpawnActor(MagnetDroneVisualsClass);

		// Attach to the mesh, this allows URespawnEffectHandler to find the mesh
		MagnetDroneVisuals.AttachToComponent(Player.Mesh);

		DroneMesh = MagnetDroneVisuals.MeshComp;
		PointLight = MagnetDroneVisuals.PointLight;

		CollisionComponent.SetSphereRadius(MagnetDrone::Radius);
	}

	UMeshComponent GetDroneMeshComponent() const override
	{
		return DroneMesh;
	}

	void ApplyOutline() override
	{
		TArray<UPrimitiveComponent> OutlinedComponents;
		OutlinedComponents.Add(GetDroneMeshComponent());
		
		Outline::ApplyOutlineOnComponents(OutlinedComponents, Game::Mio, Outline::GetMioOutlineAsset(), this, EInstigatePriority::High);
	}

	void ClearOutline() override
	{
		TArray<UPrimitiveComponent> OutlinedComponents;
		OutlinedComponents.Add(GetDroneMeshComponent());

		Outline::ClearOutlineOnComponents(OutlinedComponents, Game::Mio, this);
	}

	// we need at least this trace amount in order to touch the surface that the mesh is standing on.
	float GetMinimumOffset() const
	{
		return MagnetDrone::Radius + 1;
	}

	void DrawDebugTracePath(FVector Start, FVector End, const float InRadius, const float Duration = 10.0) const
	{
		// const float DebugRad = 100.0;
		const float DebugRad = InRadius;
		Debug::DrawDebugCylinder(
			Start,
			End,
			DebugRad,
			12,
			FLinearColor::Yellow,
			2.0,
			Duration
		);

		Debug::DrawDebugSphere(Start, DebugRad, 12, FLinearColor::Green, 10.0, Duration);
		Debug::DrawDebugSphere(End, DebugRad, 12, FLinearColor::Red, 10.0, Duration);
	}
};
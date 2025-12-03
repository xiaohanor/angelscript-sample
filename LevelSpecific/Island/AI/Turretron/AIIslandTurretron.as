UCLASS(Abstract)
class AAIIslandTurretron : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldBubbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTurretronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTurretronDamagePlayerOnTouchCapability");

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	UStaticMeshComponent Mesh_Base;
	default Mesh_Base.RelativeScale3D = FVector(0.5, 0.5, 0.5);

	UPROPERTY(DefaultComponent, Attach = "Mesh_Base")
	UStaticMeshComponent Mesh_Mid;

	UPROPERTY(DefaultComponent, Attach = "Mesh_Mid")
	UStaticMeshComponent Mesh_Holder;

	UPROPERTY(DefaultComponent, Attach = "Mesh_Holder")
	UStaticMeshComponent Mesh_Turret;
	default Mesh_Turret.RelativeLocation = FVector(0,0,270);

	UPROPERTY(DefaultComponent, Attach = "Mesh_Turret")
	USceneComponent Pivot_BarrelLeft;
	default Pivot_BarrelLeft.RelativeLocation = FVector(100, -68, -7.5);

	UPROPERTY(DefaultComponent, Attach = "Mesh_Turret")
	USceneComponent Pivot_BarrelRight;
	default Pivot_BarrelRight.RelativeLocation = FVector(100, 68, -7.5);

	// Rotate this after every shot from Left Barrel
	UPROPERTY(DefaultComponent, Attach = "Pivot_BarrelLeft")
	UStaticMeshComponent Mesh_BarrelLeft;
	default Mesh_BarrelLeft.RelativeLocation = FVector(-100, 68, 7.5);

	// Rotate this after every shot from the Right Barrel
	UPROPERTY(DefaultComponent, Attach = "Pivot_BarrelRight")
	UStaticMeshComponent Mesh_BarrelRight;
	default Mesh_BarrelRight.RelativeLocation = FVector(-100, -68, 7.5);


	UPROPERTY(DefaultComponent, Attach = "Mesh_BarrelLeft")
	UBasicAIProjectileLauncherComponent Weapon_Left;	
	default Weapon_Left.RelativeLocation = FVector(260, -68, -7.5);

	UPROPERTY(DefaultComponent, Attach = "Mesh_BarrelRight")
	UBasicAIProjectileLauncherComponent Weapon_Right;
	default Weapon_Right.RelativeLocation = FVector(260, 68, -7.5);
	
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	default GrenadeResponseComp.RelativeLocation = FVector(0, 0, 90);
	default GrenadeResponseComp.Shape.Type = EHazeShapeType::Sphere;
	default GrenadeResponseComp.Shape.SphereRadius = 200.0;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UIslandTurretronSettings Settings;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnPostRespawn");		
	}

	UFUNCTION()
	private void OnPostRespawn()
	{
		Settings = UIslandTurretronSettings::GetSettings(this);
		TargetableComp.MaximumDistance = Settings.AutoAimMaximumDistance;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 100;
	}

}
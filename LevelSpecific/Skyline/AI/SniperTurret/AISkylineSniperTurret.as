UCLASS(Abstract)
class AAISkylineSniperTurret : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSniperTurretBehaviourCompoundCapability");

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
	USkylineSniperTurretAimingComponent AimingComp;

	UPROPERTY(EditAnywhere)
	EHazePlayer TargetPlayer;

	UPROPERTY(EditAnywhere)
	AActor RangeActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BlockCapabilities(n"Behaviour", this);
		UBasicAISettings::SetPriorityTarget(this, TargetPlayer, this);
		HealthComp.SetInvulnerable();
	}

	UFUNCTION()
	void EnableTurret()
	{
		UnblockCapabilities(n"Behaviour", this);
		USkylineSniperTurretSettings::SetAttackRange(this, RangeActor.GetDistanceTo(this), this);
	}

	UFUNCTION()
	void DisableTurret()
	{
		if(!IsCapabilityTagBlocked(n"Behaviour"))
			BlockCapabilities(n"Behaviour", this);
	}
}
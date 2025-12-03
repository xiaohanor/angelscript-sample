UCLASS(Abstract)
class AAISkylineTurret : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTurretBehaviourCompoundCapability");

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
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent OutlineComp;
	default OutlineComp.bAllowOutlineWhenNotPossibleTarget = false;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipImpactComp;

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 100;
	}

	USkylineTurretSettings Settings;

	UPROPERTY(EditAnywhere)
	EHazePlayer TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WhipImpactComp.OnImpact.AddUFunction(this, n"OnImpact");
		WhipImpactComp.OnRadialImpact.AddUFunction(this, n"OnRadialImpact");
		Settings = USkylineTurretSettings::GetSettings(this);
		UBasicAISettings::SetPriorityTarget(this, TargetPlayer, this);
		DisableTurret();
		BlockCapabilities(n"Sweep", this);
	}

	UFUNCTION()
	private void OnRadialImpact(FGravityWhipRadialImpactData ImpactData)
	{
		HealthComp.TakeDamage(Settings.SlingableDamage, EDamageType::Default, nullptr);
	}

	UFUNCTION()
	protected void OnImpact(FGravityWhipImpactData ImpactData)
	{
		HealthComp.TakeDamage(Settings.SlingableDamage, EDamageType::Default, nullptr);
	}

	UFUNCTION()
	void EnableTurret()
	{
		if(IsCapabilityTagBlocked(n"Attack"))
			UnblockCapabilities(n"Attack", this);
	}

	UFUNCTION()
	void DisableTurret()
	{
		if(!IsCapabilityTagBlocked(n"Attack"))
			BlockCapabilities(n"Attack", this);
	}

	UFUNCTION()
	void EnableSweep()
	{
		if(IsCapabilityTagBlocked(n"Sweep"))
			UnblockCapabilities(n"Sweep", this);
	}

	UFUNCTION()
	void DisableSweep()
	{
		if(!IsCapabilityTagBlocked(n"Sweep"))
			BlockCapabilities(n"Sweep", this);
	}
}
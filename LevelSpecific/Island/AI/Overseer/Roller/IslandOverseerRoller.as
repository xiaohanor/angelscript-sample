class AIslandOverseerRoller : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerRollerSweepCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerFxCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandOverseerRollerBlockRespawnPointCapability");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UHazeCharacterSkeletalMeshComponent RollerMesh;
	default RollerMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeTargetable RedBlueTargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerForceFieldComponent ForceFieldComp;
	default ForceFieldComp.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UBoxComponent DamageCollision;
	default DamageCollision.bDisableUpdateOverlapsOnComponentMove = true;
	default DamageCollision.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UCapsuleComponent TakeDamageCollision;
	default TakeDamageCollision.bDisableUpdateOverlapsOnComponentMove = true;
	default TakeDamageCollision.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach=TakeDamageCollision)
	UIslandRedBlueImpactResponseComponent RedBlueResponseComp;

	UPROPERTY(DefaultComponent)
	USceneComponent RightFxContainer;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftFxContainer;

	UPROPERTY(DefaultComponent)
	USceneComponent UpFxContainer;

	UPROPERTY(DefaultComponent)
	USceneComponent DownFxContainer;

	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerEyeHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRollerComponent RollerComp;

	UPROPERTY()
	FHazeTimeLike DropTimeLike;

	float InitialEmissiveIntensity;
	float TimeLastShot;
	bool bIsFlashing = false;
	float ShotEmissiveMax = 300.0;
	float ShotFlashDuration = 0.05;
	bool bDamageMeshHidden;
	bool bBlueForceField;
	float LastAttackMoveSpeed = 0;

	UFUNCTION(BlueprintPure)
	float GetLastAttackMoveSpeed()
	{
		return LastAttackMoveSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthBarComp.Offset = FVector(0, 0, 60);
		HealthBarComp.Initialize();
		HealthBarComp.SetHealthBarEnabled(false);
		HideDamageMesh();
		RollerMesh.bPauseAnims = true;
	}

	void InitializeForceField()
	{		
		if(HasControl())
			CrumbInitializeForceField(bBlueForceField);
		bBlueForceField = !bBlueForceField;
	}

	UFUNCTION(CrumbFunction)
	void CrumbInitializeForceField(bool bBlue)
	{
		ForceFieldComp.ForceFieldTypes.Empty();
		ForceFieldComp.ForceFieldTypes.Add(bBlue ? EIslandForceFieldType::Blue : EIslandForceFieldType::Red);
		ForceFieldComp.Reset();
	}

	void ShowDamageMesh()
	{
		if(!bDamageMeshHidden)
			return;
		bDamageMeshHidden = false;
	}

	void HideDamageMesh()
	{
		if(bDamageMeshHidden)
			return;
		bDamageMeshHidden = true;
	}

	void SetColor(EIslandForceFieldType Color)
	{
		RollerComp.Color = Color;
	}
}
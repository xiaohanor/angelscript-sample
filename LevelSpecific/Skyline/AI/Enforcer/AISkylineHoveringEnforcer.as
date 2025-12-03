UCLASS(Abstract)
class AAISkylineHoveringEnforcer : AAISkylineEnforcerWhippableBase
{
    default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	default CapabilityComp.DefaultCapabilities.Add(n"HoveringEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerHoveringCapability");

	// In case we want this to be able to land and switch to normal enforcer behaviour, we should keep these 
	// and use a capability to switch between flying and ground movement
	default CapabilityComp.DefaultCapabilities.Remove(n"GroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability"); 

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WhipTarget.Enable(this);
		AutoAimComp.Disable(this);
		BladeTarget.Disable(this);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnHoverRespawn");
	}

    UFUNCTION()
    private void OnHoverRespawn()
    {
		WhipTarget.Enable(this);
		AutoAimComp.Disable(this);
		BladeTarget.Disable(this);
		BladeOutline.UnblockOutline(this);
    }
}

UCLASS(Abstract)
class AAISkylineHoveringDualWieldingEnforcer : AAISkylineEnforcerWhippableBase
{
	default HealthComp.MaxHealth = 0.01; // Always instakill

    default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;

	default CapabilityComp.DefaultCapabilities.Remove(n"SkylineEnforcerDeathCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"GravityBladeCombatEnforcerGloryDeathCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"GravityBladeCombatEnforcerGloryDeathSyncMeshCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerHoveringBillboardDeathCapability");

	default CapabilityComp.DefaultCapabilities.Add(n"HoveringDualWieldingEnforcerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"FlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"EnforcerHoveringCapability");

	// In case we want this to be able to land and switch to normal enforcer behaviour, we should keep these 
	// and use a capability to switch between flying and ground movement
	default CapabilityComp.DefaultCapabilities.Remove(n"GroundPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability"); 

	UPROPERTY(DefaultComponent)
	UEnforcerDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UEnforcerDangerZone DangerZoneRoot;
	
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIWeaponWielderComponent SecondaryWeaponWielder;
	default SecondaryWeaponWielder.bMaintainWeaponWorldScale = false; // Weapon should scale with wielder
	default SecondaryWeaponWielder.bVisible = false; // Use the mesh from the main WeaponWielder instead

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WhipTarget.Enable(this);
		AutoAimComp.Disable(this);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnHoverRespawn");
	}

    UFUNCTION()
    private void OnHoverRespawn()
    {
		AutoAimComp.Disable(this);
		BladeOutline.UnblockOutline(this);
    }
}
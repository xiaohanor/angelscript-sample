UCLASS(Abstract)
class AAIslandShieldotronSidescroller : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIGroundMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronSidescrollerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandSidescrollerGroundMovementCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldBubbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronDamagePlayerOnTouchCapability");

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.OptionalShape = FHazeShapeSettings::MakeCapsule(25, 75);

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;
	default ForceFieldComp.bIsAutoRespawnable = true;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	UBasicAIProjectileLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftForeArm")
	UIslandShieldotronMortarLauncherLeft MortarLauncherLeftComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	UIslandShieldotronMortarLauncherRight MortarLauncherRightComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;
	
	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		auto Settings = UIslandShieldotronSidescrollerSettings::GetSettings(this);
		ForceFieldComp.AutoRespawnCooldown = Settings.ForceFieldDepletedCooldown;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 200;
	}
}

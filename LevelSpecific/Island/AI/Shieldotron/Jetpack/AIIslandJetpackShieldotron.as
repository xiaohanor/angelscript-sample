
UCLASS(Abstract)
class AAIIslandJetpackShieldotron : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronAirBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronDefaultAimCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronDamagePlayerOnTouchCapability");

	// Flying movement
	default CapabilityComp.DefaultCapabilities.Add(n"IslandShieldotronFlyingPathfollowingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronFlyingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronTiltCapability"); 
	
	default CapabilityComp.DefaultCapabilities.Add(n"IslandJetpackShieldotronHoveringCapability");

	
	UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
	UPathfollowingMoveToComponent MoveToComp;
	
	UPROPERTY(DefaultComponent, Attach = "HitCapsule")
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UIslandForceFieldComponent ForceFieldComp;
	default ForceFieldComp.bIsAutoRespawnable = false;
	
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	UCapsuleComponent HitCapsule;
	default HitCapsule.bGenerateOverlapEvents = false;
	default HitCapsule.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Gun")
	UBasicAIProjectileLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Gun")
	UBasicAIProjectileLauncherComponent LemonLauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	UBasicAIProjectileLauncherComponent MoonLauncherComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "LeftForeArm")
	UIslandShieldotronMortarLauncherLeft MortarLauncherLeftComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightForeArm")
	UIslandShieldotronMortarLauncherRight MortarLauncherRightComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	UIslandShieldotronOrbLauncher OrbLauncherComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;
	
	UPROPERTY(DefaultComponent)
	UBasicAIEntranceComponent EntranceComp;
	
	UPROPERTY(DefaultComponent)
	UIslandRedBlueForceFieldCollisionComponent ForceFieldCollisionComp;

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UIslandJetpackShieldotronComponent JetpackComp;
	default JetpackComp.SetCurrentFlyState(EIslandJetpackShieldotronFlyState::IsAirBorne);

	UPROPERTY(DefaultComponent)
	UIslandJetpackShieldotronAttackComponent AttackComp;

	UPROPERTY(DefaultComponent)
	UIslandJetpackShieldotronAimComponent AimComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(EditAnywhere)
	UIslandShieldotronSettings DefaultSettings;

	UPROPERTY(EditAnywhere)
	UIslandJetpackShieldotronSettings DefaultJetpackSettings;

	bool bHasPerformedDeathAnimation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(IslandJetpackShieldotronTags::IslandJetpackShieldotronTeam);
		UIslandShieldotronSettings Settings = UIslandShieldotronSettings::GetSettings(this);
		EntranceComp.CollisionDurationAtEndOfEntrance.Apply(Settings.CollisionDurationAtEndOfEntrance, this, EInstigatePriority::Low);
		ApplyDefaultSettings(IslandJetpackShieldotronHealthBarSettings);
		ApplySettings(IslandJetpackShieldotronBasicSettings, this);
		// Override default settings
		if (DefaultSettings != nullptr)
			ApplyDefaultSettings(DefaultSettings);
		if (DefaultJetpackSettings != nullptr)
			ApplyDefaultSettings(DefaultJetpackSettings);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		UBasicAIMovementSettings::SetTurnDuration(this, 2.5, this);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasPerformedDeathAnimation = false;
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 200;
	}
}

asset IslandJetpackShieldotronHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarOffset = FVector(0.0, 0.0, 280.0);
}

asset IslandJetpackShieldotronBasicSettings of UBasicAISettings
{
	TrackTargetRange = 15000;
}

namespace IslandJetpackShieldotronTags
{
	const FName IslandJetpackShieldotronTeam = n"IslandJetpackShieldotronTeam";
}
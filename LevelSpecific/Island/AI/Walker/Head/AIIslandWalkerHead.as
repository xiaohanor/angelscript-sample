event void FIslandWalkerHeadFledSignature();

class AIslandWalkerHead : ABasicAICharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadDeployedBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadDetachedBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadSwimmingBehaviourCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadEscapeBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadDetachedMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadCrashMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadSwimmingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadEscapeMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadDestroyedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadGrenadeDetectionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadHatchDamageCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadHatchInteractionAudioCapability");

	default Mesh.SetBoundsScale(2.0);

	UPROPERTY(DefaultComponent) 
	UBasicAICharacterMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UIslandWalkerAnimationComponent WalkerAnimComp;

	// Note: The head is spawned in runtime, so we need to place these requests on the walker itself
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilities.Add(n"IslandWalkerHeadHatchInteractionCapability");

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UIslandWalkerHeadStumpRoot StumpRoot;
	default StumpRoot.RelativeLocation = FVector(0.0, 0.0, 0.0);
	default StumpRoot.RelativeRotation = FRotator(0.0, 0.0, 180.0);

	// Grenades in front of this component will not be able to affect grenade locks
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	UWalkerHeadBackDividerComponent BackDividerComp;
	default BackDividerComp.RelativeLocation = FVector(0.0, 0.0, 150.0);
	default BackDividerComp.RelativeRotation = FRotator(90.0, 0.0, 180.0);

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent BulletReflectorComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerHeadComponent HeadComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Head")
	UIslandWalkerLaserEmitterComponent Laser;
	default Laser.RelativeLocation = FVector(100.0, 0.0, 500.0);
	default Laser.RelativeRotation = FRotator(105.0, 0.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Head")
	UIslandWalkerFlameThrowerComponent FlameThrower;
	default FlameThrower.RelativeLocation = FVector(-110.0, 0.0, 300.0);
	default FlameThrower.RelativeRotation = FRotator(100.0, 0.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Head")
	UIslandWalkerFuelAndFlameThrowerComponent FuelAndFlameThrower;
	default FuelAndFlameThrower.RelativeLocation = FVector(-110.0, 0.0, 300.0);
	default FuelAndFlameThrower.RelativeRotation = FRotator(100.0, 0.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UIslandWalkerCableOriginComponent CableOrigin;
	default CableOrigin.RelativeLocation = FVector(-240.0, 0.0, 0.0); 	
	default CableOrigin.RelativeRotation = FRotator(0.0, 180.0, 0.0); 	

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Head")
	USceneComponent HeadBase;	
	default HeadBase.RelativeRotation = FRotator(90.0, 0.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandRedBlueImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadHatchShootablePanel HatchShootablePanel;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadHatchRoot HatchRoot;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "HeadHatch")
	UIslandWalkerHeadHatchDetachedComponent DetachedHatch;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadHatchInteractionComponent LeftHatchInteractionComp;
	default LeftHatchInteractionComp.Other = RightHatchInteractionComp;
	default LeftHatchInteractionComp.FocusShape.SphereRadius = 1500.0;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadHatchInteractionComponent RightHatchInteractionComp;
	default RightHatchInteractionComp.Other = LeftHatchInteractionComp;
	default RightHatchInteractionComp.FocusShape.SphereRadius = 1500.0;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UPerchPointComponent MioPerch;
	default MioPerch.RelativeLocation = FVector(140.0, 135.0, 212.0);
	default MioPerch.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioPerch.bTestCollision = true;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UPerchPointComponent ZoePerch;
	default ZoePerch.RelativeLocation = FVector(140.0, -135.0, 212.0);
	default ZoePerch.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoePerch.bTestCollision = true;

	UPROPERTY(DefaultComponent)
	UIslandWalkerThrusterAssembly ThrusterAssembly;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterBelow;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelow")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableBelow;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelow")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseBelow;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterFrontRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterFrontRight")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableFrontRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterFrontRight")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseFrontRight;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterFrontLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterFrontLeft")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableFrontLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterFrontLeft")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseFrontLeft;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterRearRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterRearRight")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableRearRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterRearRight")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseRearRight;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterRearLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterRearLeft")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableRearLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterRearLeft")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseRearLeft;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterBelowRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelowRight")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableBelowRight;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelowRight")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseBelowRight;

	UPROPERTY(DefaultComponent, Attach = HeadBase)
	UIslandWalkerHeadThruster ThrusterBelowLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelowLeft")
	UIslandWalkerHeadThrusterTargetableComponent ThrusterTargetableBelowLeft;
	UPROPERTY(DefaultComponent, Attach = "ThrusterBelowLeft")
	UIslandWalkerHeadThrusterImpactResponseComponent ThrusterShootableResponseBelowLeft;

	UPROPERTY(DefaultComponent, Attach = "HeadBase")
	UIslandWalkerAcidBlobLauncher AcidBlobLauncher0;

 	UPROPERTY(DefaultComponent, Attach = "HeadBase")
	UIslandWalkerAcidBlobLauncher AcidBlobLauncher1;

	UPROPERTY(DefaultComponent, Attach = "HeadBase")
	UIslandWalkerAcidBlobLauncher AcidBlobLauncher2;

	UPROPERTY(DefaultComponent, Attach = "HeadBase")
	UIslandWalkerAcidBlobLauncher AcidBlobLauncher3;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent FireSwoopTelegraphDecal;
	default FireSwoopTelegraphDecal.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent AcidPoolDecal;
	default AcidPoolDecal.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY()
	FIslandWalkerHeadFledSignature OnFled;

	UPROPERTY()
	UMaterialInterface PoweredDownEyeMaterial;
	
	UPROPERTY()
	UMaterialInterface PoweredDownUpperBodyMaterial;
	
	UPROPERTY()
	UMaterialInterface PoweredDownLowerBodyMaterial;

	UMaterialInterface PoweredUpEyeMaterial;
	UMaterialInterface PoweredUpUpperBodyMaterial;
	UMaterialInterface PoweredUpLowerBodyMaterial;

	bool bIsPoweredUp = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this);

		StumpRoot.SetupTarget();
		StumpRoot.Target.PowerDown();

		UHazeSkeletalMeshComponentBase BodyMesh = Cast<AHazeCharacter>(HeadComp.NeckCableOrigin.Owner).Mesh;
		PoweredUpEyeMaterial = BodyMesh.GetMaterial(1);
		PoweredUpUpperBodyMaterial = BodyMesh.GetMaterial(2);
		PoweredUpLowerBodyMaterial = BodyMesh.GetMaterial(3);
	}

	UFUNCTION()
	void BlockForceField()
	{
		StumpRoot.Target.BlockCapabilities(n"WalkerForceField", this);
	}
	
	UFUNCTION()
	void UnblockForceField()
	{
		StumpRoot.Target.UnblockCapabilities(n"WalkerForceField", this);
	}

	void PowerDown()
	{
		bIsPoweredUp = false;
		// No need to set material on head which is always hidden when powered up/down. We don't want to replace damaged material.
		UHazeSkeletalMeshComponentBase BodyMesh = Cast<AHazeCharacter>(HeadComp.NeckCableOrigin.Owner).Mesh;		
		BodyMesh.SetMaterial(1, PoweredDownEyeMaterial);
		BodyMesh.SetMaterial(2, PoweredDownUpperBodyMaterial);
		BodyMesh.SetMaterial(3, PoweredDownLowerBodyMaterial);
		StumpRoot.Target.PowerDown();
	}

	void PowerUp()
	{
		bIsPoweredUp = true;
		// No need to set material on head which is always hidden when powered up/down. We don't want to replace damaged material.
		UHazeSkeletalMeshComponentBase BodyMesh = Cast<AHazeCharacter>(HeadComp.NeckCableOrigin.Owner).Mesh;		
		BodyMesh.SetMaterial(1, PoweredUpEyeMaterial);
		BodyMesh.SetMaterial(2, PoweredUpUpperBodyMaterial);
		BodyMesh.SetMaterial(3, PoweredUpLowerBodyMaterial);
	}

	UFUNCTION(DevFunction)
	void TestPerchPoints()
	{
		HatchRoot.EnablePerches();
	}
}

class UWalkerHeadBackDividerComponent : USceneComponent
{
}


UCLASS(Abstract, meta = (DefaultActorLabel = "RangedGhost"))
class AAISanctuaryRangedGhost : ABasicAIFlyingCharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::StrafeMovement;

	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryRangedGhostBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"DarkPortalEscapeCapability");

	UPROPERTY(DefaultComponent)
	USceneComponent LightBirdTargetDummy;

	UPROPERTY(DefaultComponent, Attach = "LightBirdTargetDummy")
	ULightBirdTargetComponent LightBirdTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;
	default DarkPortalResponseComp.bOmnidirectional = true;
	default DarkPortalResponseComp.bDisableBirdAttach = true;

	UPROPERTY(DefaultComponent)
	UDarkPortalReactionComponent DarkPortalReactionComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	USanctuaryGhostDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerKnockdownSheet); // Replace this with a sheet containing animations in BP

	UPROPERTY()
	UMaterialInterface PetrifyMaterial;

	UPROPERTY()
	UMaterialInterface GhostMaterial;

	UPROPERTY()
	float BeamedFresnelPower = 2.0;

	UPROPERTY()
	FLinearColor BeamedColor;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	UBasicAIProjectileLauncherComponent Weapon;

	UMaterialInstanceDynamic GhostMaterialInstance;
	float InitialFresnelPower;
	FLinearColor InitialColor;

	TArray<UMaterialInterface> OriginalMaterials;

	// Uncomment this if you want to scrub pose in temporal logger etc
	// UPROPERTY(DefaultComponent)
	// UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UPROPERTY()
	TMap<int, UDecalComponent> TargetLocationDecals;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		BlockCapabilities(SanctuaryAICapabilityTags::LightProjectileCollision, this);

		// Setup Dynamic Materials
		GhostMaterialInstance = Material::CreateDynamicMaterialInstance(this, GhostMaterial);
		// for (int i = 0; i < Mesh.NumMaterials; i++)
		// 	Mesh.SetMaterial(i, GhostMaterialInstance);
		InitialFresnelPower = GhostMaterialInstance.GetScalarParameterValue(n"FresnelPower");
		InitialColor = GhostMaterialInstance.GetVectorParameterValue(n"EmissiveColor");

		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
		LightBirdResponseComp.OnAttached.AddUFunction(this, n"OnLightBirdAttached");
		LightBirdResponseComp.OnDetached.AddUFunction(this, n"OnLightBirdDetached");

		OriginalMaterials = Mesh.Materials;

		HealthComp.OnDie.AddUFunction(this, n"OnGhostDie");

		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"OnDarkPortalAttached");
		DarkPortalResponseComp.OnDetached.AddUFunction(this, n"OnDarkPortalDetached");
	}

	UFUNCTION()
	private void OnLightBirdAttached()
	{
		LightBirdTargetDummy.DetachFromParent(true);
	}

	UFUNCTION()
	private void OnLightBirdDetached()
	{
		LightBirdTargetDummy.AttachTo(this.RootComponent, AttachType = EAttachLocation::SnapToTarget);
	}

	UFUNCTION()
	private void OnDarkPortalDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		UnblockCapabilities(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock, Portal);
		ClearSettingsByInstigator(Portal);
	}

	UFUNCTION()
	private void OnDarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		BlockCapabilities(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock, Portal);
		UBasicAISettings::SetCircleStrafeSpeed(this, 200.0, Portal);
		UBasicAISettings::SetEvadeMoveSpeed(this, 200.0, Portal);
		UBasicAISettings::SetChaseMoveSpeed(this, 200.0, Portal);
	}

	UFUNCTION()
	private void OnGhostDie(AHazeActor ActorBeingKilled)
	{
		USanctuaryGhostCommonEventHandler::Trigger_OnDeath(this);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		for(int i = 0; i < Mesh.NumMaterials; ++i)
		{
			Mesh.SetMaterial(i, OriginalMaterials[i]);
		}
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		for(int i = 0; i < Mesh.NumMaterials; ++i)
		{
			Mesh.SetMaterial(i, PetrifyMaterial);
		}
	}
}
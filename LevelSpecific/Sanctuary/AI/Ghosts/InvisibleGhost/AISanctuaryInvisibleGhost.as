
UCLASS(Abstract, meta = (DefaultActorLabel = "InvisibleGhost"))
class AAISanctuaryInvisibleGhost : ABasicAIFlyingCharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::StrafeMovement;

	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryInvisibleGhostBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryInvisibleGhostIndicateCapability");
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
	USanctuaryInvisibleGhostVisibilityComp VisibilityComp;

	UPROPERTY(DefaultComponent)
	USanctuaryGhostDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);
	default RequestCapabilityComp.PlayerSheets.Add(BasePlayerKnockdownSheet); // Replace this with a sheet containing animations in BP

	UPROPERTY()
	UMaterialInterface PetrifyMaterial;

	UPROPERTY()
	UMaterialInterface IndicatorMaterial;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = RightAttach)
	UBasicAIMeleeWeaponComponent MeleeComp;

	TArray<UMaterialInterface> OriginalMaterials;

	// Uncomment this if you want to scrub pose in temporal logger etc
	// UPROPERTY(DefaultComponent)
	// UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TemporalScrubComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		BlockCapabilities(SanctuaryAICapabilityTags::LightProjectileCollision, this);

		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
		LightBirdResponseComp.OnAttached.AddUFunction(this, n"OnLightBirdAttached");
		LightBirdResponseComp.OnDetached.AddUFunction(this, n"OnLightBirdDetached");
		VisibilityComp.OnReveal.AddUFunction(this, n"OnReveal");
		VisibilityComp.OnHide.AddUFunction(this, n"OnHide");

		OriginalMaterials = Mesh.Materials;

		Mesh.SetVisibility(false, true);

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
	private void OnDarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		BlockCapabilities(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock, Portal);
		UBasicAISettings::SetCircleStrafeSpeed(this, 200.0, Portal);
		UBasicAISettings::SetEvadeMoveSpeed(this, 200.0, Portal);
		UBasicAISettings::SetChaseMoveSpeed(this, 200.0, Portal);
	}

	UFUNCTION()
	private void OnDarkPortalDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		UnblockCapabilities(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock, Portal);
		ClearSettingsByInstigator(Portal);
	}

	UFUNCTION()
	private void OnGhostDie(AHazeActor ActorBeingKilled)
	{
		USanctuaryGhostCommonEventHandler::Trigger_OnDeath(this);
	}

	UFUNCTION()
	void ResetMaterial()
	{
		for(int i = 0; i < Mesh.NumMaterials; ++i)
		{
			Mesh.SetMaterial(i, OriginalMaterials[i]);
		}
	}

	UFUNCTION()
	private void OnHide()
	{
		Mesh.SetVisibility(false, true);
	}

	UFUNCTION()
	private void OnReveal()
	{
		Mesh.SetVisibility(true, true);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{		
		ResetMaterial();
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		if(!VisibilityComp.bVisible) return;

		for(int i = 0; i < Mesh.NumMaterials; ++i)
		{
			Mesh.SetMaterial(i, PetrifyMaterial);
		}
	}
}

asset SkylineTorHammerPlayerSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineTorHammerAimPlayerCapability);	
}

UCLASS(Abstract)
class ASkylineTorHammer : ABasicAIGroundMovementCharacter
{	
	// Remove
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");

	// Add
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerIdleCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerRecallCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerHurtReactionCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerStolenAttackCameraCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerOffsetCapability");																
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerPlayerCollisionCapability");
	
	// Compounds
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerReturnBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerVolleyBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerMeleeBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerMeleeSecondBehaviourCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerMeleeGroundedBehaviourCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerSmashBehaviourCompoundCapability");	
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineTorHammerStolenCompoundCapability");

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	USkylineTorDamageCapsuleComponent DamageCapsule;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UEnforcerRocketLauncherProjectileIndicatorComponent Indicator;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerComponent HammerComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerPivotComponent PivotComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::TorHammer;
	default WhipResponse.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutline;

	UPROPERTY(DefaultComponent)
	UGravityWhipThrowResponseComponent ThrowResponseComp;
	default ThrowResponseComp.bNonThrowBlocking = true;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	UGravityWhipSlingAutoAimComponent SlingAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SlingAutoAimComp)
	UTargetableOutlineComponent WhipSlingOutlineComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerVolleyComponent VolleyComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerSmashComponent SmashComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerMeleeComponent MeleeComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UGravityBladeCombatTargetComponent BladeTarget;
	
	UPROPERTY(DefaultComponent, Attach = BladeTarget)
	UTargetableOutlineComponent BladeOutline;
	default BladeOutline.bAllowOutlineWhenNotPossibleTarget = false;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	UGravityBladeGrappleComponent GrappleTarget;
	default GrappleTarget.AutoAimMaxAngle = GravityBladeCombat::DefaultMaxCombatGrappleAngle;
	default GrappleTarget.MinimumDistanceFromPlayer = GravityBladeCombat::DefaultMinCombatGrappleDistance;
	default GrappleTarget.MaximumDistanceFromPlayer = GravityBladeCombat::DefaultMaxCombatGrappleDistance;
	default GrappleTarget.bIsCombatGrapple = true;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerStealComponent StealComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerWhipComponent WhipComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	USceneComponent ImpactLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	USceneComponent TopLocation;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	USceneComponent HeadLocation;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	UHazeCharacterSkeletalMeshComponent ShieldMesh;
	default ShieldMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	USkylineTorHammerBulletComponent BulletComp;

	UPROPERTY(DefaultComponent, Attach=InvertedFauxRotateComp)
	UFauxPhysicsConeRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent InvertedFauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = "MeshOffsetComponent")
	USceneComponent TranslationComp;

	UPROPERTY(DefaultComponent, Attach = TranslationComp)
	USceneComponent ExtraTranslationComp;

	UPROPERTY(DefaultComponent)
	USkylineTorHammerStolenComponent StolenComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent PlayerCollision;
	default PlayerCollision.CollisionProfileName = CollisionProfile::BlockOnlyPlayerCharacter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 400.0, this);
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
		
		UBasicAISettings::SetChaseMinRange(this, 150, this);
		UBasicAISettings::SetChaseMoveSpeed(this, 700, this);
		UBasicAISettings::SetPriorityTarget(this, EHazePlayer::Mio, this);
		UBasicAISettings::SetCircleStrafeMinRange(this, 0, this);
		
		UMovementGravitySettings::SetGravityScale(this, 20, this);

		BlockCapabilities(n"GroundMovement", this);
		BlockCapabilities(n"SplineMovement", this);

		HealthBarComp.SetHealthBarEnabled(false);

		ShieldMesh.SetVisibility(false, true);

		TranslationComp.AttachTo(FauxRotateComp);
		Mesh.AttachTo(ExtraTranslationComp);
		ShieldMesh.AttachTo(ExtraTranslationComp);
	}

	void SetupHammerHolder(AHazeActor HammerHolder)
	{
		HammerComp.HoldHammerComp = USkylineTorHoldHammerComponent::Get(HammerHolder);
		ProjectileComp.Launcher = HammerHolder;
	
		// VO needs events called on SkylineTorHammer to be relayed to ASkylineTor
        EffectEvent::LinkActorToReceiveEffectEventsFrom(HammerHolder, this);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return CapsuleComponent.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
}
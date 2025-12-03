event void FSanctuaryDodgerDetectedPlayerSignature();

UCLASS(Abstract)
class AAISanctuaryDodger : ABasicAIFlyingCharacter
{
	// Do not use pathfinding, just move straight to destination
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDodgerBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicOptimizeFitnessStrafingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryDodgerHeightCapability");

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalDebugComponent DarkPortaDebug;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComp;

	UPROPERTY(DefaultComponent)
	UProjectileProximityDetectorComponent ProjectileProximityComp;
	default ProjectileProximityComp.DetectionShape.SphereRadius = 600.0;

	UPROPERTY(DefaultComponent)
	UHazeEffectEventHandlerComponent EffectEventComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Jaw")
	UBasicAIProjectileLauncherComponent Weapon;

	UPROPERTY(DefaultComponent)
	UBasicAIFleeingComponent FleeingComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCombatHitStopComponent HitStopComp;

	UPROPERTY(DefaultComponent)
	USanctuaryDodgerGrabComponent GrabComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USanctuaryDodgerSleepComponent SleepComp;

	UPROPERTY(DefaultComponent)
	USanctuaryDodgerLandComponent LandComp;

	UPROPERTY(DefaultComponent)
	UScenepointUserComponent ScenepointComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UBasicAISettings Settings;
	USanctuaryDodgerSettings DodgerSettings;

	UPROPERTY(EditAnywhere)
	UAnimSequence FlyAnim;

	UPROPERTY(EditAnywhere)
	UAnimSequence SleepAnim;

	bool bDetectedPlayer;
	UPROPERTY()
	FSanctuaryDodgerDetectedPlayerSignature OnDetectedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"OnDarkPortalAttached");
		DarkPortalResponseComp.OnDetached.AddUFunction(this, n"OnDarkPortalDetached");
		DarkPortalResponseComp.OnExploded.AddUFunction(this, n"OnExploded");

		TargetingComponent.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");

		this.JoinTeam(SanctuaryDodgerTags::SanctuaryDodgerTeam);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 200;
	}

	UFUNCTION()
	private void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{
		if(bDetectedPlayer) return;
		bDetectedPlayer = true;
		OnDetectedPlayer.Broadcast();
	}

	UFUNCTION()
	private void OnDarkPortalDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		UnblockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock, this);
		ClearSettingsByInstigator(DarkPortalResponseComp);
		LightBirdTargetComp.Enable(this);
	}

	UFUNCTION()
	private void OnDarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		BlockCapabilities(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock, this);
		UBasicAISettings::SetCircleStrafeSpeed(this, 200.0, DarkPortalResponseComp);
		UBasicAISettings::SetEvadeMoveSpeed(this, 200.0, DarkPortalResponseComp);
		UBasicAISettings::SetChaseMoveSpeed(this, 200.0, DarkPortalResponseComp);
		LightBirdTargetComp.Disable(this);
	}

	UFUNCTION()
	private void OnExploded(ADarkPortalActor Portal, FVector Direction)
	{
		HealthComp.Die();
	}
}

namespace SanctuaryDodgerTags
{
	const FName SanctuaryDodgerTeam = n"SanctuaryDodgerTeam";
	const FName SanctuaryDodgerGrab = n"SanctuaryDodgerGrab";
	const FName SanctuaryDodgerDarkPortalBlock = n"SanctuaryDodgerDarkPortalBlock";
	const FName SanctuaryDodgerLandBlock = n"SanctuaryDodgerLandBlock";
	const FName SanctuaryDodgerChargeBlock = n"SanctuaryDodgerChargeBlock";
}
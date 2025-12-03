UCLASS(Abstract)
class AAIIslandBeamTurretron : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldBubbleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandBeamTurretronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTurretronDamagePlayerOnTouchCapability");

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeIgnoreActorCollisionComponent GrenadeIgnoreCollisionComp;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;
	
	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	USceneComponent MeshHolderPivot;

	UPROPERTY(DefaultComponent, Attach=MeshHolderPivot)
	USceneComponent MeshTurretPivot;

	UPROPERTY(DefaultComponent, Attach=MeshTurretPivot)
	USceneComponent CannonPivot;

	UPROPERTY(DefaultComponent, Attach=CannonPivot)
	UBasicAIProjectileLauncherComponent LauncherComp;

	UPROPERTY(DefaultComponent)
	USceneComponent Muzzle;

	UPROPERTY(DefaultComponent)
	UIslandBeamTurretronTrackingLaserComponent TrackingLaserComp;

	UPROPERTY(DefaultComponent)
	UIslandBeamTurretronInactiveComponent InactiveComp;
	default InactiveComp.bIsOwnerActive = true;
	
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerSheets.Add(FitnessQueueSheet);

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(EditAnywhere)
	UIslandBeamTurretronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		// Override default settings
		if (Settings != nullptr)
			ApplyDefaultSettings(Settings);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		return ActorLocation + FVector::UpVector * 130;
	}

}
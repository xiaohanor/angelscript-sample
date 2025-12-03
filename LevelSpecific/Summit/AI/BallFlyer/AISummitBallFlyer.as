UCLASS(Abstract)
class AAISummitBallFlyer : ABasicAICharacter
{
	default AnimComp.BaseMovementTag = LocomotionFeatureAITags::Flying;
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapsuleComponent.CapsuleRadius = 200;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	default DisableComp.AutoDisableRange = 50000.0;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitBallFlyerCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAIFlyAlongSplineMovementCapability");

	UPROPERTY(DefaultComponent, Attach = Root)
	UTeenDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UBasicAINetworkedProjectileLauncherComponent Launcher; // Needs to be networked since projectiles can be hit by acid

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResposeComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Ignore pathfinding
		UPathfollowingSettings::SetIgnorePathfinding(this, true, this);

		OnRespawn(); // In case not spawned by spawner
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");
		
		// Mio will interact the most with flyer
		SetActorControlSide(Game::Mio);

		Super::BeginPlay();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Always go for the acid shooter
		TargetingComponent.SetTarget(Game::Mio);
	}
}

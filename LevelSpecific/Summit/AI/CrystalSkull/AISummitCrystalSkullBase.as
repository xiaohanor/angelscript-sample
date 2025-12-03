UCLASS(Abstract)
class AAISummitCrystalSkullBase : ABasicAIFlyingCharacter
{
	default CapsuleComponent.CapsuleRadius = 2000;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	default DisableComp.AutoDisableRange = 200000.0;

	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIFlyingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSkullMovementCapability");
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalSkullTailSmashCapability");
	
	default MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonTailSmashModeTargetableComponent SmashTargetable;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitCrystalSkullComponent CrystalSkullComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USummitArcProjectileLauncher ArcLauncher;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent TailResponseComp;
	default TailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	UStormSiegeMagicBarrierResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HealthComp.OnDie.AddUFunction(this, n"OnBarrierDeathResponse");
		CrystalSkullsTeam::Join(this);
	}

	UFUNCTION()
	void OnBarrierDeathResponse(AHazeActor ActorBeingKilled)
	{
		ResponseComp.TriggerTarget();
	}
}

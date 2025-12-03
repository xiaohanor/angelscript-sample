UCLASS(Abstract)
class AAISummitCrystalChaser : ABasicAIFlyingCharacter
{
	default CapsuleComponent.CapsuleRadius = 1000;
	default CapsuleComponent.CapsuleHalfHeight = CapsuleComponent.CapsuleRadius;

	default DisableComp.AutoDisableRange = 200000.0;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitCrystalChaserCompoundCapability");
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
	UBasicAIProjectileLauncherComponent Launcher;

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
	}

	UFUNCTION()
	void OnBarrierDeathResponse(AHazeActor ActorBeingKilled)
	{
		ResponseComp.TriggerTarget();
	}
}

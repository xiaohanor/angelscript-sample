class UAITundraFishieEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnStartPatrol() {}

	UFUNCTION(BlueprintEvent)
	void OnStopPatrol() {}

	UFUNCTION(BlueprintEvent)
	void OnStartChase() {}

	UFUNCTION(BlueprintEvent)
	void OnStopChase() {}

	UFUNCTION(BlueprintEvent)
	void OnBite() {}
}

UCLASS(Abstract)
class AAITundraChasingFishie : ABasicAICharacter
{
	default CapsuleComponent.bOffsetBottomToAttachParentLocation = false;

	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimmingMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraChasingFishieBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimAlongSplineMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraFishieSwimmingNoCollisionMovementCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTundraFishieComponent FishieComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = "CharacterMesh0", AttachSocket = "Head")
	UTundraFishieMouthComp MouthComp;
	default MouthComp.RelativeLocation = FVector(20.0, 0.0, 40.0);
	default MouthComp.RelativeRotation = FRotator(70.0, 0.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnRespawn();		
		UHazeActorRespawnableComponent::Get(this).OnPostRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Tasty otter!
		SetActorControlSide(Game::Mio);
		TargetingComponent.SetTarget(Game::Mio);
	}

	UFUNCTION(BlueprintCallable)
	void StopChasing()
	{
		UTundraFishieSettings::SetChaseRangeAbove(this, 0.0, this, EHazeSettingsPriority::Script);
		UTundraFishieSettings::SetChaseRangeBelow(this, 0.0, this, EHazeSettingsPriority::Script);
		UTundraFishieSettings::SetChaseRangeAhead(this, 0.0, this, EHazeSettingsPriority::Script);
		UTundraFishieSettings::SetChaseRangeBehind(this, 0.0, this, EHazeSettingsPriority::Script);
	}

	UFUNCTION(BlueprintCallable)
	void ResumeChasing()
	{
		UTundraFishieSettings::ClearChaseRangeAbove(this, this);
		UTundraFishieSettings::ClearChaseRangeBelow(this, this);
		UTundraFishieSettings::ClearChaseRangeAhead(this, this);
		UTundraFishieSettings::ClearChaseRangeBehind(this, this);
	}
}

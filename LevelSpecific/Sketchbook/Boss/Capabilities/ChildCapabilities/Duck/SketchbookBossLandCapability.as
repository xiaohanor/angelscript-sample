class USketchbookBossLandCapability : USketchbookDuckBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	const float LandDuration = 3;
	FVector TargetLocation;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DuckComp.SubPhase != ESketchbookDuckBossSubPhase::Land)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TargetLocation.Distance(Owner.ActorLocation) <= KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetLocation = Boss.JumpComp.LandingLocation;
		Boss.Mesh.SetAnimTrigger(n"StartLanding");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		Boss.EndMainAttackSequence();

		Owner.SetActorLocation(TargetLocation);
		Boss.Idle(1);

		USketchbookBossEffectEventHandler::Trigger_OnLand(Boss);

		Boss.Mesh.SetAnimTrigger(n"Land");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, DuckComp.LandSpeed);
		Owner.SetActorLocation(NewLocation);
	}
};
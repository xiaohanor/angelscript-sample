class USketchbookBossEnterArenaCapability : USketchbookBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.bEnteredArena)
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
	 	TargetLocation = Owner.ActorLocation;
		TargetLocation.X = 0;
		Boss.Mesh.SetAnimTrigger(n"EnterArena");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.bEnteredArena = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, SketchbookBoss::Settings::EnterArenaSpeed);
		Owner.SetActorLocation(NewLocation);
	}
};
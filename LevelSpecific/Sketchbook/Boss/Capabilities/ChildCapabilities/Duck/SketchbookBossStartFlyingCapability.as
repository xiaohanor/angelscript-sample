class USketchbookBossStartFlyingCapability : USketchbookDuckBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DuckComp.SubPhase != ESketchbookDuckBossSubPhase::StartFlying)
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
	 	TargetLocation = Owner.ActorLocation + FVector::UpVector * DuckComp.HoverHeight;

		USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);

		Boss.Mesh.SetAnimBoolParam(n"StartFlying", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.SetActorLocation(TargetLocation);
		DuckComp.SubPhase = ESketchbookDuckBossSubPhase::Flying;

		Boss.Mesh.SetAnimBoolParam(n"StartFlying", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, DuckComp.LiftSpeed);
		Owner.SetActorLocation(NewLocation);
	}
};
class USketchbookBossFlyToCornerCapability : USketchbookDemonBossChildCapability
{
	FVector TargetLocation;
	const float FlySpeed = 1000;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DemonComp.SubPhase != ESketchbookDemonBossSubPhase::FlyToCorner)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Owner.ActorLocation.Distance(TargetLocation) <= KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetLocation = Boss.ActorLocation;
		TargetLocation.Z = Boss.ArenaFloorZ + 450;

		USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);

		Boss.Mesh.SetAnimTrigger(n"Fly");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DemonComp.SubPhase = ESketchbookDemonBossSubPhase::Shoot;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, FlySpeed);
		Owner.SetActorLocation(NewLocation);
	}
};
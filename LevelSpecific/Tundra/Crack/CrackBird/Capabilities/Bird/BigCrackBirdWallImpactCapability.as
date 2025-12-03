class UBigCrackBirdWallImpactCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	bool bLanded = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.bHitWall)
			return false;

		if(bLanded)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bLanded)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Bird.bIsLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bird.bRunningAway = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Pawn);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Owner);

		const FVector Start = Owner.ActorLocation;
		const FVector End = Owner.ActorLocation + FVector::DownVector * 01000;
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(Start, End);

		if(GroundHit.bBlockingHit)
		{
			Owner.SetActorLocation(Math::VInterpConstantTo(Owner.ActorLocation, GroundHit.ImpactPoint, DeltaTime, 700));
			if(Owner.ActorLocation.Distance(GroundHit.ImpactPoint) <= SMALL_NUMBER)
				bLanded = true;
		}
		else
			bLanded = true;
	}
};
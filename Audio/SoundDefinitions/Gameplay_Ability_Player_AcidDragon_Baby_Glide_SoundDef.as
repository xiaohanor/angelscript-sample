
UCLASS(Abstract)
class UGameplay_Ability_Player_AcidDragon_Baby_Glide_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StoppedGliding(){}

	UFUNCTION(BlueprintEvent)
	void StartedGliding(){}

	UFUNCTION(BlueprintEvent)
	void AirBoostActivated(){}

	/* END OF AUTO-GENERATED CODE */
	
	UPlayerAcidBabyDragonComponent DragonComp;
	
	UPROPERTY(BlueprintReadWrite)
	float WingFlapDuckingValue = 1.0;

	UPROPERTY(BlueprintReadOnly)
	float DistanceToGround = 0.0;

	float MAX_GROUND_TRACE_DIST = 1000;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SetPlayerOwner(Game::GetMio());
		DragonComp = UPlayerAcidBabyDragonComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool CanActivate() const
	{
		return DragonComp.bIsGliding;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DragonComp.bIsGliding;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !DragonComp.bIsGliding;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector Start = PlayerOwner.ActorLocation;
		const FVector End = Start + (FVector::UpVector * -MAX_GROUND_TRACE_DIST);

		FHazeTraceSettings Trace;
		Trace.UseLine();
		Trace.TraceWithPlayer(PlayerOwner);
		Trace.IgnoreActor(PlayerOwner);
		Trace.IgnoreActor(DragonComp.BabyDragon);
		
		if(IsDebugging())
			Trace.DebugDrawOneFrame();

		FHitResult Result = Trace.QueryTraceSingle(Start, End);
		if(Result.bBlockingHit)
			DistanceToGround = Math::Saturate(Result.Distance / MAX_GROUND_TRACE_DIST);
		else 
			DistanceToGround = 1.0;

		WingFlapDuckingValue = Math::FInterpTo(WingFlapDuckingValue, 1.0, DeltaSeconds, 2.0);
	}

}
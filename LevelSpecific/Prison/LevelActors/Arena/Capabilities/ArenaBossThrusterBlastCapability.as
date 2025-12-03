class UArenaBossThrusterBlastCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::ThrusterBlast;
	default bResetToIdleOnDeactivation = false;
	default WindDownDuration = 3.0;

	AHazePlayerCharacter TargetPlayer;
	FVector TargetLocation;

	int MaxBlastAmount = 12;
	int CurrentBlastAmount = 0;

	float TimeSincePlayerSwap = 0.0;
	float SwapPlayerDuration = 5.0;

	float TimeSinceBlast = 0.0;
	float BlastInterval = 2.0;

	UHazeAudioEvent PlatformImpulseAudioEvent;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		TargetPlayer = Game::Mio;

		CurrentBlastAmount = 0;

		Boss.AnimationData.ThrusterAlpha = 0.0;

		UArenaBossEffectEventHandler::Trigger_ThrusterBlastStateEntered(Boss);		
		Audio::GetAudioEventAssetByName(FName("Play_World_Boss_Prison_ArenaBoss_Platform_Impact"), PlatformImpulseAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Boss.AnimationData.ThrusterAlpha = 1.0;

		Boss.ActivateState(EArenaBossState::LaserEyes);

		UArenaBossEffectEventHandler::Trigger_ThrusterBlastStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!bChargedUp)
		{
			FVector TargetLoc = Boss.DefaultLocation + (FVector::UpVector * 1200.0);
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 0.75);
			Boss.SetActorLocation(Loc);
		}

		if (bWindingDown)
		{
			FVector TargetLoc = Boss.DefaultLocation;
			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, 1200.0);
			Boss.SetActorLocation(Loc);
		}

		if (IsChargingUpOrWindingDown())
			return;

		TimeSinceBlast += DeltaTime;
		if (TimeSinceBlast >= BlastInterval)
			TriggerBlast();

		FVector PlayerLoc = TargetPlayer.IsPlayerDead() ? TargetPlayer.OtherPlayer.ActorLocation : TargetPlayer.ActorLocation;

		FVector TargetLoc = PlayerLoc;
		TargetLoc.Z = Boss.DefaultLocation.Z + 1200.0;

		float InterpSpeed = Math::GetMappedRangeValueClamped(FVector2D(800.0, 500.0), FVector2D(600.0, 450.0), Boss.ActorLocation.Dist2D(TargetLoc, FVector::UpVector));

		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, InterpSpeed);
		Boss.SetActorLocation(Loc);

		TimeSincePlayerSwap += DeltaTime;
		if (TimeSincePlayerSwap >= SwapPlayerDuration)
			SwapTargetPlayer();
	}

	void SwapTargetPlayer()
	{
		TimeSincePlayerSwap = 0.0;
		TargetPlayer = TargetPlayer.OtherPlayer;
	}

	void TriggerBlast()
	{
		TimeSinceBlast = 0.0;
		Boss.AnimationData.bThrusterBlasting = true;
		Boss.SetAnimBoolParam(n"ThrusterBlast", true);

		CurrentBlastAmount++;

		UArenaBossEffectEventHandler::Trigger_ThrusterBlast(Boss);

		if (CurrentBlastAmount >= MaxBlastAmount)
			Timer::SetTimer(this, n"DelayedWindDown", 1.0);

		FHazeTraceSettings KillTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		KillTrace.UseCapsuleShape(250.0, 2000.0);
		FOverlapResultArray KillOverlapResults = KillTrace.QueryOverlaps(Boss.ActorLocation);
		for (FOverlapResult Result : KillOverlapResults)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::DownVector, 5.0), Boss.ThrusterDamageEffect, Boss.ThrusterDeathEffect);
		}

		FHazeTraceSettings PhysicsTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		PhysicsTrace.UseCapsuleShape(500.0, 2000.0);
		FOverlapResultArray PhysicsOverlapResults = PhysicsTrace.QueryOverlaps(Boss.ActorLocation);
		for (FOverlapResult Result : PhysicsOverlapResults)
		{
			FVector ImpulseLoc = Boss.ActorLocation - (FVector::UpVector * 1100.0);
			FauxPhysics::ApplyFauxImpulseToActorAt(Result.Actor, ImpulseLoc, -FVector::UpVector * 400.0);
		}

		if(PlatformImpulseAudioEvent != nullptr && PhysicsOverlapResults.Num() > 0)
		{
			FHazeAudioFireForgetEventParams Params;
			Params.Transform = PhysicsOverlapResults[0].Actor.ActorTransform;

			AudioComponent::PostFireForget(PlatformImpulseAudioEvent, Params);
		}
	}

	UFUNCTION()
	void DelayedWindDown()
	{
		StartWindingDown();
	}

	void ChargedUp() override
	{
		Super::ChargedUp();
	}
	
	void StartWindingDown() override
	{
		Super::StartWindingDown();
		
		UArenaBossEffectEventHandler::Trigger_ThrusterBlastStateWindDown(Boss);
	}
}

enum EArenaBossThrusterBlastState
{
	LockingOn,
	Charging,
	Blasting,
}
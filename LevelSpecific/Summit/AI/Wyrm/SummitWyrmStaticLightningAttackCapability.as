class USummitWyrmStaticLightningAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitWyrmStaticLightningAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AAISummitWyrm Wyrm;
	UStormSiegeDetectPlayerComponent DetectComp;

	float NextAttackTime;

	float DistanceIntervals = 500.0;
	float CurrentDistance;
	float Rate = 0.02;
	float NextLightningTime;
	float MaxRange; 
	float RandomOffset = 3000.0;

	int TargetIndex;

	bool bCompletedAttack;

	FVector LightningStartPoint;
	FVector PlayerAttackPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DetectComp = UStormSiegeDetectPlayerComponent::Get(Owner);
		Wyrm = Cast<AAISummitWyrm>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DetectComp.HasAvailablePlayers())
			return false;

		if (Time::GameTimeSeconds < NextAttackTime)
			return false;

		if (!Wyrm.bSiegeActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bCompletedAttack)
			return true;
		
		if (!Wyrm.bSiegeActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bCompletedAttack = false;
		CurrentDistance = DistanceIntervals;

		if(DetectComp.GetAvailablePlayers().Num() > 1)
		{
			TargetIndex = Math::RandRange(0, 1);
		}
		else
		{
			TargetIndex = 0;
		}

		MaxRange = (DetectComp.GetAvailablePlayers()[TargetIndex].ActorLocation - Owner.ActorLocation).Size();
		PlayerAttackPoint = DetectComp.GetAvailablePlayers()[TargetIndex].ActorLocation;
		MaxRange += 5000.0;

		NextAttackTime = Time::GameTimeSeconds + Wyrm.LightningWaitTime;

		LightningStartPoint = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > NextLightningTime)
		{
			NextLightningTime = Time::GameTimeSeconds + Rate;

			FVector AttackDirection = PlayerAttackPoint - Owner.ActorLocation;
			AttackDirection += FVector(Math::RandRange(-RandomOffset, RandomOffset), Math::RandRange(-RandomOffset, RandomOffset), Math::RandRange(-RandomOffset, RandomOffset)); 
			AttackDirection.Normalize();

			FStormSiegeLightningStrikeParams Params;
			Params.Start = LightningStartPoint;
			FVector EndPoint = Owner.ActorLocation + AttackDirection * CurrentDistance;
			Params.End = EndPoint;
			Params.BeamWidth = 4.0;
			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(Owner, Params);
			
			FHazeTraceDebugSettings Debug;
			Debug.TraceColor = FLinearColor::Red;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseBoxShape(FVector(500.0));
			TraceSettings.IgnoreActor(Owner);

			FHitResultArray HitArray = TraceSettings.QueryTraceMulti(LightningStartPoint, EndPoint);

			for (FHitResult Hit : HitArray)
			{
				if (Hit.bBlockingHit)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

					if (Player != nullptr)
						Player.DamagePlayerHealth(0.3);
				}
			} 

			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayWorldCameraShake(Wyrm.CameraShake, this, LightningStartPoint, 10000.0, 80000.0, Scale = 0.5);
			}

			CurrentDistance += DistanceIntervals;
			LightningStartPoint = Owner.ActorLocation + AttackDirection * CurrentDistance;


			if (CurrentDistance > MaxRange)
				bCompletedAttack = true;
		}
	}	
}
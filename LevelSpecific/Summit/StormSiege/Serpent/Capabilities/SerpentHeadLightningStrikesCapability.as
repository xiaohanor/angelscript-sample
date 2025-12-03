class USerpentHeadLightningStrikesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASerpentHead SerpentHead;

	float NextAttackTime;

	float DistanceIntervals = 180.0;
	float CurrentDistance;
	float Rate = 0.01;
	float NextLightningTime;
	float MaxRange; 
	float RandomOffset = 4000.0;

	int TargetIndex;

	bool bCompletedAttack;
	bool bMioTarget;

	FVector TargetLoc;
	FVector LightningStartPoint;
	FVector PlayerAttackPoint;
	FVector LastPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SerpentHead = Cast<ASerpentHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SerpentHead.bRunLightningStrikes)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bCompletedAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

		if (bMioTarget)
			TargetLoc = Game::Mio.ActorLocation;
		else
			TargetLoc = Game::Zoe.ActorLocation;

		bMioTarget = !bMioTarget;
		LightningStartPoint = Owner.ActorLocation;
		PlayerAttackPoint = LightningStartPoint;
		LastPoint = LightningStartPoint;

		bCompletedAttack = false;
		CurrentDistance = 0.0;
		float TotalDist = (LightningStartPoint - TargetLoc).Size();
		float Iterations = TotalDist / DistanceIntervals;
		Iterations /= 1.8;
		MaxRange = DistanceIntervals * Iterations;
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

			FVector AttackForwardDirection = TargetLoc - PlayerAttackPoint;
			// AttackDirection += FVector(Math::RandRange(-RandomOffset, RandomOffset), Math::RandRange(-RandomOffset, RandomOffset), Math::RandRange(-RandomOffset, RandomOffset)); 
			AttackForwardDirection.Normalize();
			FVector EndPoint = PlayerAttackPoint + AttackForwardDirection * CurrentDistance;
			FVector AttackRight = AttackForwardDirection.CrossProduct(FVector::UpVector);
			FVector AttackUp = AttackRight.CrossProduct(AttackForwardDirection);
			EndPoint += AttackRight * Math::RandRange(-RandomOffset, RandomOffset);
			EndPoint += AttackUp * Math::RandRange(-RandomOffset, RandomOffset);

			FStormSiegeLightningStrikeParams Params;
			Params.Start = LastPoint;
			Params.End = EndPoint;
			Params.BeamWidth = 2.0;
			UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(Owner, Params);
			

			//TODO Get halfway point and sphere trace instead
			// FHazeTraceDebugSettings Debug;
			// Debug.TraceColor = FLinearColor::Red;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseBoxShape(FVector(1000.0));
			// TraceSettings.IgnoreActor(Owner);

			FHitResultArray HitArray = TraceSettings.QueryTraceMulti(LastPoint, EndPoint);

			for (FHitResult Hit : HitArray)
			{
				if (Hit.bBlockingHit)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

					if (Player != nullptr)
						Player.DamagePlayerHealth(0.3);
				}
			} 

			// for (AHazePlayerCharacter Player : Game::Players)
			// {
			// 	Player.PlayWorldCameraShake(Wyrm.CameraShake, this, LightningStartPoint, 10000.0, 80000.0, Scale = 0.5);
			// }

			LastPoint = EndPoint;
			PlayerAttackPoint += (TargetLoc - LightningStartPoint).GetSafeNormal() * DistanceIntervals;
			CurrentDistance += DistanceIntervals;
			// LightningStartPoint = EndPoint;

			if (CurrentDistance > MaxRange)
				bCompletedAttack = true;
		}
	}	


	// float WaitDuration = 0.25;
	// float NextActivationTime;

	// bool bMioTarget = true;

	// FVector TargetLoc;
	// FVector CurrentLoc;
	// FVector Direction;
	// FVector RightVector;

	// float RightOffset = 1300.0;
	// float Speed = 3100.0;

	// bool bCompletedAttack;

	// float StrikeRate = 0.6;
	// float StrikeTime;

	// float MaxAttackTime = 3.5;
	// float AttackTime;

	// float Damage = 0.4;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	SerpentHead = Cast<ASerpentHead>(Owner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (!SerpentHead.bIsActive)
	// 		return false;

	// 	if (!SerpentHead.bRunLightningStrikes)
	// 		return false;

	// 	if (Time::GameTimeSeconds < NextActivationTime)
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (!SerpentHead.bIsActive)
	// 		return true;

	// 	if (bCompletedAttack)
	// 		return true;

	// 	return false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	if (bMioTarget)
	// 		TargetLoc = Game::Mio.ActorLocation;
	// 	else
	// 		TargetLoc = Game::Mio.OtherPlayer.ActorLocation;

	// 	CurrentLoc = SerpentHead.ActorLocation - FVector::UpVector * 10000.0;
	// 	Direction = (TargetLoc - CurrentLoc).GetSafeNormal();
	// 	RightVector = FVector::UpVector.CrossProduct(Direction);

	// 	AttackTime = MaxAttackTime;
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	NextActivationTime = Time::GameTimeSeconds + WaitDuration;
	// 	bMioTarget = !bMioTarget;
	// 	bCompletedAttack = false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	AttackTime -= DeltaTime;
	// 	StrikeTime -= DeltaTime;

	// 	while (StrikeTime < 0.0)
	// 	{
	// 		StrikeTime += StrikeRate;

	// 		SerpentHead.SpawnLightningStrike(CurrentLoc);
	// 		SerpentHead.SpawnLightningStrike(CurrentLoc + RightVector * RightOffset);
	// 		SerpentHead.SpawnLightningStrike(CurrentLoc + RightVector * -RightOffset);

	// 		CurrentLoc += Direction * Speed;

	// 		if ((CurrentLoc - TargetLoc).Size() < Speed)
	// 			bCompletedAttack = true;
	// 	}

	// 	FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
	// 	TraceSettings.UseSphereShape(RightOffset * 2.0);

	// 	FHitResultArray Hits = TraceSettings.QueryTraceMulti(CurrentLoc, CurrentLoc + FVector::ForwardVector);

	// 	for (FHitResult Hit : Hits)
	// 	{
	// 		if (Hit.bBlockingHit)
	// 		{
	// 			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
	// 			if (Player != nullptr)
	// 			{
	// 				Player.DamagePlayerHealth(Damage);
	// 			}
	// 		}
	// 	}

	// 	if (AttackTime <= 0.0)
	// 		bCompletedAttack = true;
	// }

	// default CapabilityTags.Add(n"SummitWyrmStaticLightningAttackCapability");
	
	// default TickGroup = EHazeTickGroup::Gameplay;
	// default TickGroupOrder = 100;

	// AAISummitWyrm Wyrm;
	// UStormSiegeDetectPlayerComponent DetectComp;
};
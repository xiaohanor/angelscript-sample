class UStormDragonIntroLightningCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonIntroLightningCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonIntro StormDragon;
	ALightningAttackpoint LightningAttackPoint;

	FVector WorldTracePoint;

	int Index;
	int MaxIndex;

	float TelegraphTime;
	float AttackTime;
	float AdditionalLightningAmount = 5000.0;

	float SparkRate = 0.05;
	float SparkTime;
	int SparkIndex;

	bool bStartAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonIntro>(Owner);
		MaxIndex = StormDragon.LightningPoints.Num() - 1;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return false;

		if (!StormDragon.bRunLightningAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return true;

		if (!StormDragon.bRunLightningAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bStartAttack = false;

		SparkIndex = 0;

		Index++;
		if (Index > MaxIndex)
			Index = 0;
		
		LightningAttackPoint = StormDragon.LightningPoints[Index];
		WorldTracePoint = StormDragon.LightningPoints[Index].ActorLocation;
		TelegraphTime = Time::GameTimeSeconds + StormDragonIntroAttackSettings::LightningTelegraphDuration;
		LightningAttackPoint.ActivateLightningTelegraph();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// LightningAttackPoint.ElectricityField.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if (Time::GameTimeSeconds > TelegraphTime)
		{
			FHazeTraceDebugSettings DebugSettings;
			DebugSettings.TraceColor = FLinearColor::Red;
			DebugSettings.Thickness = 125.0;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			TraceSettings.UseBoxShape(FVector(3000.0, 9000.0, 1400.0));
			// TraceSettings.DebugDraw(DebugSettings);

			FHitResultArray HitArray = TraceSettings.QueryTraceMulti(WorldTracePoint, WorldTracePoint + StormDragon.LightningPoints[Index].ActorForwardVector);

			for (FHitResult Hit : HitArray)
			{
				if (Hit.bBlockingHit)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

					if (Player != nullptr)
					{
						if (!Player.IsPlayerDead())
						{
							Player.KillPlayer();
							UPlayerHealthSettings::SetEnableRespawnTimer(Player, true, this);
							UPlayerHealthSettings::SetRespawnTimer(Player, 2.0, this);
							Print("KillPlayer");
						}
					}
				}
			}

			if (LightningAttackPoint.bTelegraphActive)
				LightningAttackPoint.DeactivateLightningTelegraph();
			
			if (!bStartAttack)
			{
				bStartAttack = true;
				AttackTime = Time::GameTimeSeconds + StormDragonIntroAttackSettings::LightningStrikeDuration;
			}

			if (SparkIndex < LightningAttackPoint.GetAllSubPoints().Num() - 1 && Time::GameTimeSeconds > SparkTime)
			{
				SparkTime = Time::GameTimeSeconds + SparkRate;
				ULightningSubPoint Point = LightningAttackPoint.GetAllSubPoints()[SparkIndex];

				FStormSiegeLightningStrikeParams Params;

				FVector Dir = (Point.WorldLocation - StormDragon.ActorLocation); 
				FVector NewDir = -Dir.ConstrainToPlane(FVector::UpVector);
				FVector NewStart = Point.WorldLocation + NewDir;

				// Params.Start = StormDragon.ActorLocation;
				Params.Start = NewStart;
				Params.End = Point.WorldLocation + (Dir.GetSafeNormal() * AdditionalLightningAmount);
				Params.BeamWidth = 30.0;
				UStormSiegeLightningEffectsHandler::Trigger_LightningStrike(StormDragon, Params);

				SparkIndex++;
			}

			if (Time::GameTimeSeconds > AttackTime)
				StormDragon.bRunLightningAttack = false;
		}
		else
		{
			//Telegraph
			for (ULightningSubPoint Point : LightningAttackPoint.GetAllSubPoints())
			{
				FVector Offset = (StormDragon.ActorLocation - Point.WorldLocation); 
				FVector NewDir = Offset.ConstrainToPlane(FVector::UpVector);
				FVector NewStart = Point.WorldLocation + NewDir;

				FVector Dir = (Point.WorldLocation - StormDragon.ActorLocation).GetSafeNormal(); 
				// Debug::DrawDebugLine(NewStart, Point.WorldLocation + (Dir * AdditionalLightningAmount), FLinearColor::Blue, 25.0);
			}
		}
	}	
}
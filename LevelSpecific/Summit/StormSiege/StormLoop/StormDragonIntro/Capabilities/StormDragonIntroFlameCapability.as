class UStormDragonIntroFlameCapability : UHazeCapability
{
	default CapabilityTags.Add(n"StormDragonIntroFlameCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AStormDragonIntro StormDragon;

	float ActivateRate = 2.0;
	float NextActivateTime;

	float MiddleX;
	float LeftX;
	float RightX;

	AFlameAttackPoint FlameAttackPoint;

	UMaterialInstanceDynamic DynamicMat;

	int Index;
	int MaxIndex;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StormDragon = Cast<AStormDragonIntro>(Owner);
		MaxIndex = StormDragon.FlamePoints.Num() - 1;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return false;

		if (!StormDragon.bRunFlameAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StormDragon.State != EStormDragonAttackState::Attacking)
			return true;

		if (!StormDragon.bRunFlameAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FlameAttackPoint = StormDragon.FlamePoints[Index];
		FlameAttackPoint.ActivateFlameAttack();
		StormDragon.FlameEffect.Activate();
		Index++;

		if(Index > MaxIndex)
			Index = 0;

		AHazePlayerCharacter ControlPlayer;

		if (Game::Mio.HasControl())
			ControlPlayer = Game::Mio;
		else
			ControlPlayer = Game::Zoe;

		StormDragon.SpawnFlameAttack(FlameAttackPoint.ActorLocation);

		// DynamicMat = PostProcessing::ApplyPostProcessMaterial(ControlPlayer, StormDragon.FlamePostProcessMat, this, EInstigatePriority::High);

		// switch(Index)
		// {
		// 	case 0:
		// 		DynamicMat.SetScalarParameterValue(n"positionX", 0.75);
		// 		break;
		// 	case 1:
		// 		DynamicMat.SetScalarParameterValue(n"positionX", 0.25);
		// 		break;
		// 	case 2:
		// 		DynamicMat.SetScalarParameterValue(n"positionX", 0.5);
		// 		break;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		NextActivateTime = Time::GameTimeSeconds + ActivateRate;
		StormDragon.FlameEffect.Deactivate();
		FlameAttackPoint.DeactivateFlameAttack();
		StormDragon.bRunFlameAttack = false;

		AHazePlayerCharacter ControlPlayer;

		if (Game::Mio.HasControl())
			ControlPlayer = Game::Mio;
		else
			ControlPlayer = Game::Zoe;

		// PostProcessing::ClearPostProcessMaterial(ControlPlayer, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator TargetRot = (FlameAttackPoint.FlamePoint - StormDragon.FlameEffect.WorldLocation).Rotation();
		StormDragon.FlameEffect.WorldRotation = TargetRot;

		// float Bottom = 1 - (FlameAttackPoint.GetAlphaProgress() - 0.15);
		float Position = 1.1 - FlameAttackPoint.GetAlphaProgress();

		// DynamicMat.SetScalarParameterValue(n"positionY", Position);
		// FHazeTraceDebugSettings DebugSettings;
		// DebugSettings.TraceColor = FLinearColor::Red;
		// DebugSettings.Thickness = 25.0;
		// FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		// TraceSettings.UseBoxShape(FVector(1800.0, 1800.0, 1000.0));
		// // TraceSettings.DebugDraw(DebugSettings);

		// FHitResultArray HitArray = TraceSettings.QueryTraceMulti(FlameAttackPoint.FlamePoint, FlameAttackPoint.FlamePoint + FlameAttackPoint.ActorForwardVector);

		// for (FHitResult Hit : HitArray)
		// {
		// 	if (Hit.bBlockingHit)
		// 	{
		// 		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

		// 		if (Player != nullptr)
		// 		{
		// 			if (!Player.IsPlayerDead())
		// 			{
		// 				Player.KillPlayer();
		// 				UPlayerHealthSettings::SetRespawnTimer(Player, 2.0, this);
		// 			}
		// 		}
		// 	}
		// }

		if (FlameAttackPoint.ReachedEndPoint())
			StormDragon.bRunFlameAttack = false;
	}	
} 
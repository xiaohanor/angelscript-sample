struct FMeltdownBossBallSmashAttackParameters
{
	float Duration = 0;
	float AttackStartTime = 0;
	float TelegraphStartTime = 0;
	FVector AttackRelativePosition;
	TSubclassOf<AMeltdownBossPhaseThreeTelegraph> TelegraphClass;
	TSubclassOf<AMeltdownBossPhaseThreeShockwave> ShockwaveClass;
	float TelegraphRadius = 300.0;
	float ShockwaveMaxRadius = 4000.0;
	float ShockwaveDuration = 4.0;
	int DebrisCount = 0;
	AMeltdownBossPhaseThreeBallSmash BallSmash;
	FRandomStream RandomStream;
	AStaticMeshActor BossPhase3Floor;
}

class UMeltdownBossBallSmashAttackCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownPhaseThreeBoss Rader;
	FMeltdownBossBallSmashAttackParameters Parameters;

	bool bTriggeredTelegraph = false;
	AMeltdownBossPhaseThreeTelegraph Telegraph;

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FMeltdownBossBallSmashAttackParameters QueueParams)
	{
		Parameters = QueueParams;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownPhaseThreeBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Parameters.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rader.bIsAttacking = false;
		Rader.PortalLocomotionTag = NAME_None;

		bTriggeredTelegraph = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Rader.bIsAttacking = false;

		TriggerAttack();
		if (IsValid(Telegraph))
			Telegraph.HideAndDestroy();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration >= Parameters.AttackStartTime)
		{
			Rader.bIsAttacking = true;
		}

		if (!bTriggeredTelegraph && ActiveDuration >= Parameters.TelegraphStartTime)
		{
			TriggerTelegraph();
		}
	}

	void TriggerTelegraph()
	{
		FVector TelegraphLocation = Rader.Mesh.WorldTransform.TransformPosition(Parameters.AttackRelativePosition);
		Telegraph = MeltdownBossPhaseThree::SpawnTelegraph(Parameters.TelegraphClass, TelegraphLocation, Parameters.TelegraphRadius, Type = ETelegraphDecalType::Scifi);
		bTriggeredTelegraph = true;
	}

	// Shockwave index needed so we can have muiltiple waves going at once
	int shockwaveIndex = 0;

	void TriggerAttack()
	{
		FVector AttackLocation = Rader.Mesh.WorldTransform.TransformPosition(Parameters.AttackRelativePosition);
		
		shockwaveIndex++;

		auto Shockwave = MeltdownBossPhaseThree::SpawnShockwave(Parameters.ShockwaveClass, AttackLocation, Parameters.ShockwaveMaxRadius, Parameters.ShockwaveDuration, Parameters.BossPhase3Floor, shockwaveIndex);
		if (Shockwave != nullptr)
			Shockwave.KnockbackImpulse = FVector(900, 0, 1200);
		Parameters.BallSmash.OnSmash();

		for (int i = 0; i < Parameters.DebrisCount; ++i)
		{
			AMeltdownPhaseThreeBallDebris Debris = SpawnActor(Rader.BallDebrisClass, AttackLocation);
			if (!IsValid(Debris))
				continue;

			float Angle = (360.0 / Parameters.DebrisCount) * i + Parameters.RandomStream.RandRange(-5.0, 5.0);
			FVector2D Forward = Math::AngleDegreesToDirection(Angle);

			float ForwardSpeed = Parameters.RandomStream.RandRange(1000.0, 1800.0);
			float VerticalSpeed = Parameters.RandomStream.RandRange(1500.0, 3500.0);

			Debris.Rader = Rader;
			Debris.Velocity = FVector(Forward.X * ForwardSpeed, Forward.Y * ForwardSpeed, VerticalSpeed);
			Debris.Launch(Parameters.RandomStream);
		}

		FMeltdownBossPhaseThreeBallSmashImpactParams ImpactParams;
		ImpactParams.ImpactLocation = AttackLocation;
		UMeltdownBossPhaseThreeBallSmashEffectHandler::Trigger_SmashImpact(Parameters.BallSmash, ImpactParams);
	}
}
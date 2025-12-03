class ULightningConductorCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ALightningConductor LightningConductor;

	bool bCompletedMove;
	float MoveSpeed = 25000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightningConductor = Cast<ALightningConductor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (LightningConductor.bIsLightningStarter)
		{
			LightningConductor.LightningLoopComp.SetNiagaraVariableVec3("End", LightningConductor.OtherConductor.LightningLoopComp.WorldLocation);

			if (LightningConductor.LightningLoopComp.WorldLocation != LightningConductor.OtherConductor.LightningLoopComp.WorldLocation)
			{
				// FHazeTraceDebugSettings Debug;
				// Debug.Thickness = 100.0;
				// Debug.TraceColor = FLinearColor::Red;
				FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
				TraceSettings.UseBoxShape(FVector(950.0, 950.0, 950.0));
				TraceSettings.IgnoreActor(LightningConductor);
				// TraceSettings.DebugDraw(Debug);

				FHitResultArray Hits = TraceSettings.QueryTraceMulti(LightningConductor.LightningLoopComp.WorldLocation, LightningConductor.OtherConductor.LightningLoopComp.WorldLocation);

				for (FHitResult Hit : Hits)
				{
					if (Hit.bBlockingHit)
					{
						AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);

						if (Player != nullptr)
						{
							Player.DamagePlayerHealth(0.2);
							Player.AddDamageInvulnerability(this, 1.0);
						}
					}
				}
			}
		}


		if (!bCompletedMove)
		{
			LightningConductor.ActorLocation = Math::VInterpConstantTo(LightningConductor.ActorLocation, LightningConductor.EndLocation, DeltaTime, MoveSpeed);
			LightningConductor.ActorRotation = (LightningConductor.EndLocation - LightningConductor.ActorLocation).GetSafeNormal().Rotation(); 

			if ((LightningConductor.ActorLocation - LightningConductor.EndLocation).SizeSquared() < 10.0)
			{
				bCompletedMove = true;	
			}
		}
	}
};
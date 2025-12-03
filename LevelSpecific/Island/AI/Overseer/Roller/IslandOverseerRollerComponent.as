class UIslandOverseerRollerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UIslandOverseerDeployRollerComponent DeployComp;
	AIslandOverseerRoller Roller;
	AHazeActor OwningActor;
	EIslandOverseerPhase Phase;
	bool bDetached;
	EIslandForceFieldType Color;
	bool bSpinning;
	bool bDestroyed;
	FVector PreviousLocation;
	UIslandOverseerSettings Settings;
	float KnockbackTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Roller = Cast<AIslandOverseerRoller>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(OwningActor);
	}

	void Detach(EIslandOverseerPhase CurrentPhase)
	{
		Phase = CurrentPhase;
		bDetached = true;
	}

	void Attach()
	{
		Phase = EIslandOverseerPhase::Idle;
		bDetached = false;
	}

	void StartSpin()
	{
		bSpinning = true;
	}

	void StopSpin()
	{
		bSpinning = false;
	}

	void SetupRoller()
	{
		bDestroyed = true;
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
	}

	void DestroyRoller()
	{
		if(bDestroyed)
			return;
		
		UIslandOverseerRollerEventHandler::Trigger_OnDestroyed(Cast<AHazeActor>(Owner));
		bDestroyed = true;
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
	}
	
	void ResetRoller()
	{
		if(!bDestroyed)
			return;
		bDestroyed = false;
		Owner.RemoveActorVisualsBlock(this);
		Owner.RemoveActorCollisionBlock(this);
	}

	void ResetDamage()
	{
		PreviousLocation = Owner.ActorLocation;
	}

	void DealDamage()
	{
		FVector Delta = PreviousLocation - Owner.ActorLocation;
		PreviousLocation = Owner.ActorLocation;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;
			if(Overlap::QueryShapeSweep(Roller.DamageCollision.GetCollisionShape(), Roller.DamageCollision.WorldTransform, Delta, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
				Player.KillPlayer(DeathEffect = DeathEffect);
		}
	}

	void Knockback()
	{
		FVector Delta = PreviousLocation - Owner.ActorLocation;
		PreviousLocation = Owner.ActorLocation;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;
			if(Overlap::QueryShapeSweep(Roller.TakeDamageCollision.GetCollisionShape(15), Roller.TakeDamageCollision.WorldTransform, Delta, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
			{
				Player.AddKnockbackImpulse(FVector::UpVector, 0, 800);

				if(Time::GetGameTimeSince(KnockbackTime) > 0.1)
				{
					UIslandOverseerRollerEventHandler::Trigger_OnKnockback(Roller, FIslandOverseerRollerEventHandlerOnKnockbackData(Player.ActorLocation, Player));
					KnockbackTime = Time::GameTimeSeconds;
				}
			}
		}
	}
}
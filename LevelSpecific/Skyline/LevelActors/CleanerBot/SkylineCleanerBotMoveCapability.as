class USkylineCleanerBotMoveCapability : UHazeCapability
{
	ASkylineCleanerBot Bot;

	UBasicAIDestinationComponent DestinationComp;
	FVector Direction;

	float BlockTimer;
	AHazePlayerCharacter Blocker;
	AHazePlayerCharacter AttackingPlayer;
	int BlockNum;
	bool bBlocked;

	int StartAttackBlocks = 2;
	float AttackTime;
	float LastBlockedTime;
	float LastChangeDirectionTime;

	FHazeAcceleratedRotator AccWeapon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bot = Cast<ASkylineCleanerBot>(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		Direction = Owner.ActorForwardVector.RotateAngleAxis(Math::RandRange(0, 360), Owner.ActorUpVector);
		AccWeapon.SnapTo(Bot.WeaponPivot.RelativeRotation);
		UBasicAIMovementSettings::SetTurnDuration(Cast<AHazeActor>(Owner), 1, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(AttackTime > 0)
		{
			DestinationComp.RotateTowards(AttackingPlayer);
			AccWeapon.SpringTo(FRotator(30, 0, 0), 100, 0.5, DeltaTime);
			Bot.WeaponPivot.RelativeRotation = AccWeapon.Value;
			if(Time::GetGameTimeSince(AttackTime) > 1.5)
			{
				USkylineCleanerBotEventHandler::Trigger_OnFireAtPlayer(Owner, FSkylineCleanerBotEventData(AttackingPlayer));
				Niagara::SpawnOneShotNiagaraSystemAtLocation(Bot.WeaponFireFx, Bot.WeaponPivot.WorldLocation, Bot.WeaponPivot.WorldRotation);
				AttackTime = 0;
				AttackingPlayer.KillPlayer();
				Bot.BodyMesh.SetMaterial(0, Bot.DefaultEyes);
			}
			return;
		}
		else
		{
			AccWeapon.SpringTo(FRotator(0, 0, 0), 100, 0.5, DeltaTime);
			Bot.WeaponPivot.RelativeRotation = AccWeapon.Value;
		}
			
		if (HasControl())
		{
			FVector NavLoc;
			Pathfinding::FindNavmeshLocation(Owner.ActorLocation, 0, 100, NavLoc);

			FVector Dest = Owner.ActorLocation + Direction * 100;
			Pathfinding::FindNavmeshLocation(Dest, 0, 100, Dest);

			if(!Pathfinding::StraightPathExists(NavLoc, Dest))
				SetDirection();

			bool bCurrentBlocked = false;
			AHazePlayerCharacter CurrentBlocker;

			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(Player.ActorLocation.IsWithinDist2D(Dest, 50))
				{
					CurrentBlocker = Player;
					bCurrentBlocked = true;
				}
			}

			if (bCurrentBlocked)
			{
				if (!bBlocked && (LastBlockedTime == 0.0 || Time::GetGameTimeSince(LastBlockedTime) > 0.25))
				{
					CrumbBlockedByPlayer(CurrentBlocker);
				}
			}
			else
			{
				if (bBlocked)
				{
					CrumbUnblockedByPlayer();
				}
			}

			if (bBlocked)
			{
				BlockTimer += DeltaTime;
				if(BlockTimer > 1.5)
				{
					BlockNum++;
					if(BlockNum >= StartAttackBlocks)
					{
						CrumbStartAttacking(Blocker);
					}
					SetDirection();
				}
				return;
			}
			else
			{
				BlockTimer = 0;
			}

			DestinationComp.MoveTowards(Dest, 200);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBlockedByPlayer(AHazePlayerCharacter Player)
	{
		bBlocked = true;
		Blocker = Player;
		LastBlockedTime = Time::GameTimeSeconds;
		USkylineCleanerBotEventHandler::Trigger_OnBlockedByPlayer(Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbUnblockedByPlayer()
	{
		bBlocked = false;
		Blocker = nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttacking(AHazePlayerCharacter Player)
	{
		check(Player != nullptr);
		AttackingPlayer = Player;
		AttackTime = Time::GameTimeSeconds;
		BlockNum = 0;
		Bot.BodyMesh.SetMaterial(0, Bot.AngryEyes);
		USkylineCleanerBotEventHandler::Trigger_OnWeaponEngage(Owner);
	}

	void SetDirection()
	{
		Direction = Owner.ActorForwardVector.RotateAngleAxis(Math::RandRange(0, 360), Owner.ActorUpVector);

		if (LastChangeDirectionTime == 0.0 || Time::GetGameTimeSince(LastChangeDirectionTime) > 0.5)
			CrumbOnChangeDirection();
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnChangeDirection()
	{
		USkylineCleanerBotEventHandler::Trigger_OnChangeDirecton(Owner);
		LastChangeDirectionTime = Time::GameTimeSeconds;
	}
}
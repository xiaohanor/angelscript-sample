class ASkylineTorCenterPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(2.0);
#endif

	ASkylineTor Tor;
	float ArenaRadius = 1845;
	TPerPlayer<bool> PlayerSlowGravity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		Tor = TListedActors<ASkylineTor>().Single;
		Tor.PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");
	}

	UFUNCTION()
	private void PhaseChange(ESkylineTorPhase NewPhase, ESkylineTorPhase OldPhase,
	                         ESkylineTorSubPhase NewSubPhase, ESkylineTorSubPhase OldSubPhase)
	{
		bool DisabledPhase = NewPhase == ESkylineTorPhase::Dead || NewPhase == ESkylineTorPhase::Idle;
		if(DisabledPhase && !IsActorDisabled())
			AddActorDisable(this);
		else if(IsActorDisabled())
			RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Tor.IsActorDisabled())
		{
			AddActorDisable(this);
			return;
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.GetDistanceTo(this) > ArenaRadius)
			{
				if(!PlayerSlowGravity[Player])
				{
					UMovementGravitySettings::SetGravityScale(Player, 0.7, this);
					PlayerSlowGravity[Player] = true;
				}
			}
			else
			{
				if(PlayerSlowGravity[Player])
				{
					UMovementGravitySettings::ClearGravityScale(Player, this);
					PlayerSlowGravity[Player] = false;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}
}

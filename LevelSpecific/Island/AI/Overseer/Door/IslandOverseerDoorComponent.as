event void FIslandOverseerDoorComponentArrivedEvent();
event void FIslandOverseerDoorComponentDoorImpulseEvent(AHazeActor Instigator);
event void FIslandOverseerDoorComponentOpenDoorEvent();
event void FIslandOverseerDoorComponentCloseDoorEvent();
event void FIslandOverseerDoorComponentDoorClosedEvent();
event void FIslandOverseerDoorComponentStartCombatEvent();
event void FIslandOverseerDoorComponentHeadCutStartEvent();
event void FIslandOverseerDoorComponentHeadCutStopEvent();
event void FIslandOverseerDoorComponentHeadCutResistEvent();
event void FIslandOverseerDoorComponentHeadCutEndEvent();

enum EIslandOverseerCutHeadState
{
	None,
	Start,
	Defeated,
	Decapitate,
	Dead
}

class UIslandOverseerDoorComponent : UActorComponent
{
	AAIIslandOverseer Overseer;

	UPROPERTY()
	USkeletalMesh HeadCutMesh;

	UPROPERTY()
	FIslandOverseerDoorComponentDoorImpulseEvent OnDoorImpulse;
	UPROPERTY()
	FIslandOverseerDoorComponentDoorClosedEvent OnDoorClosed;
	UPROPERTY()
	FIslandOverseerDoorComponentStartCombatEvent OnStartCombat;
	UPROPERTY()
	FIslandOverseerDoorComponentHeadCutStartEvent OnHeadCutStart;
	UPROPERTY()
	FIslandOverseerDoorComponentHeadCutStopEvent OnHeadCutStop;

	TArray<AIslandSidescrollerBossDoor> Doors;
	AIslandSidescrollerBossDoor LeftDoor;
	AIslandSidescrollerBossDoor RightDoor;
	TArray<AIslandOverseerRedBlueDoorTarget> DoorTargets;

	UPROPERTY()
	bool bPushedBack;

	UPROPERTY()
	bool bInstantClose;

	EIslandOverseerCutHeadState CutHeadState;
	bool bDoorAttack;
	bool bDoorCutHead;
	bool bHitReaction;
	bool bDoorClosing;
	bool bDoorClosed;
	float CutHeadPlayRate = 1;
	FVector CutHeadLocation;

	bool bResist;
	bool bCut;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		OnDoorClosed.AddUFunction(this, n"DoorClosed");
		DoorTargets = TListedActors<AIslandOverseerRedBlueDoorTarget>().GetArray();
		Doors = TListedActors<AIslandSidescrollerBossDoor>().GetArray();
		CutHeadState = EIslandOverseerCutHeadState::None;
		CutHeadLocation = TListedActors<AIslandOverseerDoorCutHeadLocation>().Single.ActorLocation;


		for(AIslandSidescrollerBossDoor Door : Doors)
		{
			if(Door.bRight)
				RightDoor = Door;
			else
				LeftDoor = Door;
		}
	}

	void DisableDoorTargets()
	{
		for(AIslandOverseerRedBlueDoorTarget Target : DoorTargets)
			Target.DisableTarget();
	}

	void EnableDoorTargets()
	{
		for(AIslandOverseerRedBlueDoorTarget Target : DoorTargets)
			Target.EnableTarget();
	}

	UFUNCTION()
	private void DoorClosed()
	{
		bDoorClosed = true;
		DisableDoorTargets();
	}

	UFUNCTION(BlueprintCallable)
	void StartCombat()
	{
		OnStartCombat.Broadcast();
	}

	void ReclosingCompleted()
	{
		Overseer.PhaseComp.Phase = EIslandOverseerPhase::Dead;
	}

	UFUNCTION(BlueprintCallable)
	void HeadImpact()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			FVector ImpactLocation = Overseer.Mesh.GetSocketLocation(n"Head");
			if(Player.ActorLocation.IsWithinDist(ImpactLocation, 500))
			{
				FStumble Stumble;
				FVector Dir = (Player.ActorLocation - ImpactLocation).ConstrainToPlane(Owner.ActorForwardVector).GetNormalized2DWithFallback(Owner.ActorRightVector);
				Stumble.Move = Dir * 350;
				Stumble.Duration = 0.75;
				Player.ApplyStumble(Stumble);
			}
		}
		UIslandOverseerEventHandler::Trigger_OnHeadImpact(Overseer);
	}

	UFUNCTION(BlueprintCallable)
	void LeftEyeExplode()
	{
		UIslandOverseerEventHandler::Trigger_OnLeftEyeExplode(Overseer);
		Overseer.EyePopLeftFx.Activate();
	}

	UFUNCTION(BlueprintCallable)
	void RightEyeExplode()
	{
		UIslandOverseerEventHandler::Trigger_OnRightEyeExplode(Overseer);
		Overseer.EyePopRightFx.Activate();
	}

	void StartClosingDoors()
	{
		for(AIslandSidescrollerBossDoor Door : Doors)
			Door.StartClosing();
	}

	void StopClosingDoors()
	{
		for(AIslandSidescrollerBossDoor Door : Doors)
			Door.StopClosing();
	}

	void InstantCloseDoors()
	{
		for(AIslandSidescrollerBossDoor Door : Doors)
			Door.InstantClose();
	}

	void EnableCutHeadState()
	{
		CutHeadState = EIslandOverseerCutHeadState::Start;
	}

	void AttachCutHeadDoors()
	{
		LeftDoor.AttachToComponent(Overseer.Mesh, n"LeftHand_IK");
		RightDoor.AttachToComponent(Overseer.Mesh, n"RightHand_IK");
	}

	void DisableCutHeadState()
	{
		LeftDoor.DetachFromActor();
		RightDoor.DetachFromActor();
		CutHeadState = EIslandOverseerCutHeadState::Dead;
	}
}
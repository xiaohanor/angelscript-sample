class UIslandOverseerControlCraneComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<AIslandOverseerCrane> CraneClass;

	UIslandOverseerPhaseComponent PhaseComp;
	AIslandOverseerCrane Crane;
	FHazeAcceleratedVector AccLift;
	FHazeAcceleratedRotator AccLeftClaw;
	FHazeAcceleratedRotator AccRightClaw;

	FRotator LeftClawOpenRotation = FRotator(-70, 0, 0);
	FRotator RightClawOpenRotation = FRotator(70, 0, 0);

	bool bDrop;
	bool bLift;
	bool bLifted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
		PhaseComp.OnPhaseChange.AddUFunction(this, n"PhaseChange");

		Crane = SpawnActor(CraneClass, WorldLocation, WorldRotation, Level = Owner.Level);
		Crane.AttachToActor(Owner, NAME_None, EAttachmentRule::KeepWorld);
		HideCrane();
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(NewPhase == EIslandOverseerPhase::PovCombat && OldPhase != EIslandOverseerPhase::Flood)
		{
			ShowCrane();
		}

		if(NewPhase == EIslandOverseerPhase::Flood)
		{
			Lift();
			ShowCrane();
		}
	}

	private void ShowCrane()
	{
		Crane.RemoveActorVisualsBlock(this);
		Crane.bIsVisible = true;
	}

	private void HideCrane()
	{
		Crane.AddActorVisualsBlock(this);
		Crane.bIsVisible = false;
	}

	void Lift()
	{
		AccLift.SnapTo(Crane.ActorRelativeLocation);
		bLift = true;
		UIslandOverseerCraneEventHandler::Trigger_OnLiftStart(Crane);
		AccRightClaw.SnapTo(RightClawOpenRotation);
		AccLeftClaw.SnapTo(LeftClawOpenRotation);
		Crane.RightClaw.RelativeRotation = AccRightClaw.Value;
		Crane.LeftClaw.RelativeRotation = AccLeftClaw.Value;
	}

	void Drop()
	{
		Crane.DetachFromActor();
		bDrop = true;
		UIslandOverseerCraneEventHandler::Trigger_OnDrop(Crane);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Crane == nullptr)
			return;

		if(bDrop)
		{
			AccRightClaw.SpringTo(RightClawOpenRotation, 100, 0.5, DeltaSeconds);
			AccLeftClaw.SpringTo(LeftClawOpenRotation, 100, 0.5, DeltaSeconds);
		}
		else if(bLift)
		{
			AccRightClaw.AccelerateTo(FRotator::ZeroRotator,5, DeltaSeconds);
			AccLeftClaw.AccelerateTo(FRotator::ZeroRotator,5, DeltaSeconds);

			if(!bLifted && AccRightClaw.Value.IsNearlyZero(1))
			{
				bLifted = true;
				UIslandOverseerCraneEventHandler::Trigger_OnLiftCompleted(Crane);
			}
		}
		Crane.RightClaw.RelativeRotation = AccRightClaw.Value;
		Crane.LeftClaw.RelativeRotation = AccLeftClaw.Value;
	}
}
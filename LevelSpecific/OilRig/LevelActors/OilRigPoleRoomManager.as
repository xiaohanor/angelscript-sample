class AOilRigPoleRoomManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AKineticMovingActor> KineticActors;

	TArray<APoleClimbActor> Poles;

	TArray<AHazePlayerCharacter> PlayersOnPole;

	bool bMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AKineticMovingActor KineticActor : KineticActors)
		{
			KineticActor.OnStartForward.AddUFunction(this, n"StartMoving");
			KineticActor.OnStartBackward.AddUFunction(this, n"StartMoving");
			KineticActor.OnReachedForward.AddUFunction(this, n"StopMoving");
			KineticActor.OnReachedBackward.AddUFunction(this, n"StopMoving");

			TArray<AActor> AttachedActors;
			KineticActor.GetAttachedActors(AttachedActors);
			for (AActor Actor : AttachedActors)
			{
				APoleClimbActor Pole = Cast<APoleClimbActor>(Actor);
				if (Pole != nullptr)
				{
					Pole.OnStartPoleClimb.AddUFunction(this, n"StartClimbing");
					Pole.OnStopPoleClimb.AddUFunction(this, n"StopClimbing");
				}
					Poles.Add(Pole);
			}
		}
	}

	UFUNCTION()
	private void StartClimbing(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		PlayersOnPole.Add(Player);
	}

	UFUNCTION()
	private void StopClimbing(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		PlayersOnPole.Remove(Player);
	}

	UFUNCTION()
	private void StartMoving()
	{
		bMoving = true;
	}

	UFUNCTION()
	private void StopMoving()
	{
		bMoving = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMoving)
		{
			TArray<AHazePlayerCharacter> Players = PlayersOnPole;
			for (AHazePlayerCharacter Player : Players)
			{
				float LeftFF = Math::Sin(Time::GetGameTimeSeconds() * 50.0) * 0.3;
				float RightFF = Math::Sin(-Time::GetGameTimeSeconds() * 50.0) * 0.3;
				Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
			}
		}
	}
}
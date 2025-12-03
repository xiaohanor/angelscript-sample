event void FSkylineHighwayCombatIslandFinishedMoveSignature(int SplineIndex);

class ASkylineHighwayCombatIsland : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocation;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> MoveSplines;

	UPROPERTY(EditInstanceOnly)
	AHazeActorSpawnerBase Spawner;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 100000;

	UPROPERTY()
	FSkylineHighwayCombatIslandFinishedMoveSignature OnFinishedMove;

	UPROPERTY()
	FSkylineHighwayCombatIslandFinishedMoveSignature OnCompletedFinishedMove;

	private ASplineActor CurrentSpline;
	private float Distance;
	private bool bMove;
	private bool bCompletedMove;
	private ASkylineDisableChildrenActor Disabler;
	private int SplineIndex;

	private float CurrentSpeed;
	private float AccelerationDuration = 0.5;
	private FHazeAcceleratedFloat AccSpeed;
	private FHazeAcceleratedVector AccMove;
	private FVector CurrentLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentSpline = MoveSplines[0];
		ActorLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(0);
		TArray<AActor> Attached;
		GetAttachedActors(Attached);
		for(AActor Child : Attached)
		{
			if(Child.IsA(ASkylineDisableChildrenActor))
				Disabler = Cast<ASkylineDisableChildrenActor>(Child);
		}
		AddActorTickBlock(this);
	}

	UFUNCTION()
	void StartMove()
	{
		Distance = 0;
		bMove = true;
		bCompletedMove = true;
		if(Disabler != nullptr)
			Disabler.RemoveAllDisablers();
		if(Spawner != nullptr)
			Spawner.ActivateSpawner();
		CurrentSpeed = 0;
		AccSpeed.SnapTo(0);
		AccMove.SnapTo(CurrentSpline.Spline.GetWorldLocationAtSplineDistance(Distance));
		RemoveActorTickBlock(this);
	}

	UFUNCTION()
	void JumpToEnd()
	{
		ActorLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(CurrentSpline.Spline.SplineLength);
		if(Disabler != nullptr)
			Disabler.RemoveAllDisablers();

		for (; SplineIndex < MoveSplines.Num(); SplineIndex++)
		{
			OnFinishedMove.Broadcast(SplineIndex);
		}
		AddActorTickBlock(this);
	}

	UFUNCTION()
	void JumpToNext()
	{
		if(MoveSplines.Num() > SplineIndex + 1)
		{
			SplineIndex++;
			CurrentSpline = MoveSplines[SplineIndex];
		}
		ActorLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(0);
		if(Disabler != nullptr)
			Disabler.RemoveAllDisablers();
		AddActorTickBlock(this);
	}

	UFUNCTION()
	void Show()
	{
		if(Disabler != nullptr)
			Disabler.RemoveAllDisablers();
	}

	private void FinishedMove()
	{
		if(!bMove)
			return;

		OnFinishedMove.Broadcast(SplineIndex);
		bMove = false;

		if(MoveSplines.Num() > SplineIndex + 1)
		{
			SplineIndex++;
			CurrentSpline = MoveSplines[SplineIndex];
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMove)
		{
			if(Distance < CurrentSpline.Spline.SplineLength)
			{
				float Factor = 1 - Math::Clamp(Distance / CurrentSpline.Spline.SplineLength, 0, 0.9);
				AccSpeed.AccelerateTo(MoveSpeed, AccelerationDuration, DeltaSeconds);
				CurrentSpeed = AccSpeed.Value * Factor;

				Distance += DeltaSeconds * CurrentSpeed;
			}
			else
			{
				if(AccMove.Velocity.Size() < 250)
					FinishedMove();
			}
		}
		else if(bCompletedMove && AccMove.Velocity.Size() < 50)
		{
			bCompletedMove = false;
			OnCompletedFinishedMove.Broadcast(SplineIndex);
		}

		CurrentLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(Distance);
		AccMove.SpringTo(CurrentLocation, 5, 0.75, DeltaSeconds);

		if(HasControl())
		{
			ActorLocation = AccMove.Value;
			SyncedLocation.Value = ActorLocation;
		}
		else
			ActorLocation = SyncedLocation.Value;
	}
}
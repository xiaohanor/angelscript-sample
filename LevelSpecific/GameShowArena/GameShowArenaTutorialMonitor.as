class AGameShowArenaTutorialMonitor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent NumberMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ArmMesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ArmMesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ArmMesh03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ArmMesh04;

	UPROPERTY()
	TArray<UStaticMesh> NumberMeshes;

	UPROPERTY()
	FHazeTimeLike MoveMonitorTimelike;
	default MoveMonitorTimelike.Duration = 2;

	FVector StartingLocation;
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveMonitorTimelike.BindUpdate(this, n"MoveMonitorTimelikeUpdate");
		MoveMonitorTimelike.BindFinished(this, n"MoveMonitorTimelikeFinished");
		StartingLocation = ActorLocation;
		TargetLocation = StartingLocation;
		TargetLocation.Z += 3000;
	}

	UFUNCTION()
	void RevealTutorialMonitor()
	{
		MoveMonitorTimelike.PlayFromStart();
		SetActorHiddenInGame(false);
		UGameShowArenaTutorialMonitorEffectHandler::Trigger_MovingDown(this);
	}

	UFUNCTION()
	void HideTutorialMonitor()
	{
		MoveMonitorTimelike.ReverseFromEnd();
		UGameShowArenaTutorialMonitorEffectHandler::Trigger_MovingUp(this);
	}

	UFUNCTION()
	private void MoveMonitorTimelikeUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartingLocation, TargetLocation, Math::CircularOut(0, 1, CurrentValue)));
	}

	UFUNCTION()
	private void MoveMonitorTimelikeFinished()
	{
		if(MoveMonitorTimelike.IsReversed())
			SetActorHiddenInGame(true);
	}

	void UpdateCatchCounter(int Catches)
	{
		NumberMesh.SetStaticMesh(NumberMeshes[Catches]);

		if(Catches > 0)
		{
			FGameShowArenaTutorialMonitorData Data;
			Data.Catches = Catches;
			Data.bCompleted = Catches == 4 ? true : false;
			
			UGameShowArenaTutorialMonitorEffectHandler::Trigger_SuccesCountUp(this, Data);
		}
	}
};
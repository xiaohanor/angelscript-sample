UCLASS(Abstract)
class AGarbageRoomBossHead : AHazeActor
{
	default bHidden = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SinkTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DropCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DropFF;

	bool bDropped = false;

	FVector StartLocation;
	FVector EndLocation;

	float SinkDelay = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropTimeLike.BindUpdate(this, n"UpdateDrop");
		DropTimeLike.BindFinished(this, n"FinishDrop");

		SinkTimeLike.BindUpdate(this, n"UpdateSink");
		SinkTimeLike.BindFinished(this, n"FinishSink");
	}

	UFUNCTION()
	void Drop()
	{
		if (bDropped)
			return;

		StartLocation = ActorLocation;
		EndLocation = StartLocation - (FVector::UpVector * 4500.0);

		bDropped = true;
		DropTimeLike.PlayFromStart();

		SetActorHiddenInGame(false);

		UGarbageRoomBossHeadEffectEventHandler::Trigger_Drop(this);
	}

	UFUNCTION()
	private void UpdateDrop(float CurValue)
	{
		FVector Loc = Math::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishDrop()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(DropCamShake, this, ActorLocation, 2000.0, 3000.0);

		ForceFeedback::PlayWorldForceFeedback(DropFF, ActorLocation, true, this, 2000.0, 1000.0);

		BP_FinishDrop();
		UGarbageRoomBossHeadEffectEventHandler::Trigger_FinishDrop(this);

		Timer::SetTimer(this, n"StartSinking", SinkDelay);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FinishDrop() {}

	UFUNCTION()
	private void StartSinking()
	{
		StartLocation = ActorLocation;
		EndLocation = StartLocation - (FVector::UpVector * 1000.0);

		SinkTimeLike.PlayFromStart();

		UGarbageRoomBossHeadEffectEventHandler::Trigger_Sink(this);
	}

	UFUNCTION()
	private void UpdateSink(float CurValue)
	{
		FVector Loc = Math::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishSink()
	{
	}
}

class UGarbageRoomBossHeadEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Drop() {}
	UFUNCTION(BlueprintEvent)
	void Sink() {}
	UFUNCTION(BlueprintEvent)
	void FinishDrop() {}
}
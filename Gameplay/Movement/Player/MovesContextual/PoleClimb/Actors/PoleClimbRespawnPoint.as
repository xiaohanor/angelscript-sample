class APoleClimbRespawnPoint : ARespawnPoint
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UPoleClimbRespawnVisualizerDummyComp VisualizerDummyComp;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Respawn Point")
	ASplineActor LockedSpline;

	UPROPERTY(EditInstanceOnly, Category = "Respawn Point")
	APoleClimbActor PoleActor;

	default SecondPosition = FTransform((FVector(0,0,0)));

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerTeleportToRespawnPoint.AddUFunction(this, n"OnTeleportedToRespawnPoint");
	}

	UFUNCTION()
	private void OnTeleportedToRespawnPoint(AHazePlayerCharacter TeleportingPlayer)
	{
		if(PoleActor == nullptr)
			return;

		UPlayerPoleClimbComponent PoleClimbComp = UPlayerPoleClimbComponent::Get(TeleportingPlayer);

		if(PoleClimbComp == nullptr)
			return;

		PoleClimbComp.ForceEnterPole(PoleActor, LockedSpline);
	}

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);

		if(PoleActor == nullptr)
			return;

		UPlayerPoleClimbComponent PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);

		if(PoleClimbComp == nullptr)
			return;
		
		PoleClimbComp.ForceEnterPole(PoleActor, LockedSpline);
	}
};

class UPoleClimbRespawnPointVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPoleClimbRespawnVisualizerDummyComp;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UPoleClimbRespawnVisualizerDummyComp DummyComp = Cast<UPoleClimbRespawnVisualizerDummyComp>(Component);

		if(DummyComp == nullptr)
			return;

		APoleClimbRespawnPoint RespawnPoint = Cast<APoleClimbRespawnPoint>(DummyComp.Owner);

		if(RespawnPoint == nullptr)
			return;

		if(RespawnPoint.PoleActor == nullptr)
			return;

		DrawDashedLine(RespawnPoint.ActorLocation, RespawnPoint.PoleActor.ActorLocation + (RespawnPoint.PoleActor.ActorUpVector * (RespawnPoint.PoleActor.Height / 2)),
			 FLinearColor::Yellow, Thickness = 4);
	}
}

class UPoleClimbRespawnVisualizerDummyComp : UActorComponent
{

}
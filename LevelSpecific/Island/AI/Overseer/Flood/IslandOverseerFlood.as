UCLASS(Abstract)
class AIslandOverseerFlood : AHazeActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandOverseerFloodDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	USceneComponent StartingElevatorLeft;

	UPROPERTY(DefaultComponent)
	USceneComponent StartingElevatorRight;

	UPROPERTY(EditAnywhere)
	AHazeActor FloodStop;

	UPROPERTY(EditAnywhere)
	AHazeActor LeftElevatorStop;

	UPROPERTY(EditAnywhere)
	AHazeActor RightElevatorStop;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000;

	bool bDetachedLeftElevator;
	bool bDetachedRightElevator;
	const float DamageWidth = 2500;
	bool bEnabled;

	void DetachLeftElevator()
	{
		StartingElevatorLeft.DetachFromParent(true);
		bDetachedLeftElevator = true;
		UIslandOverseerFloodEventHandler::Trigger_OnElevatorStop(this);
	}

	void DetachRightElevator()
	{
		StartingElevatorRight.DetachFromParent(true);
		bDetachedRightElevator = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(!bEnabled)
		{
			SetActorTickEnabled(false);
			return;
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(GetHorizontalDistanceTo(Player) > DamageWidth / 2)
				continue;
			if(Player.IsPlayerDead())
				continue;
			if(ActorLocation.Z - 50 > Player.ActorLocation.Z)
			{
				FPlayerDeathDamageParams Params;
				Player.KillPlayer(Params, DeathEffect);
			}
		}
	}

	UFUNCTION()
	void MoveFloodToEnd()
	{
		DetachLeftElevator();
		DetachRightElevator();
		ActorLocation = FVector(ActorLocation.X, ActorLocation.Y, FloodStop.ActorLocation.Z);
		bEnabled = true;
		SetActorTickEnabled(true);
	}
}

class UIslandOverseerFloodEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStop() {}
};

#if EDITOR
class UIslandOverseerFloodDummyComponent : UActorComponent {};

class UIslandOverseerFloodComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandOverseerFloodDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandOverseerFloodDummyComponent>(Component);
		if(Comp == nullptr)
		 	return;
		auto Flood = Cast<AIslandOverseerFlood>(Component.Owner);
		if(Flood == nullptr)
			return;
		DrawLine(Flood.ActorLocation - Flood.ActorForwardVector * (Flood.DamageWidth / 2), Flood.ActorLocation + Flood.ActorForwardVector * (Flood.DamageWidth / 2), FLinearColor::Red, 25);
	}
}

#endif
event void FPrisonDoubleElectricPoleButtonOnEnter(APrisonDoubleElectricPoleButton Button, AHazePlayerCharacter Player, bool bFirst);
event void FPrisonDoubleElectricPoleButtonOnExit(APrisonDoubleElectricPoleButton Button, AHazePlayerCharacter Player, bool bLast);

UCLASS(Abstract)
class APrisonDoubleElectricPoleButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UPrisonDoubleElectricPoleButtonEditorComponent EditorComp;
#endif

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleActor;

	UPROPERTY(EditInstanceOnly)
	FHazeRange HeightRange = FHazeRange(-100, 50);

	UPROPERTY()
	FPrisonDoubleElectricPoleButtonOnEnter OnEnter;

	UPROPERTY()
	FPrisonDoubleElectricPoleButtonOnExit OnExit;

	private TPerPlayer<bool> bIsClimbing;
	private TPerPlayer<bool> bIsInTrigger;
	private float HeightAlongPole;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(HeightRange.Min > HeightRange.Max)
			HeightRange.Min = HeightRange.Max - KINDA_SMALL_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HeightAlongPole = GetHeightAlongPole();
		AddActorTickBlock(this);

		PoleActor.OnStartPoleClimb.AddUFunction(this, n"OnStartPoleClimb");
		PoleActor.OnStopPoleClimb.AddUFunction(this, n"OnStopPoleClimb");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(!bIsClimbing[Player])
				continue;

			CheckClimbHeight(Player);
		}

#if !RELEASE
		for(auto Player : Game::Players)
		{
			TEMPORAL_LOG(this)
				.Section(f"{Player.Player:n}", int(Player.Player))
				.Value("bIsClimbing", bIsClimbing[Player])
				.Value("bIsInTrigger", bIsInTrigger[Player])
			;
		}
#endif
	}

	UFUNCTION()
	private void OnStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		if(!IsAnyPlayerClimbing())
			RemoveActorTickBlock(this);

		bIsClimbing[Player] = true;

		CheckClimbHeight(Player);
	}

	UFUNCTION()
	private void OnStopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		bIsClimbing[Player] = false;

		if(bIsInTrigger[Player])
		{
			ExitTrigger(Player);
		}

		if(!IsAnyPlayerClimbing())
			AddActorTickBlock(this);
	}

	void CheckClimbHeight(AHazePlayerCharacter Player)
	{
		if(bIsInTrigger[Player])
		{
			if(!IsWithinRange(Player))
				ExitTrigger(Player);
		}
		else
		{
			if(IsWithinRange(Player))
				EnterTrigger(Player);
		}
	}

	private void EnterTrigger(AHazePlayerCharacter Player)
	{
		const bool bFirst = !IsAnyPlayerInTrigger();
		bIsInTrigger[Player] = true;

#if !RELEASE
		TEMPORAL_LOG(this).Event(f"EnterTrigger: {Player.Player:n}, {bFirst=}");
#endif

		OnEnter.Broadcast(this, Player, bFirst);
	}

	private void ExitTrigger(AHazePlayerCharacter Player)
	{
		bIsInTrigger[Player] = false;
		const bool bLast = !IsAnyPlayerInTrigger();

#if !RELEASE
		TEMPORAL_LOG(this).Event(f"EnterTrigger: {Player.Player:n}, {bLast=}");
#endif

		OnExit.Broadcast(this, Player, bLast);
	}

	bool IsAnyPlayerClimbing() const
	{
		for(bool bClimb : bIsClimbing)
		{
			if(bClimb)
				return true;
		}

		return false;
	}

	bool IsAnyPlayerInTrigger() const
	{
		for(bool bInTrigger : bIsInTrigger)
		{
			if(bInTrigger)
				return true;
		}

		return false;
	}

	bool IsWithinRange(AHazePlayerCharacter Player) const
	{
		const float RelativeHeight = ActorTransform.InverseTransformPositionNoScale(Player.ActorCenterLocation).Z;
		return HeightRange.IsInRange(RelativeHeight);
	}

	float GetHeightAlongPole() const
	{
		return PoleActor.ActorTransform.InverseTransformPositionNoScale(ActorLocation).Z;
	}
};

#if EDITOR
class UPrisonDoubleElectricPoleButtonEditorComponent : UActorComponent
{
}

class UPrisonDoubleElectricPoleButtonVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPrisonDoubleElectricPoleButtonEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto PoleButton = Cast<APrisonDoubleElectricPoleButton>(Component.Owner);
		if(PoleButton == nullptr)
			return;

		if(PoleButton.PoleActor == nullptr)
			return;

		const FVector BottomLocation = PoleButton.PoleActor.ActorTransform.TransformPositionNoScale(FVector::UpVector * (PoleButton.GetHeightAlongPole() + PoleButton.HeightRange.Min));
		DrawCircle(BottomLocation, 100, FLinearColor::Green, 0, PoleButton.PoleActor.ActorUpVector);
		
		const FVector TopLocation = PoleButton.PoleActor.ActorTransform.TransformPositionNoScale(FVector::UpVector * (PoleButton.GetHeightAlongPole() + PoleButton.HeightRange.Max));
		DrawCircle(TopLocation, 100, FLinearColor::Green, 0, PoleButton.PoleActor.ActorUpVector);
	}
}
#endif
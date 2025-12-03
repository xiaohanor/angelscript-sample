struct FTundraPoleClimbLeafVFXStartClimbingParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FTundraPoleClimbLeafVFXStopClimbingParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FVector ExitVelocity;
}

UCLASS(Abstract)
class UTundraPoleClimbLeafVFXComponent : UActorComponent
{
	UPROPERTY(NotVisible, Transient, BlueprintReadOnly)
	APoleClimbActor PoleClimb;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PoleClimb = Cast<APoleClimbActor>(Owner);
		devCheck(PoleClimb != nullptr, "Cannot put a leaf vfx component on an actor that isn't a APoleClimbActor");
		PoleClimb.OnStartPoleClimb.AddUFunction(this, n"Internal_OnStartPoleClimbing");
		PoleClimb.OnCancel.AddUFunction(this, n"Internal_OnCancelClimbing");
		PoleClimb.OnJumpOff.AddUFunction(this, n"Internal_OnJumpOffPole");
	}

	UFUNCTION()
	private void Internal_OnStartPoleClimbing(AHazePlayerCharacter Player, APoleClimbActor Pole)
	{
		FTundraPoleClimbLeafVFXStartClimbingParams Params;
		Params.Player = Player;
		OnStartPoleClimbing(Params);
	}

	UFUNCTION()
	private void Internal_OnCancelClimbing(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor,
	                                       FVector JumpOutDirection)
	{
		FTundraPoleClimbLeafVFXStopClimbingParams Params;
		Params.Player = Player;
		Params.ExitVelocity = Player.ActorVelocity;
		OnStopPoleClimbing(Params);
	}

	UFUNCTION()
	private void Internal_OnJumpOffPole(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor,
	                                    FVector JumpOutDirection)
	{
		FTundraPoleClimbLeafVFXStopClimbingParams Params;
		Params.Player = Player;
		Params.ExitVelocity = Player.ActorVelocity;
		OnStopPoleClimbing(Params);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPoleClimbing(FTundraPoleClimbLeafVFXStartClimbingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopPoleClimbing(FTundraPoleClimbLeafVFXStopClimbingParams Params) {}
}
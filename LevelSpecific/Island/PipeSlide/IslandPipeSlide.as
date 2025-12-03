

UCLASS(Abstract)
class AIslandPipeSlideBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
}

UCLASS(Abstract)
class UIslandPipeSlideComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	TSubclassOf<AIslandPipeSlideBoard> BoardClass;

	UPROPERTY(Category = "Settings")
	UIslandPipeSlideComposableSettings DefaultSettings;

	bool bIsPipeSliding = false;
	UHazeSplineComponent ActiveSpline;
	AIslandPipeSlideBoard Board;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Board = SpawnActor(BoardClass);
		Board.AddActorDisable(this);

		if(DefaultSettings != nullptr)
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			Player.ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);
		}
	}
}

class UIslandPipeSlideComposableSettings : UHazeComposableSettings
{
	// How fast we move, giving full input backward to forward
	UPROPERTY()
	FHazeRange MoveInputSpeed = FHazeRange(2000.0, 4000.0);

	// How fast we are moving left and right in relation to the forward speed
	UPROPERTY()
	float LeftRightMoveSpeedMultiplier = 0.4;

	// How fast we reach the target move speed if its higher than the current move speed
	UPROPERTY()
	float MoveSpeedAcceleration = 3.0;

	// How fast we reach the target move speed if its lower than the current move speed
	UPROPERTY()
	float MoveSpeedDeceleration = 3.0;

	// How high we can jump
	UPROPERTY()
	float JumpImpulse = 1000.0;
};


UFUNCTION()
void StartIslandPipeSlide(AHazePlayerCharacter Player, AActor PipeSpline)
{
	auto PipeComponent = UIslandPipeSlideComponent::Get(Player);
	if(PipeComponent == nullptr)
	{
		devError(f"StartIslandPipeSlide was called on {Player} without adding the DA_IslandPipeSheet to her. Add in in the level.");
		return;
	}	

	auto SplineActor = Cast<ASplineActor>(PipeSpline);
	if(SplineActor != nullptr)
	{
		PipeComponent.bIsPipeSliding = true;
		PipeComponent.ActiveSpline = SplineActor.Spline;
		PipeComponent.Board.RemoveActorDisable(PipeComponent);
		PipeComponent.Board.AttachToComponent(Player.Mesh);
		return;
	}

	if(PipeSpline == nullptr)
	{
		devError(f"StartIslandPipeSlide was called on {Player} without adding an actor with a spline");
	}	
}

UFUNCTION()
void StopIslandPipeSlide(AHazePlayerCharacter Player)
{
	auto PipeComponent = UIslandPipeSlideComponent::Get(Player);
	if(PipeComponent == nullptr)
		return;

	if(!PipeComponent.bIsPipeSliding)
		return;
	
	PipeComponent.Board.AddActorDisable(PipeComponent);
	PipeComponent.Board.DetachFromActor();
	PipeComponent.bIsPipeSliding = false;
	PipeComponent.ActiveSpline = nullptr;
}
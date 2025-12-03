
UCLASS(Abstract)
class ASummitRollingLiftEnterInteraction : ADoubleInteractionActor
{
	UPROPERTY(EditInstanceOnly)
	ASummitRollingLift LiftToEnter;

	default LeftInteraction.UsableByPlayers = EHazeSelectPlayer::Mio;
	
	default RightInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default RightInteraction.ActionShape.BoxExtents = FVector(600.0, 600.0, 600.0);
	default RightInteraction.ActionShapeTransform.Location = FVector(0, 0, 200);
	default RightInteraction.FocusShape.SphereRadius = 1000.0;
	default RightInteraction.FocusShapeTransform.Location = FVector(0,0, 300.0);
	default RightInteraction.MovementSettings.Type = EMoveToType::NoMovement;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		if(LiftToEnter == nullptr)
		{
			devError(f"The rolling lift interaction {this} is missing its link to the rolling lift");
			return;
		}

		OnDoubleInteractionCompleted.AddUFunction(LiftToEnter, n"OnDoubleInteractionCompleted");
	}


};

class APlayerInputPlaneLockTrigger : APlayerTrigger
{
	UPROPERTY(Category = "Input Lock", DefaultComponent, ShowOnActor)
	UPlayerInputPlaneLockTriggerComponent LockInputComponent;

	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		LockInputComponent.OnPlayerEnter(Player);
		Super::TriggerOnPlayerEnter(Player);
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		LockInputComponent.OnPlayerExit(Player);
		Super::TriggerOnPlayerLeave(Player);
	} 
}

enum EPlayerInputPlaneLockTriggerDirectionType
{
	ForwardIsUpDown_RightIsLeftRight,
	ForwardIsLeftRight_RightIsUpDown,
	ForwardIsUpDown_UpIsLeftRight,
	ForwardIsLeftRight_UpIsUpDown,
}

class UPlayerInputPlaneLockTriggerComponent : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "Input Lock")
	ASplineActor InputSpline;

	UPROPERTY(EditAnywhere, Category = "Input Lock", Meta = (EditCondition = "InputSpline != nullptr"))
	EPlayerInputPlaneLockTriggerDirectionType SplineLockDirectionType = EPlayerInputPlaneLockTriggerDirectionType::ForwardIsUpDown_RightIsLeftRight;

	UPROPERTY(EditAnywhere, Category = "Input Lock")
	EInstigatePriority Priority = EInstigatePriority::Low;

	private TArray<AHazePlayerCharacter> InsidePlayers;

	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		InsidePlayers.Add(Player);
		if(InputSpline == nullptr)
		{
			Player.LockInputToPlaneOrientation(this, WorldRotation);
		}
		else if(InsidePlayers.Num() == 1)
		{
			SetComponentTickEnabled(true);
		}	
	}

	void OnPlayerExit(AHazePlayerCharacter Player)
	{
		InsidePlayers.RemoveSingleSwap(Player);
		Player.ClearLockInputToPlane(this);

		if(InsidePlayers.Num() == 0)
		{
			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(InputSpline != nullptr)
		{
			for(auto Player : InsidePlayers)
			{
				auto MoveComp = UPlayerMovementComponent::Get(Player);
				FInputPlaneLock LockInfo = GetHorizontalVerticalDirection(Player.ActorLocation);	
				MoveComp.InputPlaneLock.Apply(LockInfo, this, Priority);
			}
		}
	}

	FInputPlaneLock GetHorizontalVerticalDirection(FVector Location) const
	{
		FInputPlaneLock Out;

		Out.UpDown = WorldRotation.ForwardVector;
		Out.LeftRight = WorldRotation.RightVector;

		// We should follow a spline
		if(InputSpline != nullptr)
		{
			auto SplineLocation = InputSpline.Spline.GetClosestSplinePositionToWorldLocation(Location);

			if(SplineLockDirectionType == EPlayerInputPlaneLockTriggerDirectionType::ForwardIsUpDown_RightIsLeftRight)
			{
				Out.UpDown = SplineLocation.WorldForwardVector;
				Out.LeftRight = SplineLocation.WorldRightVector;
			}

			else if(SplineLockDirectionType == EPlayerInputPlaneLockTriggerDirectionType::ForwardIsUpDown_UpIsLeftRight)
			{
				Out.UpDown = SplineLocation.WorldForwardVector;
				Out.LeftRight = SplineLocation.WorldUpVector;
			}

			else if(SplineLockDirectionType == EPlayerInputPlaneLockTriggerDirectionType::ForwardIsLeftRight_RightIsUpDown)
			{
				Out.LeftRight = SplineLocation.WorldForwardVector;
				Out.UpDown = SplineLocation.WorldRightVector;
			}
	
			else if(SplineLockDirectionType == EPlayerInputPlaneLockTriggerDirectionType::ForwardIsLeftRight_UpIsUpDown)
			{
				Out.LeftRight = SplineLocation.WorldForwardVector;
				Out.UpDown = SplineLocation.WorldUpVector;
				//Debug::DrawDebugDirectionArrow(Location - (SplineLocation.WorldRightVector * 100), Out.LeftRight, 500, Thickness = 10);
			}
		}	

		return Out;
	}
}


#if EDITOR
class UPlayerInputPlaneLockTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UPlayerInputPlaneLockTriggerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto LockComp = Cast<UPlayerInputPlaneLockTriggerComponent>(Component);
		if(LockComp == nullptr)
			return;

		auto TriggerOwner = Cast<APlayerInputPlaneLockTrigger>(Component.Owner);

		FVector DebugDrawLocation = LockComp.WorldLocation;
		// We should follow a spline
		if(LockComp.InputSpline != nullptr && TriggerOwner != nullptr)
		{
			FVector CameraLocation = TriggerOwner.FindClosestPoint(EditorViewLocation + (EditorViewRotation.ForwardVector * 1000));
			FSplinePosition SplineLocation = LockComp.InputSpline.Spline.GetClosestSplinePositionToWorldLocation(CameraLocation);
			DebugDrawLocation = TriggerOwner.FindClosestPoint(SplineLocation.WorldLocation);		
		}
	
		FInputPlaneLock InputLock = LockComp.GetHorizontalVerticalDirection(DebugDrawLocation);

		const float Size = 500;
		//DrawCoordinateSystem(DebugDrawLocation, InputOrientation, Size, 3);
		DrawArrow(DebugDrawLocation, DebugDrawLocation + (InputLock.UpDown * Size), FLinearColor::Red);
		DrawWorldString("Stick Up/Down", DebugDrawLocation + (InputLock.UpDown * Size), FLinearColor::Red);

		DrawArrow(DebugDrawLocation, DebugDrawLocation + (InputLock.LeftRight * Size), FLinearColor::Green);
		DrawWorldString("Stick Left/Right", DebugDrawLocation + (InputLock.LeftRight * Size), FLinearColor::Green);

	}
}
#endif
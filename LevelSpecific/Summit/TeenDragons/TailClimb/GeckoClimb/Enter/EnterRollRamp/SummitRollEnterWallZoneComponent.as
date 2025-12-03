enum ESummitRollEnterWallZoneMode
{
	LeavingGround,
	EnteringZone
}

class USummitRollEnterWallZoneComponent : USceneComponent
{
	// Make sure this is actor has a tail climbable component
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor ClimbableWall;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector LandingOffset;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ESummitRollEnterWallZoneMode Mode = ESummitRollEnterWallZoneMode::LeavingGround;

	/** If it should care how much you are facing the wall */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDisregardFacing = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinRollSpeed = 4100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float CameraBlendTime = 1.0;
	
	/** How fast the visualizer should assume the dragon will be going */
	UPROPERTY(EditAnywhere, Category = "Visualizer Settings", Meta = (ClampMin = 0))
	float SimulatedRollSpeed = 4100;

	UPROPERTY(EditAnywhere, Category = "Visualizer Settings")
	float DragonGravityMagnitude = 6750.0;

	APlayerTrigger Trigger;
	UTeenDragonTailClimbableComponent ClimbableComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger = Cast<APlayerTrigger>(Owner);
		devCheck(Trigger != nullptr, f"{this.Name} was not attached to a player trigger, it will not work then");

		ClimbableComp = UTeenDragonTailClimbableComponent::Get(ClimbableWall);
		devCheck(ClimbableComp != nullptr, f"{this.Name} does not have a functioning climbable wall reference, make sure it is referencing a wall with a climbable component");

		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		Trigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp != nullptr)
		{
			ClimbComp.RollEnterZoneCompsCurrentlyInside.AddUnique(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp != nullptr)
		{
			ClimbComp.RollEnterZoneCompsCurrentlyInside.RemoveSingleSwap(this);
		}
	}

	FVector GetLandingLocation()
	{
		ClimbableComp = UTeenDragonTailClimbableComponent::Get(ClimbableWall);
		return ClimbableComp.WorldLocation + LandingOffset;
	}
};

#if EDITOR
class USummitRollEnterWallZoneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollEnterWallZoneComponent;

	const float DragonCapsuleRadius = 130.0;

	FVector SimulatedLocation;
	FVector SimulatedVelocity;  
	float LastTimeStamp;
	float TimeToReachTarget;

	bool bHasStartedSimulation = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollEnterWallZoneComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;
		
		if(Comp.ClimbableWall == nullptr)
			return;
		
		auto ClimbableComp = UTeenDragonTailClimbableComponent::Get(Comp.ClimbableWall);
		if(ClimbableComp == nullptr)
			return;

		const FVector LaunchLocation = Comp.WorldLocation
			+ Comp.UpVector * DragonCapsuleRadius;

		const FVector LandLocation = Comp.GetLandingLocation()
			+ ClimbableComp.Owner.ActorUpVector * DragonCapsuleRadius
			+ ClimbableComp.ForwardVector * DragonCapsuleRadius;

		VisualizeLaunchPoint(LaunchLocation, Comp.ForwardVector);
		VisualizeRollJump(LaunchLocation, LandLocation, Comp);
		VisualizeLandPoint(LandLocation);
	}

	void VisualizeLaunchPoint(FVector LaunchLocation, FVector LaunchDirection)
	{
		DrawWireSphere(LaunchLocation, DragonCapsuleRadius, FLinearColor::Black, 10, 12, false);
		DrawArrow(LaunchLocation, LaunchLocation + LaunchDirection * 500, FLinearColor::Red, 40, 20, false);
	}

	void VisualizeRollJump(FVector LaunchLocation, FVector LandLocation, USummitRollEnterWallZoneComponent Comp)
	{
		float TimeStamp = Time::GameTimeSeconds;
		float DeltaTime = TimeStamp - LastTimeStamp;
		LastTimeStamp = TimeStamp;

		if(TimeToReachTarget <= 0)
			bHasStartedSimulation = false;
		
		FVector LaunchVelocity = Comp.ForwardVector * Comp.SimulatedRollSpeed;
		
		if(!bHasStartedSimulation)
		{
			SimulatedLocation = LaunchLocation;
			SimulatedVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(SimulatedLocation, LandLocation, Comp.DragonGravityMagnitude, LaunchVelocity.Size());
			
			FVector DeltaToTarget = (LandLocation - LaunchLocation);
			FVector VerticalToTarget = DeltaToTarget.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalToTarget = DeltaToTarget - VerticalToTarget;
			float HorizontalDistance = HorizontalToTarget.Size();

			FVector VerticalVelocity = SimulatedVelocity.ProjectOnToNormal(FVector::UpVector);
			FVector HorizontalVelocity = SimulatedVelocity - VerticalVelocity;
			float HorizontalSpeed = HorizontalVelocity.Size();
			TimeToReachTarget = HorizontalDistance / HorizontalSpeed;
			bHasStartedSimulation = true;
		}

		TimeToReachTarget -= DeltaTime;

		SimulatedVelocity += FVector::DownVector * Comp.DragonGravityMagnitude * DeltaTime;
		SimulatedLocation += SimulatedVelocity * DeltaTime;

		DrawWireSphere(SimulatedLocation, DragonCapsuleRadius, FLinearColor::Green, 10, 12, false);
	}

	void VisualizeLandPoint(FVector LandLocation)
	{
		DrawWireSphere(LandLocation, 130, FLinearColor::White, 10, 12, false);
	}
}
#endif
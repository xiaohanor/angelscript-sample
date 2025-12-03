event void FIslandStormdrainAlternatingCogWheelElevatorOnTriedGoingDownPastBottom();

class AIslandStormdrainAlternatingCogWheelElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UStaticMeshComponent ElevatorMesh;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	USceneComponent CogWheelRoot;

	UPROPERTY(DefaultComponent, Attach = CogWheelRoot)
	UStaticMeshComponent CogWheelMesh;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent MovingShakeComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandStormdrainAlternatingCogWheelElevatorGoDownCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandStormdrainAlternatingCogWheelElevatorGoUpCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandStormdrainAlternatingCogWheelElevatorTriedGoingDownAtBottomCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandStormdrainAlternatingCogWheelElevatorDummyComponent DummyComp;
#endif

	/** How many rotations of the cog per move down
	 * (If set to 1, the elevator will move down enough for the cog to rotate around once) */
	UPROPERTY(EditAnywhere, Category = "Move Down")
	float MoveDownRotations = 0.5;

	/** Multiplier for rotation
	 * (Leave at 1.0 if you want it to rotate like it should)
	 * Modifies how far the elevator moves down */
	UPROPERTY(EditAnywhere, Category = "Move Down")
	float RotationMultiplier = 4.0;

	UPROPERTY(EditAnywhere, Category = "Move Down")
	float MoveDownMaxSpeed = 500.0;

	UPROPERTY(EditAnywhere, Category = "Move Down")
	float MoveDownAcceleration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Move Down")
	int TimesToMoveDown = 4;

	UPROPERTY(EditAnywhere, Category = "Move Up")
	float TimeAfterShootingUntilElevatorMovesUp = 4.0;

	UPROPERTY(EditAnywhere, Category = "Move Up")
	float MoveUpMaxSpeed = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Move Up")
	float MoveUpAcceleration = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel FirstPanel;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel SecondPanel;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float CogRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> StopMovingCameraShake;

	UPROPERTY(EditAnywhere)
	FHazeFrameForceFeedback MovingFF;

	UPROPERTY(Category = "Events")
	FIslandStormdrainAlternatingCogWheelElevatorOnTriedGoingDownPastBottom OnTriedGoingPastBottom;

	int TimesMovedDown = 0;
	FVector ElevatorStartLocation;
	float TimePanelLastShot;
	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ElevatorStartLocation = ElevatorRoot.WorldLocation;

		FirstPanel.AttachToComponent(CogWheelRoot, n"Name_NONE", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		SecondPanel.AttachToComponent(CogWheelRoot, n"Name_NONE", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
	
		FirstPanel.OverchargeComp.OnImpactEvent.AddUFunction(this, n"OnPanelShot");
		SecondPanel.OverchargeComp.OnImpactEvent.AddUFunction(this, n"OnPanelShot");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPanelShot(FIslandRedBlueImpactResponseParams Data)
	{
		TimePanelLastShot = Time::GameTimeSeconds;
	}

	void TogglePanelForPlayer(AIslandOverloadShootablePanel Panel, AHazePlayerCharacter Player, bool bActivate)
	{
		if(bActivate)
		{
			Panel.OverchargeComp.UnblockImpactForPlayer(Player, this);
			Panel.OverchargeComp.RemoveComponentTickBlocker(this);
			Panel.TargetComp.EnableForPlayer(Player, this);
		}
		else
		{
			Panel.OverchargeComp.BlockImpactForPlayer(Player, this);
			Panel.OverchargeComp.AddComponentTickBlocker(this);
			Panel.TargetComp.DisableForPlayer(Player, this);
		}
	}

	void RotateCog(float MoveDelta)
	{
		float PitchRotation = -MoveDelta / CogRadius;
		PitchRotation = Math::RadiansToDegrees(PitchRotation) * RotationMultiplier; 
		CogWheelRoot.AddLocalRotation(FRotator(-PitchRotation, 0, 0));
	}

	void FixupCogRotationAtEndOfMove()
	{
		CogWheelRoot.RelativeRotation = FRotator(TimesMovedDown * MoveDownRotations * 360, 0, 0);
	}

	void StopElevator()
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		MovingShakeComp.DeactivateMovableCameraShake();
		if(TimesMovedDown == 3)
		{
			FirstPanel.DisablePanel();
		}
		// for(auto Player : Game::Players)
		// {
		// 	Player.PlayWorldCameraShake(StopMovingCameraShake, this, ElevatorRoot.WorldLocation, 0, 5000);
		// }
	}

	float GetMoveDownLength() const property
	{
		return CogRadius * Math::DegreesToRadians((360 * MoveDownRotations) / RotationMultiplier);
	}

	UFUNCTION(BlueprintPure)
	float GetElevatorPositionAlpha() const
	{
		FVector LowestPoint = ElevatorStartLocation + FVector::DownVector * (MoveDownLength * TimesToMoveDown);
		return Math::Saturate(Math::NormalizeToRange(ElevatorRoot.WorldLocation.Z, LowestPoint.Z, ElevatorStartLocation.Z));
	}
}

#if EDITOR
class UIslandStormdrainAlternatingCogWheelElevatorDummyComponent : UActorComponent {};
class UIslandStormdrainAlternatingCogWheelElevatorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainAlternatingCogWheelElevatorDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeComponent = Cast<UIslandStormdrainAlternatingCogWheelElevatorDummyComponent>(Component);
		if(VisualizeComponent == nullptr)
			return;

		auto Elevator = Cast<AIslandStormdrainAlternatingCogWheelElevator>(VisualizeComponent.Owner);
		if(Elevator == nullptr)
			return;
		
		DrawWireSphere(Elevator.ElevatorRoot.WorldLocation, 50.0, FLinearColor::White, 25, 12, false);
		FVector Start = Elevator.ElevatorRoot.WorldLocation;

		for(int i = 0 ; i < Elevator.TimesToMoveDown ; i++)
		{
			FVector MoveDownDelta = Elevator.ElevatorRoot.UpVector * Elevator.MoveDownLength;
			FVector MovedDownLocation = Elevator.ElevatorRoot.WorldLocation - (MoveDownDelta + MoveDownDelta * i);
			FLinearColor PanelColor = FLinearColor::White;

			// Is even
			if(i%2 == 0)
			{
				if(Elevator.FirstPanel != nullptr)
				{
					if(Elevator.FirstPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			else
			{
				if(Elevator.SecondPanel != nullptr)
				{
					if(Elevator.SecondPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			
			DrawArrow(Start, MovedDownLocation, PanelColor, 40, 20);

			Start = MovedDownLocation;
		}

		DrawWireCylinder(Elevator.CogWheelMesh.WorldLocation, Elevator.CogWheelMesh.WorldRotation
			, FLinearColor::Green, Elevator.CogRadius, 30, 12, 5, false);
	}
}
#endif

UCLASS(Abstract)
class UIslandStormdrainAlternatingCogWheelElevatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPassed180DegreesOfRotationGoingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedHighestPosition() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedLowestPosition() {}
}
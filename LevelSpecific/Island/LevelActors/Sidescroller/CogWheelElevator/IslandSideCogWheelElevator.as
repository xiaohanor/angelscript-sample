event void FIslandSidescrollerAlternatingCogWheelElevatorOnTriedGoingDownPastBottom();

class AIslandSidescrollerAlternatingCogWheelElevator : AHazeActor
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
	UStaticMeshComponent LeftCogWheelMesh;
	
	UPROPERTY(DefaultComponent, Attach = CogWheelRoot)
	UStaticMeshComponent RightCogWheelMesh;

	UPROPERTY(DefaultComponent, Attach = LeftCogWheelMesh)
	USceneComponent LeftGoUpPanelRoot;

	UPROPERTY(DefaultComponent, Attach = LeftCogWheelMesh)
	USceneComponent LeftGoDownPanelRoot;

	UPROPERTY(DefaultComponent, Attach = RightCogWheelMesh)
	USceneComponent RightGoUpPanelRoot;

	UPROPERTY(DefaultComponent, Attach = RightCogWheelMesh)
	USceneComponent RightGoDownPanelRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandStormdrainAlternatingCogWheelElevatorMoveCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSidescrollerAlternatingCogWheelElevatorDummyComponent DummyComp;
#endif

	/** How many rotations of the cog per move down
	 * (If set to 1, the elevator will move down enough for the cog to rotate around once) */
	UPROPERTY(EditAnywhere, Category = "Move")
	float MoveRotations = 0.5;

	/** Multiplier for rotation
	 * (Leave at 1.0 if you want it to rotate like it should)
	 * Modifies how far the elevator moves down */
	UPROPERTY(EditAnywhere, Category = "Move")
	float RotationMultiplier = 4.0;

	UPROPERTY(EditAnywhere, Category = "Move")
	float MoveMaxSpeed = 500.0;

	UPROPERTY(EditAnywhere, Category = "Move")
	float MoveAcceleration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Move")
	int TimesToMoveDown = 4;

	UPROPERTY(EditAnywhere, Category = "Move")
	int TimesToMoveUp = 4;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel LeftGoUpPanel;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel LeftGoDownPanel;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel RightGoUpPanel;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AIslandOverloadShootablePanel RightGoDownPanel;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float CogRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> StopMovingCameraShake;

	UPROPERTY(Category = "Events")
	FIslandSidescrollerAlternatingCogWheelElevatorOnTriedGoingDownPastBottom OnTriedGoingPastBottom;

	int TimesMovedDown = 0;
	FVector ElevatorStartLocation;
	bool bIsMoving = false;

	TArray<AIslandOverloadShootablePanel> Panels;
	FVector InitialCogWheelForward;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ElevatorStartLocation = ElevatorRoot.WorldLocation;

		Panels.Add(LeftGoUpPanel);
		Panels.Add(LeftGoDownPanel);
		Panels.Add(RightGoUpPanel);
		Panels.Add(RightGoDownPanel);

		InitialCogWheelForward = CogWheelRoot.ForwardVector;

		TogglePanelsBasedOnFacing();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(LeftGoUpPanel != nullptr)
		{
			LeftGoUpPanel.AttachToComponent(LeftGoUpPanelRoot, n"SOCKET_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			LeftGoUpPanel.ActorScale3D = FVector::OneVector;
		}

		if(LeftGoDownPanel != nullptr)
		{
			LeftGoDownPanel.AttachToComponent(LeftGoDownPanelRoot, n"SOCKET_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			LeftGoDownPanel.ActorScale3D = FVector::OneVector;
		}
		
		if(RightGoUpPanel != nullptr)
		{
			RightGoUpPanel.AttachToComponent(RightGoUpPanelRoot, n"SOCKET_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			RightGoUpPanel.ActorScale3D = FVector::OneVector;
		}
		
		if(RightGoDownPanel != nullptr)
		{
			RightGoDownPanel.AttachToComponent(RightGoDownPanelRoot, n"SOCKET_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			RightGoDownPanel.ActorScale3D = FVector::OneVector;
		}
	}

	void TogglePanels(bool bActivate)
	{
		for(auto Panel : Panels)
		{
			AHazePlayerCharacter PlayerToBlockPanelFor = Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 

			if(bActivate)
			{
				Panel.OverchargeComp.UnblockImpactForPlayer(PlayerToBlockPanelFor, this);
				Panel.TargetComp.EnableForPlayer(PlayerToBlockPanelFor, this);
			}
			else
			{
				Panel.OverchargeComp.BlockImpactForPlayer(PlayerToBlockPanelFor, this);
				Panel.TargetComp.DisableForPlayer(PlayerToBlockPanelFor, this);
			}
		}

	}

	void TogglePanelsBasedOnFacing()
	{
		for(auto Panel : Panels)
		{
			AHazePlayerCharacter PlayerToBlockPanelFor = Panel.OverchargeComp.OverchargeColor == EIslandRedBlueOverchargeColor::Red ? Game::Mio : Game::Zoe; 
			
			FVector DirToPanel = (CogWheelRoot.WorldLocation - Panel.ActorLocation).GetSafeNormal();
			bool bPanelIsOnFrontSide = DirToPanel.DotProduct(InitialCogWheelForward) < 0;

			if(bPanelIsOnFrontSide)
			{
				Panel.OverchargeComp.UnblockImpactForPlayer(PlayerToBlockPanelFor, this);
				Panel.TargetComp.EnableForPlayer(PlayerToBlockPanelFor, this);
			}
			else
			{
				Panel.OverchargeComp.BlockImpactForPlayer(PlayerToBlockPanelFor, this);
				Panel.TargetComp.DisableForPlayer(PlayerToBlockPanelFor, this);
			}
		}
	}

	void RotateCog(float DeltaTime, float CurrentSpeed)
	{
		float PitchRotation = -CurrentSpeed * DeltaTime / CogRadius;
		PitchRotation = Math::RadiansToDegrees(PitchRotation) * RotationMultiplier; 
		CogWheelRoot.AddLocalRotation(FRotator(-PitchRotation, 0, 0));
	}

	void FixupCogRotationAtEndOfMove()
	{
		CogWheelRoot.RelativeRotation = FRotator(TimesMovedDown * MoveRotations * 360, 0, 0);
	}

	void StopElevator()
	{
		for(auto Player : Game::Players)
		{
			Player.PlayWorldCameraShake(StopMovingCameraShake, this, ElevatorRoot.WorldLocation, 0, 5000);
		}
	}

	float GetMoveLength() const property
	{
		return CogRadius * Math::DegreesToRadians((360 * MoveRotations) / RotationMultiplier);
	}
}

#if EDITOR
class UIslandSidescrollerAlternatingCogWheelElevatorDummyComponent : UActorComponent {};
class UIslandSidescrollerAlternatingCogWheelElevatorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSidescrollerAlternatingCogWheelElevatorDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeComponent = Cast<UIslandSidescrollerAlternatingCogWheelElevatorDummyComponent>(Component);
		if(VisualizeComponent == nullptr)
			return;

		auto Elevator = Cast<AIslandSidescrollerAlternatingCogWheelElevator>(VisualizeComponent.Owner);
		if(Elevator == nullptr)
			return;
		
		DrawWireSphere(Elevator.ElevatorRoot.WorldLocation, 50.0, FLinearColor::White, 25, 12, false);
		FVector Start = Elevator.ElevatorRoot.WorldLocation;

		for(int i = 0 ; i < Elevator.TimesToMoveDown ; i++)
		{
			FVector MoveDownDelta = Elevator.ElevatorRoot.UpVector * Elevator.MoveLength;
			FVector MovedDownLocation = Elevator.ElevatorRoot.WorldLocation - (MoveDownDelta + MoveDownDelta * i);
			FLinearColor PanelColor = FLinearColor::White;

			// Is even
			if(i%2 == 0)
			{
				if(Elevator.LeftGoDownPanel != nullptr)
				{
					if(Elevator.LeftGoDownPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			else
			{
				if(Elevator.RightGoDownPanel != nullptr)
				{
					if(Elevator.RightGoDownPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			
			DrawArrow(Start, MovedDownLocation, PanelColor, 40, 20);

			Start = MovedDownLocation;
		}

		Start = Elevator.ElevatorRoot.WorldLocation;
		for(int i = 0 ; i < Elevator.TimesToMoveUp ; i++)
		{
			FVector MoveDownDelta = Elevator.ElevatorRoot.UpVector * Elevator.MoveLength;
			FVector MovedDownLocation = Elevator.ElevatorRoot.WorldLocation + (MoveDownDelta + MoveDownDelta * i);
			FLinearColor PanelColor = FLinearColor::White;

			// Is even
			if(i%2 == 0)
			{
				if(Elevator.RightGoUpPanel != nullptr)
				{
					if(Elevator.RightGoUpPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			else
			{
				if(Elevator.LeftGoUpPanel != nullptr)
				{
					if(Elevator.LeftGoUpPanel.UsableByPlayer == EHazePlayer::Mio)
						PanelColor = FLinearColor::Red;
					else
						PanelColor = FLinearColor::Blue;
				}
			}
			
			DrawArrow(Start, MovedDownLocation, PanelColor, 40, 20);

			Start = MovedDownLocation;
		}

		const float CylinderHalfHeight = 125.0;

		DrawWireCylinder(Elevator.LeftCogWheelMesh.WorldLocation + Elevator.LeftCogWheelMesh.UpVector * CylinderHalfHeight, Elevator.LeftCogWheelMesh.WorldRotation
			, FLinearColor::Green, Elevator.CogRadius, CylinderHalfHeight, 12, 5, false);
	
		DrawWireCylinder(Elevator.RightCogWheelMesh.WorldLocation+ Elevator.RightCogWheelMesh.UpVector * CylinderHalfHeight, Elevator.RightCogWheelMesh.WorldRotation
		, FLinearColor::Green, Elevator.CogRadius, CylinderHalfHeight, 12, 5, false);
	}
}
#endif
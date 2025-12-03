class AIslandSidescrollerSeeSawElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent UpwardsTranslateComp;
	default UpwardsTranslateComp.bConstrainZ = true;
	default UpwardsTranslateComp.MaxZ = 5000.0;
	default UpwardsTranslateComp.bConstrainX = true;
	default UpwardsTranslateComp.bConstrainY = true;
	default UpwardsTranslateComp.ConstrainBounce = 0.0;

	UPROPERTY(DefaultComponent, Attach = UpwardsTranslateComp)
	UFauxPhysicsTranslateComponent SidewaysTranslateComp;
	default SidewaysTranslateComp.bConstrainY = true;
	default SidewaysTranslateComp.MinY = -1500.0;
	default SidewaysTranslateComp.MaxY = 1500.0;
	default SidewaysTranslateComp.bConstrainZ = true;
	default SidewaysTranslateComp.MinZ = 0.0;
	default SidewaysTranslateComp.MaxZ = 0.0;

	UPROPERTY(DefaultComponent, Attach = SidewaysTranslateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default AxisRotateComp.LocalRotationAxis = FVector(1.0, 0.0, 0.0);
	default AxisRotateComp.bConstrain = true;
	default AxisRotateComp.ConstrainAngleMin = -25.0;
	default AxisRotateComp.ConstrainAngleMax = 25.0;
	default AxisRotateComp.SpringStrength = 1.0;
	default AxisRotateComp.ConstrainBounce = 0.0;
	default AxisRotateComp.Friction = 0.8;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent StaticMeshComp;

	UPROPERTY(DefaultComponent, Attach = StaticMeshComp)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSidescrollerSeeSawElevatorDummyComponent DummyComp;
#endif
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerWeightMagnitude = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ElevatorMovementSpeedUpwards = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ElevatorFullyTiltedMovementSpeed = 200.0;

	TPerPlayer<bool> IsOnPlatform;
	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerImpactedGround");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeftGround");

		UpwardsTranslateComp.OnConstraintHit.AddUFunction(this, n"OnUpwardsConstraintHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnUpwardsConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
			AddActorTickBlock(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void PlayerImpactedGround(AHazePlayerCharacter Player)
	{
		IsOnPlatform[Player] = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void PlayerLeftGround(AHazePlayerCharacter Player)
	{
		IsOnPlatform[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMoving)
		{
			MoveUpwards(DeltaSeconds);
			RotatePlatform(DeltaSeconds);
			MoveSideways(DeltaSeconds);
		}
		else
		{
			
			bool bBothPlayersAreOnPlatform = true;
			for(auto Player : Game::Players)
			{
				if(!IsOnPlatform[Player])
					bBothPlayersAreOnPlatform = false;
			}
			if(bBothPlayersAreOnPlatform)
			{
				bIsMoving = true;
			}
		}
	}

	private void MoveUpwards(float DeltaTime)
	{
		UpwardsTranslateComp.ApplyForce(FVector::ZeroVector, FVector::UpVector * ElevatorMovementSpeedUpwards);
	}

	private void RotatePlatform(float DeltaTime)
	{
		for(auto Player : Game::Players)
		{
			if(!IsOnPlatform[Player])
				continue;
			
			FauxPhysics::ApplyFauxForceToParentsAt(AxisRotateComp, Player.ActorLocation, FVector::DownVector * PlayerWeightMagnitude);
		}
	}

	private void MoveSideways(float DeltaTime)
	{
		float TiltAlpha = AxisRotateComp.RelativeRotation.Roll / AxisRotateComp.ConstrainAngleMax;
		SidewaysTranslateComp.ApplyMovement(FVector::ZeroVector, SidewaysTranslateComp.RightVector * ElevatorFullyTiltedMovementSpeed * TiltAlpha * DeltaTime);
	}


	UFUNCTION(BlueprintCallable)
	void ApplyImpulseToElevator(FVector Location, FVector Impulse)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Location, Impulse);
	}
};

#if EDITOR
class UIslandSidescrollerSeeSawElevatorDummyComponent : UActorComponent {};
class UIslandSidescrollerSeeSawElevatorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSidescrollerSeeSawElevatorDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeComponent = Cast<UIslandSidescrollerSeeSawElevatorDummyComponent>(Component);
		if(VisualizeComponent == nullptr)
			return;
		
		auto Elevator = Cast<AIslandSidescrollerSeeSawElevator>(Component.Owner);
		if(Elevator == nullptr)
			return;
	}
}
#endif
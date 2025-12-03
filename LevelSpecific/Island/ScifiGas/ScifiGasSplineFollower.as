
class AScifiGasSplineFollower : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent GasZoneActivator;
	default GasZoneActivator.CollisionProfileName = n"PlayerCharacter";
	default GasZoneActivator.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent MoveDirectionEditorComponent;
	default MoveDirectionEditorComponent.bIsEditorOnly = true;
	default MoveDirectionEditorComponent.bHiddenInGame = false;
	default MoveDirectionEditorComponent.ArrowSize = 3.0;
	default MoveDirectionEditorComponent.ArrowLength = 40.0;

	// The actor containing the spline
	UPROPERTY(EditAnywhere)
	AActor SplineActor;

	/** If true, we will stay close the the player in front,
	 * else the one in the back
	 * making it harder for the player laggin behind
	 */ 
	UPROPERTY(EditAnywhere)
	bool bFollowPlayerThatIsAhead = true;

	/** The distance to the player we are following, we want to keep. 
	 * @Max; in front of the player
	 * @Min; behind the player
	*/
	UPROPERTY(EditAnywhere)
	FHazeRange DesiredDistance = FHazeRange(-500.0, 1000.0);

	// When the distance is bigger than the desired distance, this speed is used
	UPROPERTY(EditAnywhere)
	float CathUpSpeed = 2000.0;

	// If true, we will match the players current speed while we are inside the desired ranges
	UPROPERTY(EditAnywhere)
	bool bMatchPlayerSpeedWhileInsideRange = false;

	/** When we are closer than the desired distance, this is the speed we use
	 * @Min; when we are at the same position as the player
	 * @Max; when we are almost at the desired distance
	 */ 
	UPROPERTY(EditAnywhere, meta = (EditCondition = "!bMatchPlayerSpeedWhileInsideRange"))
	FHazeRange InsideRangeSpeed = FHazeRange(0.0, 500.0);

	/** How fast the desired speed is reached.
	 * Use 0 to instantly reach the desired speed
	 */
	UPROPERTY(EditAnywhere)
	float MoveSpeedAcceleration = 0;

	UPROPERTY(EditInstanceOnly)
	bool bDrawDebugValues = false;

	UHazeSplineComponent Spline;
	FSplinePosition SplinePosition;
	float CurrentMoveSpeed = 0;

	UFUNCTION()
	void ActivateSplineMovement()
	{
		Spline = Spline::GetGameplaySpline(SplineActor, this);
		devCheck(Spline != nullptr, "Add an actor with a spline component");

		SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		SetActorLocation(SplinePosition.WorldLocation);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Players = Game::GetPlayers();
		
		TPerPlayer<FSplinePosition> PlayerSplinePosition;
		int IndexToFollow = -1;
		TPerPlayer<float> PlayerDistanceOnSpline;

		// Setup what player to follow
		for(auto Player : Players)
		{
			PlayerSplinePosition[Player] = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
			PlayerDistanceOnSpline[Player] = PlayerSplinePosition[Player].GetCurrentSplineDistance();
		}

		// Setup what player to follow
		if(bFollowPlayerThatIsAhead)
		{
			if(PlayerDistanceOnSpline[0] < PlayerDistanceOnSpline[1])
				IndexToFollow = 0;
			else
				IndexToFollow = 1;
		}
		else
		{
			if(PlayerDistanceOnSpline[0] > PlayerDistanceOnSpline[1])
				IndexToFollow = 0;
			else
				IndexToFollow = 1;
		}

		// Setup the near plane for the movespeed
		FSplinePosition NearRangeSplinePosition = PlayerSplinePosition[IndexToFollow];
		NearRangeSplinePosition.Move(DesiredDistance.Min - KINDA_SMALL_NUMBER);
		float DistanceToNearPlane = Math::Abs(NearRangeSplinePosition.GetCurrentSplineDistance() - SplinePosition.GetCurrentSplineDistance());

		// Setup the far plane for the movespeed
		FSplinePosition FarRangeSplinePosition = PlayerSplinePosition[IndexToFollow];
		FarRangeSplinePosition.Move(DesiredDistance.Max + KINDA_SMALL_NUMBER);
		float DistanceToFarPlane = Math::Abs(FarRangeSplinePosition.GetCurrentSplineDistance() - SplinePosition.GetCurrentSplineDistance());

		float TargetMoveSpeed = 0;
		
		// To far behind, need to catch up
		if(SplinePosition.CurrentSplineDistance < NearRangeSplinePosition.CurrentSplineDistance)
		{
			TargetMoveSpeed = CathUpSpeed;
		}
		else
		{
			float DistanceBetweenPlanes = Math::Abs(Math::Abs(DesiredDistance.Min) - Math::Abs(DesiredDistance.Max));
			if(bMatchPlayerSpeedWhileInsideRange || DistanceBetweenPlanes <= 0)
			{
				AHazePlayerCharacter PlayerToFollow = Players[IndexToFollow];
				TargetMoveSpeed = PlayerToFollow.GetActorVelocity().VectorPlaneProject(FVector::UpVector).Size();
			}
			else
			{
				float Alpha = Math::Clamp((DistanceToFarPlane - DistanceToNearPlane) / DistanceBetweenPlanes, 0.0, 1.0);	
				TargetMoveSpeed = InsideRangeSpeed.Lerp(Alpha);
			}
		}

		if(MoveSpeedAcceleration <= KINDA_SMALL_NUMBER)
		{
			CurrentMoveSpeed = TargetMoveSpeed;
		}
		else
		{
			CurrentMoveSpeed = Math::FInterpConstantTo(CurrentMoveSpeed, TargetMoveSpeed, DeltaSeconds, MoveSpeedAcceleration);
		}

		if(SplinePosition.Move(CurrentMoveSpeed * DeltaSeconds))
		{
			SetActorLocation(SplinePosition.WorldLocation);
			SetActorRotation(SplinePosition.WorldRotation);
		}

		auto TraceSettings = Trace::InitFromPrimitiveComponent(GasZoneActivator);
		auto Overlaps = TraceSettings.QueryOverlaps(ActorLocation);
		for(auto Overlap : Overlaps)
		{
			auto GasZone = Cast<AScifiGasZone>(Overlap.Actor);
			if(GasZone == nullptr)
				continue;

			if(GasZone.GasIsActive())
				continue;

			GasZone.ActivateGas();	
		}

		// DEBUG
		#if EDITOR
		if(bDrawDebugValues)
		{
			FVector DebugLocation = PlayerSplinePosition[IndexToFollow].WorldLocation;
			AHazePlayerCharacter PlayerToFollow = Players[IndexToFollow];
			Debug::DrawDebugSphere(ActorCenterLocation);
			Debug::DrawDebugArrow(DebugLocation + (FVector::UpVector * 150), DebugLocation, 40, Thickness = 5, LineColor = FLinearColor::Red);

			FVector DirBetweenPositions = (FarRangeSplinePosition.WorldLocation - NearRangeSplinePosition.WorldLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			Debug::DrawDebugPlane(FarRangeSplinePosition.WorldLocation, DirBetweenPositions, LineColor = FLinearColor::Blue);
			Debug::DrawDebugPlane(NearRangeSplinePosition.WorldLocation, DirBetweenPositions, LineColor = FLinearColor::LucBlue);

			FLinearColor DebugColor = FLinearColor::White;
			if(SplinePosition.CurrentSplineDistance < DistanceToNearPlane)
			{
				DebugColor = FLinearColor::Red;
			}
			else
			{
				DebugColor = FLinearColor::LucBlue;
			}

			Debug::DrawDebugArrow(ActorCenterLocation, PlayerToFollow.ActorCenterLocation, LineColor = DebugColor);
			PrintToScreen("Gas Follower distance to far; " + DistanceToFarPlane);
			PrintToScreen("Gas Follower distance to near; " + DistanceToNearPlane);
			PrintToScreen("Gas Follower Player Spline distance; " + PlayerDistanceOnSpline[IndexToFollow]);
			PrintToScreen("Gas Follower Spline distance; " + SplinePosition.CurrentSplineDistance);
		}
		#endif
	}
}
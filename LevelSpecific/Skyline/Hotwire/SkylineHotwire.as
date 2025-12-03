class ASkylineHotwire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	USceneComponent MioPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent ZoePivot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHotwireConnectCapability");

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	float Radius = 13.0;

	UPROPERTY(EditAnywhere)
	float ConnectionWidth = 2.0;

	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerFullscreen = EHazePlayer::Mio;

	TArray<ASkylineHotwireNode> Nodes;
	TArray<ASkylineHotwireTool> ConnectedTools;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Nodes = GetAttachedNodes();

		for (auto Node : Nodes)
			Node.AttachToComponent(RotationPivot, AttachmentRule = EAttachmentRule::KeepWorld);


		Game::Mio.ActivateCamera(Camera, 2.0, this);
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotationPivot.AddLocalRotation(FRotator(RotationSpeed * DeltaSeconds, 0.0, 0.0));

		PrintToScreen("ConnectedTools: " + ConnectedTools.Num(), 0.0, FLinearColor::Green);
/*
		for (auto Player : Game::Players)
		{
			USceneComponent ToolComp = (Player.IsMio() ? MioPivot : ZoePivot);

			ToolComp.RelativeLocation += FVector(0.0, UserComps[Player].Input.X, UserComps[Player].Input.Y) * 0.5;
			ToolComp.RelativeScale3D = (UserComps[Player].bIsActivated ? FVector::OneVector * 0.9 : FVector::OneVector);
		}
*/

		if (IsConnected())
		{
//			Debug::DrawDebugLine(ConnectedTools[0].Pivot.WorldLocation, ConnectedTools[1].Pivot.WorldLocation, FLinearColor::LucBlue, ConnectionWidth, 0.0);
//			ConnectNodes();
		}
	}

	UFUNCTION()
	private void HandleToolConnect(ASkylineHotwireTool Tool)
	{
		ConnectedTools.Add(Tool);

		if (IsConnected())
		{
			//Debug::DrawDebugLine(ConnectedTools[0].Pivot.WorldLocation, ConnectedTools[1].Pivot.WorldLocation, FLinearColor::LucBlue, ConnectionWidth, 1.0);
			DrawSegmentedConnectionDebugLine();
			ConnectNodes();
		}
	}

	UFUNCTION()
	private void HandleToolDisconnect(ASkylineHotwireTool Tool)
	{
		ConnectedTools.Remove(Tool);
	}

	bool IsConnected()
	{
		/*
		for (auto Player : Game::Players)
		{
			if (!UserComps[Player].bIsActivated)
				return false;
		}
		*/
		return ConnectedTools.Num() == 2;
	}

	void ConnectNodes()
	{
		FVector LineStart = ConnectedTools[0].Pivot.WorldLocation;
		FVector LineEnd = ConnectedTools[1].Pivot.WorldLocation;
	
		for (auto Node : Nodes)
		{
			if (Node.ActorLocation.Distance(Math::ClosestPointOnLine(LineStart, LineEnd, Node.ActorLocation)) <= ConnectionWidth)
			{
				if (Node.bIsActivated)
					Node.Deactivate();
				else
					Node.Activate();
			}
		}
	}

	void DrawSegmentedConnectionDebugLine(int Segments = 12)
	{
		FVector LineStart = ConnectedTools[0].Pivot.WorldLocation;
		FVector LineEnd = ConnectedTools[1].Pivot.WorldLocation;
		FVector ToEnd = LineEnd - LineStart;

//		Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Green, ConnectionWidth * 0.5, 1.0);			

		TArray<FVector> Points;

		for (int i = 0; i < Segments; i++)
		{
			FVector Point = LineStart + ToEnd * i / Segments;
			Point = GetProjectedPointOnCylinder(Point - RotationPivot.WorldLocation);
			Points.Add(Point);

			Debug::DrawDebugPoint(Point, 20.0, FLinearColor::Red, 2.0);
		}

		for (int i = 0; i < Points.Num() - 1; i++)
		{
			Debug::DrawDebugLine(RotationPivot.WorldLocation + Points[i], RotationPivot.WorldLocation + Points[i + 1], FLinearColor::LucBlue, ConnectionWidth, 1.0);			
		}
	}

	TArray<ASkylineHotwireNode> GetAttachedNodes()
	{
		TArray<ASkylineHotwireNode> AttachedNodes;

		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto AttachedActor : AttachedActors)
		{
			auto AttachedNode = Cast<ASkylineHotwireNode>(AttachedActor);
			if (AttachedNode == nullptr)
				continue;

			AttachedNodes.Add(AttachedNode);
		}

		return AttachedNodes;
	}

	FVector GetProjectedPointOnCylinder(FVector Location)
	{
		FVector Direction = Location.VectorPlaneProject(RotationPivot.RightVector).SafeNormal * Radius;
		FVector ProjectedPoint = FVector(Direction.X, Location.Y, Direction.Z);

		return ProjectedPoint;
	}

	FVector GetProjectedPointOnCylinder(FVector Location, FVector &OutDirection)
	{
		OutDirection = Location.VectorPlaneProject(RotationPivot.RightVector).SafeNormal * Radius;
		FVector ProjectedPoint = FVector(OutDirection.X, Location.Y, OutDirection.Z);

		return ProjectedPoint;		
	}
};
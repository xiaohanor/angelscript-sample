class USkylineMovableSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

class ASkylineCableSling : APerchSpline
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;
	default FauxPhysicsTranslateComponent.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsSpringConstraint FauxPhysicsSpringConstraint;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;
	
	UPROPERTY(DefaultComponent)
	UBoxComponent MioFloorBox;
	default MioFloorBox.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default MioFloorBox.bGenerateOverlapEvents = false;
	default MioFloorBox.CollisionProfileName = n"BlockAllDynamic";
	default MioFloorBox.BoxExtent = FVector(1);

	TArray<USplineMeshComponent> SplineMeshComponents;

	UPROPERTY(EditAnywhere)
	float DesiredMeshLength = 300.0;

	UPROPERTY(EditAnywhere)
	float MeshScale = 1.0;

	int NumOfMeshes;
	float MeshLength;

	TArray<AHazePlayerCharacter> PerchingPlayers;
	TArray<AHazePlayerCharacter> ContactingPlayers;

	UPROPERTY(EditAnywhere)
	float SlingImpulse = 3000.0;
	FVector SlingDirection;

	bool bValidRelease = false;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ZoeForceFeedBack;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect MioForceFeedBack;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleStartedPerching");
		OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandleStoppedPerching");

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleWhipGrab");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleWhipRelease");

		FHazeSplinePoint SplinePoint;
		SplinePoint.bOverrideTangent = true;
		SplinePoint.RelativeRotation = Spline.SplinePoints[0].RelativeRotation;
		SplinePoint.ArriveTangent = FVector::RightVector * 0.2;
		SplinePoint.LeaveTangent = FVector::RightVector * 0.2;
		SplinePoint.RelativeLocation = FauxPhysicsTranslateComponent.RelativeLocation;
		Spline.SplinePoints.Insert(SplinePoint, 1);

		SplineMeshComponents.Reset();
		CreateSplineMeshes();
		UpdateSplineMeshes();
	}

	UFUNCTION()
	private void HandleAffected()
	{
//		PlayerWeightComponent.Players
//		PerchingPlayers.Add(Player);
	}

	UFUNCTION()
	private void HandleUnaffected()
	{
//		PerchingPlayers.Remove(Player);
	}

	UFUNCTION()
	private void HandleWhipGrab(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		SetActorControlSide(Game::Zoe);
		FauxPhysicsTranslateComponent.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		EnablePerchSpline(this);
	}

	UFUNCTION()
	private void HandleWhipRelease(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		SetActorControlSide(Game::Mio);
		TArray<AHazePlayerCharacter> SlingedPlayers = PerchingPlayers;
		for (auto SlingedPlayer : SlingedPlayers)
		{		
			float SlindDot = ActorTransform.TransformVectorNoScale(FauxPhysicsTranslateComponent.RelativeLocation).DotProduct(SlingedPlayer.MovementWorldUp);
			Game::Mio.PlayForceFeedback(MioForceFeedBack, false, true, this, 1.0);
			PrintToScreen("SlindDot: " + SlindDot, 0.0, FLinearColor::Green);

			if (SlindDot < -50.0)
			{
				bValidRelease = true;
				SlingDirection = FauxPhysicsSpringConstraint.AnchorWorldLocation - FauxPhysicsTranslateComponent.WorldLocation;
			}
		}

		Game::Zoe.PlayForceFeedback(ZoeForceFeedBack, false, true, this, 1.0);
	}

	UFUNCTION()
	private void HandleStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
	//	PrintToScreen("StartedPerching", 1.0, FLinearColor::Green);

		PerchingPlayers.Add(Player);
	}

	UFUNCTION()
	private void HandleStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
	//	PrintToScreen("StoppedPerching", 1.0, FLinearColor::Green);

		PerchingPlayers.Remove(Player);

		if (ContactingPlayers.Contains(Player))
			ContactingPlayers.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto PerchingPlayer : PerchingPlayers)
		{
			auto MoveComp = UPlayerMovementComponent::Get(PerchingPlayer);
			if (!ContactingPlayers.Contains(PerchingPlayer) && MoveComp.HasCustomMovementStatus(n"Perching"))
				ContactingPlayers.Add(PerchingPlayer);

			if (ContactingPlayers.Contains(PerchingPlayer) && !MoveComp.HasCustomMovementStatus(n"Perching"))
				ContactingPlayers.Remove(PerchingPlayer);
		}

		for (auto ContactingPlayer : ContactingPlayers)
		{
			FauxPhysics::ApplyFauxForceToActorAt(this, ContactingPlayer.ActorLocation, -ContactingPlayer.MovementWorldUp * 3000.0);
		}

		Spline.SplinePoints[1].RelativeLocation = FauxPhysicsTranslateComponent.RelativeLocation;

		Spline.UpdateSpline();

		UpdateSplineMeshes();

		if (GravityWhipResponseComponent.Grabs.Num() == 0 && FauxPhysicsTranslateComponent.GetVelocity().Size() > 500.0 && PerchingPlayers.Num() == 0)
			DisablePerchSpline(this);
		else
			EnablePerchSpline(this);

		TArray<AHazePlayerCharacter> SlingedPlayers = ContactingPlayers;
		for (auto SlingedPlayer : SlingedPlayers)
		{
			float SlindDot = ActorTransform.TransformVectorNoScale(FauxPhysicsTranslateComponent.RelativeLocation).DotProduct(SlingedPlayer.MovementWorldUp);

		//	PrintToScreen("SlindDot: " + SlindDot, 0.0, FLinearColor::Green);

			if (bValidRelease && SlindDot > 0.0)
			{
				FVector SlingVector = SlingDirection;
			//	FVector SlingVector = FauxPhysicsSpringConstraint.AnchorWorldLocation - FauxPhysicsTranslateComponent.WorldLocation;
				DisablePerchSplineForPlayer(SlingedPlayer, this);
				SlingedPlayer.SetActorVelocity(SlingVector.SafeNormal * Math::Clamp(SlingVector.Size() * 8.0, 2000.0, SlingImpulse));
				bValidRelease = false;

				FHazePointOfInterestFocusTargetInfo FocusTarget;
//				FocusTarget.SetFocusToComponent(GravityWhipTargetComponent);
				FocusTarget.SetFocusToActor(SlingedPlayer);
				FocusTarget.LocalOffset = FVector::UpVector * -500.0;

				FApplyPointOfInterestSettings PoiSetting;
				PoiSetting.Duration = 0.2;
				SlingedPlayer.OtherPlayer.ApplyPointOfInterest(this, FocusTarget, PoiSetting, 1.0, EHazeCameraPriority::VeryHigh);
			}
		}

		// Update a little collision box to be below Mio so she can't fall through
		FTransform SplineTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(Game::Mio.ActorLocation);
		MioFloorBox.WorldTransform = FTransform(
			SplineTransform.Rotation,
			SplineTransform.Location - Game::Mio.MovementWorldUp * 10.0,
			FVector(60.0, 60.0, 10.0),
		);
	}

	void CreateSplineMeshes()
	{
		NumOfMeshes = Math::FloorToInt(Spline.SplineLength / DesiredMeshLength);
		MeshLength = Spline.SplineLength / NumOfMeshes;

		for (int i = 0; i < NumOfMeshes; i++)
		{
			auto SplineMesh = USkylineMovableSplineMeshComponent::Create(this);
			SplineMesh.AttachToComponent(Spline);
			SplineMesh.StaticMesh = Mesh;
			for (int j = 0; j < SplineMesh.NumMaterials; j++)
				SplineMesh.SetMaterial(j, Material);
			SplineMeshComponents.Add(SplineMesh);
		}		
	}

	void UpdateSplineMeshes()
	{
		MeshLength = Math::FloorToInt(Spline.SplineLength / NumOfMeshes);

		for (int i = 0; i < SplineMeshComponents.Num(); i++)
		{
			auto StartPosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength - ((i + 1) * MeshLength));
			auto EndPosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength - (i * MeshLength));

			SplineMeshComponents[i].SetStartAndEnd(			
				StartPosition.RelativeLocation,
				StartPosition.RelativeTangent.GetSafeNormal() * MeshLength,
				EndPosition.RelativeLocation,
				EndPosition.RelativeTangent.GetSafeNormal() * MeshLength,
				true				
			);

			SplineMeshComponents[i].SetStartScale(FVector2D(MeshScale, MeshScale));			
			SplineMeshComponents[i].SetEndScale(FVector2D(MeshScale, MeshScale));			
		}
	}

	void DrawDebug()
	{
		float SegmentLenght = 50.0;

		int Segments = Math::FloorToInt(Spline.SplineLength / SegmentLenght);

		SegmentLenght = Spline.SplineLength / Segments;

		for (int i = 0; i <= Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldLocationAtSplineDistance(i * SegmentLenght);
			LineEnd = Spline.GetWorldLocationAtSplineDistance((i + 1) * SegmentLenght);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Yellow, 5.0, 0.0);
		}
	}
}
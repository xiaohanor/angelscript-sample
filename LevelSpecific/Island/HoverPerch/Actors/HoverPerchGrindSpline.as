struct FHoverPerchGrindConnection
{
	AHoverPerchGrindSpline ConnectingGrind;
	float SplineDistance;
	bool bRequireSteering;
	bool bStartBackwards;
	bool bRequireComeFromBackwards;

	int opCmp(const FHoverPerchGrindConnection& Other) const
	{
		if(SplineDistance > Other.SplineDistance)
			return 1;
		else if(SplineDistance < Other.SplineDistance)
			return -1;
		else
			return 0;
	}
}

class AHoverPerchGrindSpline : APropLine
{
	default bGameplaySpline = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	USceneComponent GrindStart;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UHoverPerchGrindSplineDummyComponent DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Setup")
	float SplineBoundsDistance = 10000.0;

	UPROPERTY(EditAnywhere, Category = "Start")
	bool bUseBoxForStart = false;

	/** How far away the perch is allowed to be to be before being considered "on it"*/
	UPROPERTY(EditAnywhere, Category = "Start", Meta = (EditCondition = !bUseBoxForStart, EditConditionHides))
	float GrindEnterDistance = 50.0;

	UPROPERTY(EditAnywhere, Category = "Start", Meta = (EditCondition = bUseBoxForStart, EditConditionHides))
	FVector StartBoxExtents = FVector(400, 200, 200);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GrindMaxSpeed = 1200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GrindAcceleration = 10.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GrindElevationChange = 500;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bGrindBackwards = false;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDebugDrawElevationChange = false;
#endif

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bRotateCameraWithSpline = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bSwitchDirectionWhenHittingOtherHoverPerch = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bSwitchDirectionWhenHittingOtherHoverPerch", EditConditionHides))
	float PlayerDamageToApplyWhenSwitchingDirectionOnHit = 0;

	/** If true, the grind spline will switch material when someone is grinding. */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bChangeMaterialWhenGrinding = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bChangeMaterialWhenGrinding", EditConditionHides))
	int MaterialIndexToChangeWhenGrinding = 1;
	
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bChangeMaterialWhenGrinding", EditConditionHides))
	UMaterialInterface MioGrindingMaterial;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bChangeMaterialWhenGrinding", EditConditionHides))
	UMaterialInterface ZoeGrindingMaterial;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bChangeMaterialWhenGrinding", EditConditionHides))
	UMaterialInterface BothGrindingMaterial;

	/** Only if they are also grinding */
	UPROPERTY(EditAnywhere, Category = "Respawn")
	bool bBlockOtherPlayerRespawnWhileOnGrind = false;

	UPROPERTY(EditAnywhere, Category = "Respawn", Meta = (EditCondition = bBlockOtherPlayerRespawnWhileOnGrind, EditConditionHides))
	bool bGameOverIfBothDie = true;



	UPROPERTY(EditAnywhere, Category = "Connections")
	bool bConnectsToOtherSplines = false;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = bConnectsToOtherSplines, EditConditionHides))
	bool bStartConnects = false;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	AHoverPerchGrindSpline StartConnectingGrind;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	bool bStartConnectsBothWays = true;
	
	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	bool bStartConnectsBackwards = false;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	bool bStartConnectsFromBackwards = true;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	bool bStartConnectionRequiresSteering = true;

	UPROPERTY(EditAnywhere, Category = "Connections|Start", Meta = (EditCondition = "bConnectsToOtherSplines && bStartConnects", EditConditionHides))
	bool bPlaceStartConnectionOnSpline = false;



	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = bConnectsToOtherSplines, EditConditionHides))
	bool bEndConnects = false;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	AHoverPerchGrindSpline EndConnectingGrind;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	bool bEndConnectsBothWays = true;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	bool bEndConnectsBackwards = false;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	bool bEndConnectsFromBackwards = true;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	bool bEndConnectionRequiresSteering = true;

	UPROPERTY(EditAnywhere, Category = "Connections|End", Meta = (EditCondition = "bConnectsToOtherSplines && bEndConnects", EditConditionHides))
	bool bPlaceEndConnectionOnSpline = false;

	UPROPERTY(BlueprintHidden)
	FVector GrindCenterOffset;

	UPROPERTY(BlueprintHidden)
	FVector GrindBoundsExtent = FVector(1000, 1000, 1000);

	TArray<FHoverPerchGrindConnection> GrindConnections;
	TArray<AHoverPerchActor> GrindingHoverPerches;
	UMaterialInterface OriginalMaterial;
	TArray<UStaticMeshComponent> Meshes;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		GetComponentsByClass(UStaticMeshComponent, Meshes);
		OriginalMaterial = Meshes[0].GetMaterial(MaterialIndexToChangeWhenGrinding);
		Spline = Spline::GetGameplaySpline(this);

		if(bConnectsToOtherSplines)
		{
			auto SplineComp = UHazeSplineComponent::Get(this);
			if(bStartConnects
			&& bStartConnectsBothWays
			&& StartConnectingGrind != nullptr)
			{
				FSplinePosition StartSplinePos = SplineComp.GetSplinePositionAtSplineDistance(0.0);
				auto StartConnectionSplineComp = UHazeSplineComponent::Get(StartConnectingGrind);
				FSplinePosition ClosestSplinePosToStart = StartConnectionSplineComp.GetClosestSplinePositionToWorldLocation(StartSplinePos.WorldLocation);

				FHoverPerchGrindConnection NewConnection;
				NewConnection.ConnectingGrind = this;
				NewConnection.SplineDistance = ClosestSplinePosToStart.CurrentSplineDistance;
				NewConnection.bRequireSteering = bStartConnectionRequiresSteering;
				NewConnection.bStartBackwards = false;
				NewConnection.bRequireComeFromBackwards = bStartConnectsFromBackwards;
				StartConnectingGrind.GrindConnections.Add(NewConnection);
			}
			if(bEndConnects
			&& bEndConnectsBothWays
			&& EndConnectingGrind != nullptr)
			{
				FSplinePosition EndSplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplineComp.SplineLength);
				auto EndConnectionSplineComp = UHazeSplineComponent::Get(EndConnectingGrind);
				FSplinePosition ClosestSplinePosToEnd = EndConnectionSplineComp.GetClosestSplinePositionToWorldLocation(EndSplinePos.WorldLocation);

				FHoverPerchGrindConnection NewConnection;
				NewConnection.ConnectingGrind = this;
				NewConnection.SplineDistance = ClosestSplinePosToEnd.CurrentSplineDistance;
				NewConnection.bRequireSteering = bEndConnectionRequiresSteering;
				NewConnection.bStartBackwards = true;
				NewConnection.bRequireComeFromBackwards = bEndConnectsFromBackwards;
				EndConnectingGrind.GrindConnections.Add(NewConnection);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TListedActors<AHoverPerchActor> HoverPerches;
		for(auto HoverPerch : HoverPerches.Array)
		{
			float DistSqrdToPerch = (ActorLocation + GrindCenterOffset).DistSquared(HoverPerch.BaseLocation);
			if(DistSqrdToPerch <= Math::Square(SplineBoundsDistance))
			{
				if(!HoverPerch.GrindsCloseEnoughToCheck.Contains(this))
					HoverPerch.GrindsCloseEnoughToCheck.Add(this);
			}
			else
			{
				if(HoverPerch.GrindsCloseEnoughToCheck.Contains(this))
					HoverPerch.GrindsCloseEnoughToCheck.RemoveSingleSwap(this);
			}
		}
	}

	void StartGrinding(AHoverPerchActor HoverPerch)
	{
		GrindingHoverPerches.AddUnique(HoverPerch);

		if(bChangeMaterialWhenGrinding)
			UpdateMaterials();
	}

	void StopGrinding(AHoverPerchActor HoverPerch)
	{
		GrindingHoverPerches.RemoveSingleSwap(HoverPerch);

		if(bChangeMaterialWhenGrinding)
			UpdateMaterials();
	}

	void UpdateMaterials()
	{
		UMaterialInterface Material = GetDesiredMaterial();

		for(UStaticMeshComponent Mesh : Meshes)
		{
			Mesh.SetMaterial(MaterialIndexToChangeWhenGrinding, Material);
		}
	}

	UMaterialInterface GetDesiredMaterial()
	{
		if(GrindingHoverPerches.Num() == 0)
			return OriginalMaterial;

		if(GrindingHoverPerches.Num() == 2)
			return BothGrindingMaterial;

		if(GrindingHoverPerches[0].PlayerLocker.IsMio())
			return MioGrindingMaterial;

		return ZoeGrindingMaterial;
	}

	bool IsInsideStartBox(AHoverPerchActor PerchActor) const
	{
		FVector RelativeLocation = GrindStart.WorldTransform.InverseTransformPositionNoScale(PerchActor.BaseLocation);
		FBox StartBox(-StartBoxExtents, StartBoxExtents);
		
		return StartBox.IsInsideOrOn(RelativeLocation);
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void UpdateBounds()
	{
		FVector BoundsCenter;
		FVector BoundsExtent;
		GetActorBounds(false, BoundsCenter, BoundsExtent, true);
		GrindCenterOffset = BoundsCenter - ActorLocation;

		GrindElevationChange = BoundsExtent.Z * 2.0;
		const FVector CenterToStartDir = (BoundsCenter - GrindStart.WorldLocation).GetSafeNormal(); 
		if(CenterToStartDir.DotProduct(FVector::UpVector) < 0)
			GrindElevationChange *= -1;

		SplineBoundsDistance = BoundsExtent.Size() + 2000;
		GrindBoundsExtent = BoundsExtent;
	}

	float GetEndZ() const property
	{
		return ActorLocation.Z + GrindCenterOffset.Z + GrindElevationChange * 0.5;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Connections")
	void PlaceConnectionsOnSpline()
	{
		if(!bConnectsToOtherSplines)
			return;
		
		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(this);
		if(bStartConnects
		&& StartConnectingGrind != nullptr)
		{
			auto& FirstSplinePoint = SplineComp.SplinePoints[0];
			FVector FirstSplinePointWorldLocation = SplineComp.WorldTransform.TransformPosition(FirstSplinePoint.RelativeLocation);
			auto OtherSplineComp = UHazeSplineComponent::Get(StartConnectingGrind); 
			
			auto ClosestSplinePos = OtherSplineComp.GetClosestSplinePositionToWorldLocation(FirstSplinePointWorldLocation);
			FirstSplinePoint.RelativeLocation = SplineComp.WorldTransform.InverseTransformPosition(ClosestSplinePos.WorldLocation);
		}
		if(bEndConnects
		&& EndConnectingGrind != nullptr)
		{
			auto& LastSplinePoint = SplineComp.SplinePoints[SplineComp.SplinePoints.Num()-1];
			FVector LastSplinePointWorldLocation = SplineComp.WorldTransform.TransformPosition(LastSplinePoint.RelativeLocation);
			auto OtherSplineComp = UHazeSplineComponent::Get(EndConnectingGrind); 
			
			auto ClosestSplinePos = OtherSplineComp.GetClosestSplinePositionToWorldLocation(LastSplinePointWorldLocation);
			LastSplinePoint.RelativeLocation = SplineComp.WorldTransform.InverseTransformPosition(ClosestSplinePos.WorldLocation);
		}

		SplineComp.UpdateSpline();
		UpdatePropLine();
	}
#endif
}

#if EDITOR
class UHoverPerchGrindSplineDummyComponent : UActorComponent {}
class UHoverPerchGrindSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHoverPerchGrindSplineDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UHoverPerchGrindSplineDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto GrindSpline = Cast<AHoverPerchGrindSpline>(Component.Owner);
		if(GrindSpline == nullptr)
			return;

		SetRenderForeground(false);

		const FVector GrindCenter = GrindSpline.ActorLocation + GrindSpline.GrindCenterOffset;
		DrawWireSphere(GrindCenter, GrindSpline.SplineBoundsDistance, FLinearColor::Green , 20, 6, false);
		DrawWorldString("Grind Spline Bounds", GrindSpline.ActorLocation + GrindSpline.GrindCenterOffset + FVector::UpVector * GrindSpline.SplineBoundsDistance, FLinearColor::Green, 1);
		
		if(GrindSpline.bDebugDrawElevationChange)
		{
			DrawSolidBox(this, GrindCenter + FVector::UpVector * GrindSpline.GrindElevationChange * 0.5, FQuat::Identity, FVector(GrindSpline.GrindBoundsExtent.X, GrindSpline.GrindBoundsExtent.Y, 1), FLinearColor::LucBlue, 0.75, 10);
			DrawWorldString("End of Grind Elevation", GrindCenter + FVector::UpVector * GrindSpline.GrindElevationChange * 0.5, FLinearColor::LucBlue);
		}

		if(GrindSpline.bUseBoxForStart)
			DrawWireBox(GrindSpline.GrindStart.WorldLocation, GrindSpline.StartBoxExtents, GrindSpline.GrindStart.ComponentQuat, FLinearColor::Green, 20, false);
		else
			DrawWireSphere(GrindSpline.GrindStart.WorldLocation, GrindSpline.GrindEnterDistance, FLinearColor(0.17, 0.63, 0.13), 5, 24);
		DrawWorldString("Grind Start", GrindSpline.GrindStart.WorldLocation, FLinearColor(0.17, 0.63, 0.13));

		if(GrindSpline.bConnectsToOtherSplines)
		{
			auto SplineComp = UHazeSplineComponent::Get(GrindSpline);

			if(GrindSpline.bStartConnects
			&& GrindSpline.StartConnectingGrind != nullptr)
			{
				FSplinePosition StartSplinePos = SplineComp.GetSplinePositionAtSplineDistance(0.0);
				auto StartConnectionSplineComp = UHazeSplineComponent::Get(GrindSpline.StartConnectingGrind);
				FSplinePosition ClosestSplinePosToStart = StartConnectionSplineComp.GetClosestSplinePositionToWorldLocation(StartSplinePos.WorldLocation);
				if(GrindSpline.bStartConnectsBackwards)
					ClosestSplinePosToStart.ReverseFacing();

				DrawWireSphere(ClosestSplinePosToStart.WorldLocation, 10, FLinearColor::White, 5, 12);
				DrawArrow(ClosestSplinePosToStart.WorldLocation, ClosestSplinePosToStart.WorldLocation + ClosestSplinePosToStart.WorldForwardVector * 100, FLinearColor::White, 30, 10);
				DrawWorldString("Connecting Start Grind Location", ClosestSplinePosToStart.WorldLocation, FLinearColor::White);

				if(GrindSpline.bStartConnectsBothWays)
				{
					if(GrindSpline.bStartConnectsBackwards)
						ClosestSplinePosToStart.ReverseFacing();

					FVector ConnectingStartGrindLocation = ClosestSplinePosToStart.WorldLocation;
					if(!GrindSpline.bStartConnectsFromBackwards)
						ClosestSplinePosToStart.ReverseFacing();
					ClosestSplinePosToStart.Move(200);
					DrawArrow(ClosestSplinePosToStart.WorldLocation, ConnectingStartGrindLocation, FLinearColor::LucBlue, 30, 10);
				}
			}
			if(GrindSpline.bEndConnects
			&& GrindSpline.EndConnectingGrind != nullptr)
			{
				FSplinePosition EndSplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplineComp.SplineLength);
				auto EndConnectionSplineComp = UHazeSplineComponent::Get(GrindSpline.EndConnectingGrind);
				FSplinePosition ClosestSplinePosToEnd = EndConnectionSplineComp.GetClosestSplinePositionToWorldLocation(EndSplinePos.WorldLocation);
				if(GrindSpline.bEndConnectsBackwards)
					ClosestSplinePosToEnd.ReverseFacing();

				DrawWireSphere(ClosestSplinePosToEnd.WorldLocation, 10, FLinearColor::Black, 5, 12);
				DrawArrow(ClosestSplinePosToEnd.WorldLocation, ClosestSplinePosToEnd.WorldLocation + ClosestSplinePosToEnd.WorldForwardVector * 100, FLinearColor::Black, 30, 10);
				DrawWorldString("Connecting End Grind Location", ClosestSplinePosToEnd.WorldLocation, FLinearColor::Black);

				if(GrindSpline.bEndConnectsBothWays)
				{
					if(GrindSpline.bEndConnectsBackwards)
						ClosestSplinePosToEnd.ReverseFacing();

					FVector ConnectingEndGrindLocation = ClosestSplinePosToEnd.WorldLocation;
					if(!GrindSpline.bEndConnectsFromBackwards)
						ClosestSplinePosToEnd.ReverseFacing();
					ClosestSplinePosToEnd.Move(200);
					DrawArrow(ClosestSplinePosToEnd.WorldLocation, ConnectingEndGrindLocation, FLinearColor::LucBlue, 30, 10);
				}
			}
		}
	}
}
#endif
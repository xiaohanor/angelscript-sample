UCLASS(Abstract)
class ARemoteHackableMachineryCell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CellRoot;

	UPROPERTY(EditAnywhere)
	UStaticMesh CellMeshAsset;

	UPROPERTY(EditInstanceOnly)
	int CopiesX = 1;
	UPROPERTY(EditInstanceOnly)
	int CopiesY = 1;
	UPROPERTY(EditInstanceOnly)
	int CopiesZ = 1;

	float CellOffset = 600.0;
	float CellScale = 1.5;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector EndLocation = FVector::ZeroVector;
	

#if EDITOR
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewAlpha = 0.0;
#endif

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve HackCurve;

	bool bAllowMovement = true;

	UPROPERTY(BlueprintReadOnly)
	float MovementSpeed = 0.0;

	float PreviousAlpha = 0.0;
	float CurrentAlpha = 0.0;

	bool bHitStartPoint = true;
	bool bHitEndPoint = false;
	bool bMovingOutwards = false;
	bool bMovingInwards = false;
	bool bMoving = false;

	float CurrentOffset;
	float PreviousOffset;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	ARemoteHackableMachineryControlPanel ControlPanel;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (int X = 0; X < CopiesX; ++X)
		{
			for (int Y = 0; Y < CopiesY; ++Y)
			{
				for (int Z = 0; Z < CopiesZ; ++Z)
				{
					UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this, FName(f"Cell_{X}_{Y}_{Z}"));
					MeshComp.SetStaticMesh(CellMeshAsset);
					MeshComp.AttachToComponent(CellRoot, NAME_None, EAttachmentRule::KeepWorld);
					MeshComp.SetRelativeLocation(FVector(X * -CellOffset, Y * CellOffset, Z * CellOffset));
					MeshComp.RemoveTag(ComponentTags::LedgeClimbable);
				}
			}
		}

#if EDITOR
		UpdatePreviewAlphaAndLoc(PreviewAlpha);
#endif
	}

#if EDITOR
	void UpdatePreviewAlphaAndLoc(float NewAlpha)
	{
		PreviewAlpha = NewAlpha;
		float Alpha = PreviewAlpha;

		if (HackCurve.NumKeys > 0)
			Alpha = HackCurve.GetFloatValue(PreviewAlpha);
		
		FVector Loc = Math::Lerp(FVector::ZeroVector, EndLocation, Alpha);
		CellRoot.SetRelativeLocation(Loc);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Drone::SwarmDronePlayer);

		ControlPanel = TListedActors<ARemoteHackableMachineryControlPanel>().Single;

		CurrentOffset = CellRoot.RelativeLocation.X;
		PreviousOffset = CellRoot.RelativeLocation.X;

		UpdateLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bAllowMovement)
			return;

		UpdateLocation();
	}

	void UpdateLocation()
	{
		PreviousAlpha = CurrentAlpha;
		PreviousOffset = CurrentOffset;

		if (HackCurve.NumKeys > 0)
			CurrentAlpha = HackCurve.GetFloatValue(ControlPanel.SyncedAlphaComp.Value);
		else
			CurrentAlpha = ControlPanel.SyncedAlphaComp.Value;
		
		FVector Loc = Math::Lerp(FVector::ZeroVector, EndLocation, CurrentAlpha);
		CellRoot.SetRelativeLocation(Loc);

		CurrentOffset = CellRoot.RelativeLocation.X;
		
		float Dif = CurrentOffset - PreviousOffset;
		if (Dif == 0)
			StopMoving();
		else if (Dif > 0)
			StartMovingOutwards();
		else if (Dif < 0)
			StartMovingInwards();

		MovementSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, 12.0), FVector2D(0.0, 1.0), Math::Abs(Dif));

		if (Math::IsNearlyEqual(CurrentAlpha, 1.0, 0.005) && bMovingOutwards)
		{
			if (!bHitEndPoint)
			{
				bHitEndPoint = true;
				URemoteHackableMachineryEffectEventHandler::Trigger_FullyExtended(this);

				if (bDebug)
					Print("fully extended!", 2.0, FLinearColor::DPink);
			}
		}
		else if (Math::IsNearlyEqual(CurrentAlpha, 0.0, 0.005) && bMovingInwards)
		{
			if (!bHitStartPoint)
			{
				bHitStartPoint = true;
				URemoteHackableMachineryEffectEventHandler::Trigger_FullyRetracted(this);

				if (bDebug)
					Print("fully retracted!", 2.0, FLinearColor::DPink);
			}
		}
		else
		{
			bHitEndPoint = false;
		}
	}

	void StartMovingOutwards()
	{
		if (bMovingOutwards)
			return;

		if (bHitEndPoint)
			return;

		bHitStartPoint = false;
		bMovingOutwards = true;
		bMovingInwards = false;
		bMoving = true;

		if (bDebug)
			Print("move out!", 2.0, FLinearColor::LucBlue);

		URemoteHackableMachineryEffectEventHandler::Trigger_StartMovingOutwards(this);
	}

	void StartMovingInwards()
	{
		if (bMovingInwards)
			return;

		if (bHitStartPoint)
			return;

		bHitEndPoint = false;
		bMovingInwards = true;
		bMovingOutwards = false;
		bMoving = true;

		if (bDebug)
			Print("move in!", 2.0, FLinearColor::Green);

		URemoteHackableMachineryEffectEventHandler::Trigger_StartMovingInwards(this);
	}

	void StopMoving()
	{
		if (!bMoving)
			return;

		bMoving = false;
		bMovingOutwards = false;
		bMovingInwards = false;

		if (bDebug)
			Print("stop it!", 2.0, FLinearColor::Red);

		URemoteHackableMachineryEffectEventHandler::Trigger_StopMoving(this);
	}

	UFUNCTION()
	void SetAllowMovement(bool bNewAllowMovement)
	{
		bAllowMovement = bNewAllowMovement;
	}

	UFUNCTION()
	void Break()
	{
		URemoteHackableMachineryEffectEventHandler::Trigger_Break(this);
	}
}
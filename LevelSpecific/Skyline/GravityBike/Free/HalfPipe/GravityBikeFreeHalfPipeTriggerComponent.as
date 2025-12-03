event void FGravityBikeFreeHalfPipeJumpStarted(AGravityBikeFree GravityBike);
event void FGravityBikeFreeHalfPipeJumpEnded(AGravityBikeFree GravityBike, bool bLanded);

struct FGravityBikeFreeHalfPipeTriggerPlayerData
{
	AGravityBikeFree GravityBike;
	bool bIsInsideTrigger = false;
	bool bIsBoosted = false;
}

class UGravityBikeFreeHalfPipeTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	default Mobility = EComponentMobility::Movable;

	default Shape = FHazeShapeSettings::MakeBox(FVector(1000, 1000, 1000));
	default ShapeColor = FLinearColor(1.0, 0.0, 0.8, 1.0);

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Meta = (UseComponentPicker, AllowAnyActor, AllowedClasses = "/Script/Angelscript.GravityBikeFreeHalfPipeTriggerComponent"))
	FComponentReference JumpToTriggerRef;

	UPROPERTY(EditInstanceOnly)
	float PreviewSpeed = GravityBikeFree::HalfPipe::MinimumVerticalSpeed * 2;
	
	TInstigated<bool> IsDisabled;
	default IsDisabled.DefaultValue = false;

	TPerPlayer<FGravityBikeFreeHalfPipeTriggerPlayerData> PlayerDatas;

	UPROPERTY()
	FGravityBikeFreeHalfPipeJumpStarted OnHalfPipeJumpStarted;
	
	UPROPERTY()
	FGravityBikeFreeHalfPipeJumpEnded OnHalfPipeJumpEnded;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData : PlayerDatas)
		{
			if(!PlayerData.bIsInsideTrigger)
				continue;

			if(ShouldBoost(PlayerData))
				ApplyBoost(PlayerData);
			else
				ClearBoost(PlayerData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		auto GravityBike = GravityBikeFree::GetGravityBike(Player);
        if (GravityBike == nullptr)
            return;

		FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData = PlayerDatas[Player];
		PlayerData.GravityBike = GravityBike;
		PlayerData.bIsInsideTrigger = true;

		auto HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);
		if(HalfPipeComp == nullptr)
			return;

		if(HalfPipeComp.JumpData.IsJumpingToTrigger(this))
		{
			HalfPipeComp.JumpData.FinishJump();
		}

		if(ShouldBoost(PlayerData))
			ApplyBoost(PlayerData);
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		auto GravityBike = GravityBikeFree::GetGravityBike(Player);
        if (GravityBike == nullptr)
            return;

		FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData = PlayerDatas[Player];
		PlayerData.bIsInsideTrigger = false;
		ClearBoost(PlayerData);

		auto HalfPipeComp = UGravityBikeFreeHalfPipeComponent::Get(GravityBike);
		if(HalfPipeComp == nullptr)
			return;

		FGravityBikeFreeHalfPipeJumpData JumpData = FGravityBikeFreeHalfPipeJumpData::MakeJumpData(
			HalfPipeComp,
			this,
			GravityBike.ActorLocation,
			GravityBike.ActorVelocity,
			GetJumpToTrigger()
		);

		HalfPipeComp.JumpData = JumpData;
	}

	UGravityBikeFreeHalfPipeTriggerComponent GetJumpToTrigger() const
	{
		if(JumpToTriggerRef.OtherActor.IsValid())
		{
			return Cast<UGravityBikeFreeHalfPipeTriggerComponent>(JumpToTriggerRef.GetComponent(JumpToTriggerRef.OtherActor));
		}
		else
		{
			return Cast<UGravityBikeFreeHalfPipeTriggerComponent>(JumpToTriggerRef.GetComponent(Owner));
		}
	}

	bool ShouldBoost(FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData) const
	{
		// if(PlayerData.GravityBike.ActorVelocity.DotProduct(ForwardVector) < 0)
		// 	return false;

		return true;
	}

	private void ApplyBoost(FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData)
	{
		if(PlayerData.bIsBoosted)
			return;

		PlayerData.bIsBoosted = true;

		auto BoostComp = UGravityBikeFreeBoostComponent::Get(PlayerData.GravityBike);
		if(BoostComp != nullptr)
			BoostComp.ApplyForceBoost(true, this);
	}
	
	private void ClearBoost(FGravityBikeFreeHalfPipeTriggerPlayerData& PlayerData)
	{
		if(!PlayerData.bIsBoosted)
			return;

		PlayerData.bIsBoosted = false;

		auto BoostComp = UGravityBikeFreeBoostComponent::Get(PlayerData.GravityBike);
		if(BoostComp != nullptr)
			BoostComp.ClearForceBoost(this);
	}

	FVector GetRelativeLeftEdgeLocation() const property
	{
		const FVector BoxExtent = Shape.BoxExtents;
		return FVector(BoxExtent.X, -BoxExtent.Y, BoxExtent.Z);
	}

	FVector GetRelativeRightEdgeLocation() const property
	{
		const FVector BoxExtent = Shape.BoxExtents;
		return FVector(BoxExtent.X, BoxExtent.Y, BoxExtent.Z);
	}

	FVector GetRelativeCenterEdgeLocation() const property
	{
		const FVector BoxExtent = Shape.BoxExtents;
		return FVector(BoxExtent.X, 0, BoxExtent.Z);
	}

	FVector GetWorldLeftEdgeLocation() const property
	{
		return WorldTransform.TransformPosition(RelativeLeftEdgeLocation);
	}

	FVector GetWorldRightEdgeLocation() const property
	{
		return WorldTransform.TransformPosition(RelativeRightEdgeLocation);
	}

	FVector GetWorldEdgeCenterLocation() const property
	{
		return WorldTransform.TransformPosition(RelativeCenterEdgeLocation);
	}

	FVector GetEdgeNormal() const property
	{
		FVector EdgeDelta = WorldRightEdgeLocation - WorldLeftEdgeLocation;
		return UpVector.CrossProduct(EdgeDelta).GetSafeNormal();
	}

	FVector GetWorldExtents() const
	{
		return Shape.BoxExtents * WorldScale;
	}

	bool IsLocationBetweenEdges(FVector Location) const
	{
		Debug::DrawDebugPlane(WorldLeftEdgeLocation, -RightVector, 200, 200, FLinearColor::Red, 30);
		Debug::DrawDebugPlane(WorldRightEdgeLocation, RightVector, 200, 200, FLinearColor::Yellow, 30);

		FVector RelativeEdgeLocation = WorldTransform.InverseTransformPosition(Location);
		if(RelativeEdgeLocation.Y > RelativeRightEdgeLocation.Y)
		{
			Debug::DrawDebugLine(WorldEdgeCenterLocation, Location,  FLinearColor::Red, 30, 30);
			return false;
		}

		if(RelativeEdgeLocation.Y < RelativeLeftEdgeLocation.Y)
		{
			Debug::DrawDebugLine(WorldEdgeCenterLocation, Location,  FLinearColor::Red, 30, 30);
			return false;
		}

		Debug::DrawDebugLine(WorldEdgeCenterLocation, Location,  FLinearColor::Green, 30, 30);
		return true;
	}
}

class UGravityBikeFreeHalfPipeTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeFreeHalfPipeTriggerComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		auto Trigger = Cast<UGravityBikeFreeHalfPipeTriggerComponent>(Component);
		if(Trigger == nullptr)
			return;

		DrawArrow(Trigger.WorldEdgeCenterLocation, Trigger.WorldEdgeCenterLocation + Trigger.UpVector * 1000, FLinearColor::Blue, 50, 10);
		DrawArrow(Trigger.WorldEdgeCenterLocation, Trigger.WorldEdgeCenterLocation + Trigger.EdgeNormal * 1000, FLinearColor::Red, 50, 10);
		DrawLine(Trigger.WorldLeftEdgeLocation, Trigger.WorldRightEdgeLocation, FLinearColor::Red, 10);
		DrawWireBox(Trigger.WorldLocation, Trigger.GetWorldExtents(), Trigger.ComponentQuat, FLinearColor::Red, 10);

		UGravityBikeFreeHalfPipeTriggerComponent JumpToTrigger = Trigger.GetJumpToTrigger();

		if(JumpToTrigger != nullptr)
		{
			FVector StartLocation = Trigger.WorldEdgeCenterLocation;
			FVector StartTangent = Trigger.UpVector * Trigger.PreviewSpeed * GravityBikeFree::HalfPipe::TangentMultiplier;

			FVector EndLocation = JumpToTrigger.WorldEdgeCenterLocation;
			FVector EndTangent = -JumpToTrigger.UpVector * Trigger.PreviewSpeed * GravityBikeFree::HalfPipe::TangentMultiplier;

			const int Resolution = 20;
			for(int i = 0; i < Resolution; i++)
			{
				float StartAlpha = i / float(Resolution);
				float EndAlpha = (i + 1.0) / float(Resolution);

				FVector Start = Math::CubicInterp(StartLocation, StartTangent, EndLocation, EndTangent, StartAlpha);
				FVector End = Math::CubicInterp(StartLocation, StartTangent, EndLocation, EndTangent, EndAlpha);
				DrawArrow(Start, End, FLinearColor::Green, 20, 20);
			}
		}
	}
}
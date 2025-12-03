enum EPinballRailVelocityMode
{
	KeepVelocity,
	ZeroVelocity,
	SetSpeed,
};

enum EPinballRailHeadOrTail
{
	Head,
	Tail,
	None,
};

enum EPinballRailEnterOrExit
{
	Enter,
	Exit,
	None,
};

struct FPinballTargetSpeedData
{
	UPROPERTY(EditInstanceOnly)
	float DistanceAlongSpline = 0;

	UPROPERTY(EditInstanceOnly)
	float TargetSpeed = 1500;

	UPROPERTY(EditInstanceOnly)
	float TargetSpeedAcceleration = 500;

	UPROPERTY(EditInstanceOnly)
	float TargetSpeedDeceleration = 500;
};

enum EPinballRailCopyDirection
{
	FromPropLineToRail,
	FromRailToPropLine,
};

event void FPinballRailOnBallEntered(UPinballBallComponent BallComp, EPinballRailHeadOrTail EnterSide);
event void FPinballRailOnBallExited(UPinballBallComponent BallComp, EPinballRailHeadOrTail ExitSide);

UCLASS(Abstract, HideCategories = "Rendering Debug Actor TextureStreaming LevelInstance Collision Cooking")
class APinballRail : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UPinballTriggerComponent HeadTrigger;

	UPROPERTY(DefaultComponent)
	UPinballTriggerComponent TailTrigger;

	UPROPERTY(DefaultComponent)
	UPinballRailSyncPoint HeadSyncPoint;
	default HeadSyncPoint.SyncPointSide = EPinballRailHeadOrTail::Head;

	UPROPERTY(DefaultComponent)
	UPinballRailSyncPoint TailSyncPoint;
	default TailSyncPoint.SyncPointSide = EPinballRailHeadOrTail::Tail;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UPinballRailEditorComponent EditorComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(BlueprintReadOnly)
	FPinballRailOnBallEntered OnBallEntered;

	UPROPERTY(BlueprintReadOnly)
	FPinballRailOnBallExited OnBallExited;

	/**
	 * Do we allow entering the spline through the Tail?
	 */
	UPROPERTY(EditInstanceOnly, Category = "Rail")
	bool bTwoSided = true;

	UPROPERTY(EditInstanceOnly, Category = "Rail")
	bool bActiveFromStart = true;

	UPROPERTY(EditInstanceOnly, Category = "Rail")
	bool bApplyGravity = true;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Head")
	bool bSnapHeadTriggerOnMove = true;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Head")
	EPinballRailVelocityMode VelocityOnExitHead = EPinballRailVelocityMode::KeepVelocity;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Head", Meta = (EditCondition = "VelocityOnExitHead == EPinballRailVelocityMode::SetSpeed", EditConditionHides))
	float SpeedOnExitHead = 1000;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Tail")
	bool bSnapTailTriggerOnMove = true;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Tail")
	EPinballRailVelocityMode VelocityOnExitTail = EPinballRailVelocityMode::KeepVelocity;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Tail", Meta = (EditCondition = "VelocityOnExitTail == EPinballRailVelocityMode::SetSpeed", EditConditionHides))
	float SpeedOnExitTail = 1000;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Target Speed")
	bool bInterpTowardsTargetSpeed = false;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Target Speed", Meta = (EditCondition = "bInterpTowardsTargetSpeed", EditConditionHides))
	private float TargetSpeed = 1500;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Target Speed", Meta = (EditCondition = "bInterpTowardsTargetSpeed", EditConditionHides))
	private float TargetSpeedAcceleration = 500;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Target Speed", Meta = (EditCondition = "bInterpTowardsTargetSpeed", EditConditionHides))
	private float TargetSpeedDeceleration = 500;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Target Speed", Meta = (EditCondition = "bInterpTowardsTargetSpeed", EditConditionHides))
	TArray<FPinballTargetSpeedData> TargetSpeedAlongSpline;

	UPROPERTY(EditInstanceOnly, Category = "Rail PropLine")
	APropLine CopyPropLine;

	UPROPERTY(EditInstanceOnly, Category = "Rail PropLine", Meta = (EditCondition = "CopyPropLine != nullptr", EditConditionHides))
	EPinballRailCopyDirection CopyDirection = EPinballRailCopyDirection::FromRailToPropLine;

	UPROPERTY(EditInstanceOnly, Category = "Rail PropLine", Meta = (EditCondition = "CopyPropLine != nullptr", EditConditionHides))
	bool bAutoCopyPropLine;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Rail|Visualization")
	float VisualizeDuration = 5;

	UPROPERTY(EditInstanceOnly, Category = "Rail|Visualization")
	EPinballRailHeadOrTail VisualizeEnterSide = EPinballRailHeadOrTail::Head;
#endif

	private TArray<UPinballBallComponent> CurrentBallsInRail;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		InitializeInEditor();
	}

	private void InitializeInEditor()
	{
		if(Spline.SplinePoints.Num() < 2)
			return;

		if(bSnapHeadTriggerOnMove)
			SnapHeadTriggerToStartOfSpline();

		if(bSnapTailTriggerOnMove)
			SnapTailTriggerToEndOfSpline();

		HeadSyncPoint.SetWorldTransform(GetHeadTransform());
		HeadSyncPoint.UpdateVisibility(bTwoSided);

		TailSyncPoint.SetWorldTransform(GetTailTransform());
		TailSyncPoint.UpdateVisibility(bTwoSided);

		if(bAutoCopyPropLine)
		{
			switch(CopyDirection)
			{
				case EPinballRailCopyDirection::FromPropLineToRail:
					CopyPropLineToRail();
					break;

				case EPinballRailCopyDirection::FromRailToPropLine:
					CopyRailToPropLine();
					break;
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		InitializeInEditor();
#endif

		SetActorControlSide(Pinball::GetBallPlayer());

		HeadTrigger.OnBallPass.AddUFunction(this, n"OnBallPassTrigger");
		TailTrigger.OnBallPass.AddUFunction(this, n"OnBallPassTrigger");
	}

	UFUNCTION()
	private void OnBallPassTrigger(UPinballTriggerComponent TriggerComp, UPinballBallComponent BallComp, bool bForward)
	{
		EPinballRailHeadOrTail HeadOrTail;
		EPinballRailEnterOrExit EnterOrExit = QueryBallPassIsHeadOrTail(TriggerComp, bForward, HeadOrTail);
		if(EnterOrExit != EPinballRailEnterOrExit::Enter)
		{
			// We don't handle Exiting the rail triggers, because this is handled in the RailMovement capability
			return;
		}
		
		auto BallRailComp = UPinballBallRailComponent::Get(BallComp.Owner);
		if(BallRailComp == nullptr)
			return;

		const EPinballRailHeadOrTail EnterSide = TriggerComp == HeadTrigger ? EPinballRailHeadOrTail::Head : EPinballRailHeadOrTail::Tail;

		BallRailComp.EnterRail(this, EnterSide);
	}

	/**
	 * Determine if the passed trigger was an enter or an exit
	 */
	EPinballRailEnterOrExit QueryBallPassIsHeadOrTail(UPinballTriggerComponent TriggerComp, bool bForward, EPinballRailHeadOrTail&out OutHeadOrTail) const
	{
		OutHeadOrTail = TriggerComp == HeadTrigger ? EPinballRailHeadOrTail::Head : EPinballRailHeadOrTail::Tail;
		
		if(TriggerComp == HeadTrigger && bActiveFromStart)
		{
			if(bForward)
			{
				return EPinballRailEnterOrExit::Enter;
			}
			else
				return EPinballRailEnterOrExit::Exit;
		}
		else if(TriggerComp == TailTrigger)
		{
			if(bForward)
			{
				return EPinballRailEnterOrExit::Exit;
			}
			else
			{
				// Only enter through the exit if we are Two Sided
				if(bTwoSided && bActiveFromStart)
					return EPinballRailEnterOrExit::Enter;
			}
		}

		return EPinballRailEnterOrExit::None;
	}

	void OnBallEnter(UPinballBallComponent BallComp, EPinballRailHeadOrTail EnterSide)
	{
		if(!HasControl())
			return;

		check(!CurrentBallsInRail.Contains(BallComp));
		NetOnBallEnter(BallComp, EnterSide);
	}

	UFUNCTION(NetFunction)
	private void NetOnBallEnter(UPinballBallComponent BallComp, EPinballRailHeadOrTail EnterSide)
	{
		CurrentBallsInRail.Add(BallComp);

		OnBallEntered.Broadcast(BallComp, EnterSide);

		FPinballRailOnBallEnterEventData RailEventData;
		RailEventData.BallComp = BallComp;
		RailEventData.Side = EnterSide;

		UPinballRailEventHandler::Trigger_OnBallEnter(this, RailEventData);
	}

	void OnBallExit(UPinballBallComponent BallComp, EPinballRailHeadOrTail ExitSide)
	{
		if(!HasControl())
			return;
		
		check(CurrentBallsInRail.Contains(BallComp));
		NetOnBallExit(BallComp, ExitSide);
	}

	UFUNCTION(NetFunction)
	private void NetOnBallExit(UPinballBallComponent BallComp, EPinballRailHeadOrTail ExitSide)
	{
		CurrentBallsInRail.RemoveSingleSwap(BallComp);

		OnBallExited.Broadcast(BallComp, ExitSide);

		FPinballRailOnBallExitEventData RailEventData;
		RailEventData.BallComp = BallComp;
		RailEventData.Side = ExitSide;
		UPinballRailEventHandler::Trigger_OnBallExit(this, RailEventData);
	}

	UFUNCTION(BlueprintEvent)
	void LaunchBall(){}

	UFUNCTION(BlueprintCallable)
	void OnActivated()
	{
		bActiveFromStart = true;
	}

	UFUNCTION(BlueprintCallable)
	void OnDeactivated()		
	{
		bActiveFromStart = false;
	}

	FTransform GetHeadTransform() const
	{
		FTransform Transform = Spline.GetWorldTransformAtSplineDistance(0);
		Transform.Rotation = FQuat::MakeFromZX(Transform.Rotation.ForwardVector, -FVector::RightVector);
		Transform.Scale3D = FVector::OneVector;
		return Transform;
	}

	FTransform GetTailTransform() const
	{
		FTransform Transform = Spline.GetWorldTransformAtSplineFraction(1);
		Transform.Rotation = FQuat::MakeFromZX(Transform.Rotation.ForwardVector, -FVector::RightVector);
		Transform.Scale3D = FVector::OneVector;
		return Transform;
	}

	UFUNCTION(CallInEditor, Category = "Rail")
	private void ConstrainAllPointsToPlane()
	{
		Spline.Modify();

		for(int i = 0; i < Spline.SplinePoints.Num(); i++)
			ConstrainPointToPlane(i);

		Spline.UpdateSpline();
		Spline.MarkRenderStateDirty();
	}

	UFUNCTION(CallInEditor, Category = "Rail")
	private void ConstrainHeadAndTailToPlane()
	{
		Spline.Modify();

		if(Spline.SplinePoints.Num() < 2)
			return;

		ConstrainPointToPlane(0);
		ConstrainPointToPlane(Spline.SplinePoints.Num() - 1);

		Spline.UpdateSpline();
		Spline.MarkRenderStateDirty();
	}

	private void ConstrainPointToPlane(int Index)
	{
		FVector WorldPosition = Spline.WorldTransform.TransformPositionNoScale(Spline.SplinePoints[Index].RelativeLocation);
		WorldPosition.X = 0;
		Spline.SplinePoints[Index].RelativeLocation = Spline.WorldTransform.InverseTransformPositionNoScale(WorldPosition);
	}

	float GetEnterSpeed(FVector InitialVelocity, EPinballRailHeadOrTail EnterSide) const
	{
		if(ShouldSyncWhenEntering(EnterSide))
		{
			const UPinballRailSyncPoint SyncPoint = GetSyncPoint(EnterSide);
			return SyncPoint.GetEnterRailSpeed();
		}
		else
		{
			float Speed = InitialVelocity.Size();
			if(EnterSide == EPinballRailHeadOrTail::Tail)
				Speed *= -1;

			return Speed;
		}
	}

	FVector GetExitLocation(EPinballRailHeadOrTail ExitSide) const
	{
		switch(ExitSide)
		{
			case EPinballRailHeadOrTail::Head:
				return GetHeadTransform().Location;
			case EPinballRailHeadOrTail::Tail:
				return GetTailTransform().Location;
			default:
				return GetHeadTransform().Location;
		}
	}

	FVector GetExitDirection(EPinballRailHeadOrTail ExitSide) const
	{
		if(ExitSide == EPinballRailHeadOrTail::Head)
			return -GetHeadTransform().Rotation.UpVector;
		else
			return GetTailTransform().Rotation.UpVector;
	}

	FVector GetExitVelocity(float RailSpeed, EPinballRailHeadOrTail ExitSide) const
	{
		EPinballRailVelocityMode ExitVelocityMode = EPinballRailVelocityMode::ZeroVelocity;

		if(ExitSide == EPinballRailHeadOrTail::Head)
			ExitVelocityMode = VelocityOnExitHead;
		else
			ExitVelocityMode = VelocityOnExitTail;

		FVector ExitDirection = GetExitDirection(ExitSide);

		switch(ExitVelocityMode)
		{
			case EPinballRailVelocityMode::KeepVelocity:
			{
				devCheck(!ShouldSyncWhenExiting(ExitSide), f"Rail sync point {GetSyncPoint(ExitSide)} on {this} has KeepVelocity when using a sync point. This makes no sense! Use SetVelocity instead.");
				return ExitDirection * Math::Abs(RailSpeed);
			}

			case EPinballRailVelocityMode::ZeroVelocity:
			{
				return FVector::ZeroVector;
			}

			case EPinballRailVelocityMode::SetSpeed:
			{
				float ExitSpeed = 0;
				if(ExitSide == EPinballRailHeadOrTail::Head)
					ExitSpeed = SpeedOnExitHead;
				else
					ExitSpeed = SpeedOnExitTail;

				return ExitDirection * ExitSpeed;
			}
		}
	}

	FPinballTargetSpeedData GetTargetSpeedData(float DistanceAlongSpline, EPinballRailHeadOrTail EnterSide) const
	{
		FPinballTargetSpeedData TargetSpeedData = GetTargetSpeedDataInternal(DistanceAlongSpline);
		if(EnterSide == EPinballRailHeadOrTail::Tail)
			TargetSpeedData.TargetSpeed *= -1;

		return TargetSpeedData;
	}

	private FPinballTargetSpeedData GetTargetSpeedDataInternal(float DistanceAlongSpline) const
	{
		devCheck(bInterpTowardsTargetSpeed);

		FPinballTargetSpeedData DefaultTargetSpeedData;
		DefaultTargetSpeedData.TargetSpeed = TargetSpeed;
		DefaultTargetSpeedData.TargetSpeedAcceleration = TargetSpeedAcceleration;
		DefaultTargetSpeedData.TargetSpeedDeceleration = TargetSpeedDeceleration;

		if(TargetSpeedAlongSpline.Num() == 0)
			return DefaultTargetSpeedData;

		if(TargetSpeedAlongSpline.Num() == 1)
			return TargetSpeedAlongSpline[0];

		if(DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < TargetSpeedAlongSpline[0].DistanceAlongSpline)
			return TargetSpeedAlongSpline[0];

		if(DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > TargetSpeedAlongSpline.Last().DistanceAlongSpline)
			return TargetSpeedAlongSpline.Last();


		// FB TODO: Faster search
		for(int i = 1; i < TargetSpeedAlongSpline.Num(); i++)
		{
			const FPinballTargetSpeedData& PreviousTargetSpeedData = TargetSpeedAlongSpline[i - 1];
			if(PreviousTargetSpeedData.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			const FPinballTargetSpeedData& NextTargetSpeedData = TargetSpeedAlongSpline[i];
			if(NextTargetSpeedData.DistanceAlongSpline < DistanceAlongSpline)
				continue;
			
			const float Alpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousTargetSpeedData.DistanceAlongSpline, NextTargetSpeedData.DistanceAlongSpline);
			
			FPinballTargetSpeedData TargetSpeedData;
			TargetSpeedData.TargetSpeed = Math::Lerp(PreviousTargetSpeedData.TargetSpeed, NextTargetSpeedData.TargetSpeed, Alpha);
			TargetSpeedData.TargetSpeedAcceleration = Math::Lerp(PreviousTargetSpeedData.TargetSpeedAcceleration, NextTargetSpeedData.TargetSpeedAcceleration, Alpha);
			TargetSpeedData.TargetSpeedDeceleration = Math::Lerp(PreviousTargetSpeedData.TargetSpeedDeceleration, NextTargetSpeedData.TargetSpeedDeceleration, Alpha);
			
			return TargetSpeedData;
		}

		devCheck(false);
		return DefaultTargetSpeedData;
	}

	bool ShouldSyncWhenEntering(EPinballRailHeadOrTail EnterSide) const
	{
		if(EnterSide == EPinballRailHeadOrTail::None)
			return false;

		return GetSyncPoint(EnterSide).ShouldSync(EPinballRailEnterOrExit::Enter);
	}

	bool ShouldSyncWhenExiting(EPinballRailHeadOrTail ExitSide) const
	{
		if(ExitSide == EPinballRailHeadOrTail::None)
			return false;

		return GetSyncPoint(ExitSide).ShouldSync(EPinballRailEnterOrExit::Exit);
	}

	UPinballRailSyncPoint GetSyncPoint(EPinballRailHeadOrTail Side) const
	{
		switch(Side)
		{
			case EPinballRailHeadOrTail::Head:
				return HeadSyncPoint;

			case EPinballRailHeadOrTail::Tail:
				return TailSyncPoint;

			case EPinballRailHeadOrTail::None:
				return nullptr;
		}
	}

	FVector GetSyncPointLocation(EPinballRailHeadOrTail Side) const
	{
		return GetSyncPoint(Side).WorldLocation;
	}

	FVector GetSyncPointDirection(EPinballRailHeadOrTail HeadOrTail, EPinballRailEnterOrExit EnterOrExit) const
	{
		const UPinballRailSyncPoint SyncPoint = GetSyncPoint(HeadOrTail);
		return SyncPoint.GetLaunchDirection(EnterOrExit);
	}

	UFUNCTION(BlueprintPure)
	TArray<UPinballBallComponent> GetBallsInRail() const
	{
		return CurrentBallsInRail;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Rail")
	private void SnapHeadTriggerToStartOfSpline()
	{
		HeadTrigger.SetWorldTransform(GetHeadTransform());
	}

	UFUNCTION(CallInEditor, Category = "Rail")
	private void SnapTailTriggerToEndOfSpline()
	{
		TailTrigger.SetWorldTransform(GetTailTransform());
	}

	UFUNCTION(CallInEditor, Category = "Rail Propline")
	private void CopyPropLineToRail()
	{
		if(CopyPropLine == nullptr)
			return;

		CopyPropLine.bGameplaySpline = true;
		auto PropLineSpline = Spline::GetGameplaySpline(CopyPropLine);
		if(PropLineSpline != nullptr)
		{
			Spline.Modify();
			SetActorTransform(CopyPropLine.ActorTransform);
			Spline.SplinePoints = PropLineSpline.SplinePoints;
			Spline.UpdateSpline();
		}
	}

	UFUNCTION(CallInEditor, Category = "Rail Propline")
	private void CopyRailToPropLine()
	{
		if(CopyPropLine == nullptr)
			return;

		CopyPropLine.bGameplaySpline = true;
		auto PropLineSpline = Spline::GetGameplaySpline(CopyPropLine);
		if(PropLineSpline != nullptr)
		{
			PropLineSpline.Modify();
			CopyPropLine.SetActorTransform(ActorTransform);
			PropLineSpline.SplinePoints = Spline.SplinePoints;
			PropLineSpline.UpdateSpline();
			CopyPropLine.UpdatePropLine();
		}
	}
#endif
};

#if EDITOR
UCLASS(NotBlueprintable)
class UPinballRailEditorComponent : UActorComponent
{
};

class UPinballRailEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPinballRailEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const auto Rail = Cast<APinballRail>(Component.Owner);
		if(Rail == nullptr)
			return;

		FPinballRailMoveSimulation MoveSimulation;
		MoveSimulation.Initialize(Rail);
		MoveSimulation.Visualize(this);

		if(Rail.bInterpTowardsTargetSpeed)
		{
			for(auto TargetSpeed : Rail.TargetSpeedAlongSpline)
			{
				FTransform Transform = Rail.Spline.GetWorldTransformAtSplineDistance(TargetSpeed.DistanceAlongSpline);
				DrawCircle(Transform.Location, 50, FLinearColor::Yellow, 3, Transform.Rotation.ForwardVector);
				DrawWorldString(f"TargetSpeed: {Math::RoundToInt(TargetSpeed.TargetSpeed)}", Transform.Location, FLinearColor::Yellow, 1);
			}
		}

		DrawSyncPoint(Rail.HeadSyncPoint, "Head SyncPoint");
		DrawSyncPoint(Rail.TailSyncPoint, "Tail SyncPoint");
	}

	private void DrawSyncPoint(UPinballRailSyncPoint SyncPoint, FString Text) const
	{
		if(!SyncPoint.IsVisible())
			return;

		DrawWireSphere(SyncPoint.WorldLocation, 10, FLinearColor::Yellow, 3, bScreenSpace = true);
		DrawWorldString(f"{Text}: {SyncPoint.GetModeString()}", SyncPoint.WorldLocation, FLinearColor::Yellow);
	}

	private void DrawSide(FString SideName, FTransform Transform)
	{
		
		DrawWorldString(SideName, Transform.Location + Transform.Rotation.ForwardVector * 500, Scale = 2, bCenterText = true);
	}



};
#endif
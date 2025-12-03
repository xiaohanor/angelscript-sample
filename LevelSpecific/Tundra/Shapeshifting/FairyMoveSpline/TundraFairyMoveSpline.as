event void FFiaryMoveSplineEvent();

class UTundraFairyMoveSplineVisualizationComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraFairyMoveSplineVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraFairyMoveSplineVisualizationComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Spline = UHazeSplineComponent::Get(Component.Owner);
		auto Actor = Cast<ATundraFairyMoveSpline>(Component.Owner);
		const float SplineDistancePerIteration = 80.0;
		const FLinearColor SplineCapsuleColor = FLinearColor::White;
		const float SplineCapsuleLineThickness = 3.0;
		const float CircleSegments = 16;

		float CurrentSplineDistance = 0.0;
		FTransform CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
		DrawCircle(CurrentSplineTransform.Location, Actor.MagneticSnapToRange, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.ForwardVector, CircleSegments);
		DrawArc(CurrentSplineTransform.Location, 180.0, Actor.MagneticSnapToRange, -CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CircleSegments, 0.0, false);
		DrawArc(CurrentSplineTransform.Location, 180.0, Actor.MagneticSnapToRange, -CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.UpVector, CircleSegments, 0.0, false);

		FVector Line1Origin = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * Actor.MagneticSnapToRange;
		FVector Line2Origin = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * -Actor.MagneticSnapToRange;
		FVector Line3Origin = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.RightVector * Actor.MagneticSnapToRange;
		FVector Line4Origin = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.RightVector * -Actor.MagneticSnapToRange;

		while(CurrentSplineDistance < Spline.SplineLength)
		{
			CurrentSplineDistance += SplineDistancePerIteration;
			CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);

			FVector Line1Destination = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * Actor.MagneticSnapToRange;
			FVector Line2Destination = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.UpVector * -Actor.MagneticSnapToRange;
			FVector Line3Destination = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.RightVector * Actor.MagneticSnapToRange;
			FVector Line4Destination = CurrentSplineTransform.Location + CurrentSplineTransform.Rotation.RightVector * -Actor.MagneticSnapToRange;

			DrawLine(Line1Origin, Line1Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
			DrawLine(Line2Origin, Line2Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
			DrawLine(Line3Origin, Line3Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
			DrawLine(Line4Origin, Line4Destination, SplineCapsuleColor, SplineCapsuleLineThickness);

			Line1Origin = Line1Destination;
			Line2Origin = Line2Destination;
			Line3Origin = Line3Destination;
			Line4Origin = Line4Destination;
		}

		CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength);
		DrawCircle(CurrentSplineTransform.Location, Actor.MagneticSnapToRange, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.ForwardVector, CircleSegments);
		DrawArc(CurrentSplineTransform.Location, 180.0, Actor.MagneticSnapToRange, CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CircleSegments, 0.0, false);
		DrawArc(CurrentSplineTransform.Location, 180.0, Actor.MagneticSnapToRange, CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.UpVector, CircleSegments, 0.0, false);

		FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(0);
		FVector ArrowOrigin = SplineTransform.Location - SplineTransform.Rotation.ForwardVector * Actor.MagneticSnapToRange;
		FVector ArrowDirection = SplineTransform.Rotation.ForwardVector;
		DrawArrow(ArrowOrigin, ArrowOrigin + ArrowDirection * 100, FLinearColor::Red, 15, 3);
	}
}

enum ETundraFairyMoveSplineCameraMode
{
	/* Will focus on a point several units in front of the player on the spline */
	PointOfInterest,
	/* Same as point of interest but can turn slightly with camera stick to look around, letting go will reset back to default */
	PointOfInterestWithStick,
	/* The camera is completely free but when the spline turns, the camera will turn with it */
	FreeButFollowsTurns
}

UCLASS(Abstract)
class ATundraFairyMoveSpline : ASplineActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UTundraFairyMoveSplineVisualizationComponent VisualizationComponent;

	UPROPERTY(DefaultComponent, Attach=Spline)
	UNiagaraComponent Niagara;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ATundraFairyMoveSplineSwitchTargetableActor> SwitchTargetableActorClass;

	UPROPERTY(EditAnywhere)
	ETundraFairyMoveSplineCameraMode CameraMode = ETundraFairyMoveSplineCameraMode::PointOfInterestWithStick;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "CameraMode == ETundraFairyMoveSplineCameraMode::PointOfInterestWithStick", EditConditionHides))
	float CameraBlendInDuration = 0.5;

	UPROPERTY(EditAnywhere)
	bool bUseCustomCameraSetting = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseCustomCameraSetting", EditConditionHides))
	UHazeCameraSettingsDataAsset CameraSettings;

	/* How far above the actual spline the player will move. */
	UPROPERTY(EditAnywhere)
	float HeightOffset = 50.0;

	/* How many units/s the player will move at along the spline */
	UPROPERTY(EditAnywhere)
	float MaxSpeed = 3000.0;

	/* This will be added to the current speed when entering the spline */
	UPROPERTY(EditAnywhere)
	float StartingImpulse = 1700.0;

	/* How fast the player will accelerate */
	UPROPERTY(EditAnywhere)
	float Acceleration = 2000.0;

	/* How far away from the spline the player should start snapping towards the spline move point */
	UPROPERTY(EditAnywhere)
	float MagneticSnapToRange = 200.0;

	/* How fast the players initial speed is towards the spline move point */
	UPROPERTY(EditAnywhere)
	float MagneticSnapToStartSpeed = 0.0;

	/* How fast the player accelerates towards the spline move point */
	UPROPERTY(EditAnywhere)
	float MagneticSnapToAcceleration = 1000.0;

	/* This jump impulse will be applied to the player at the end of the move spline to make it jump off (impulse is expressed in the closest spline transform's local space) */
	UPROPERTY(EditAnywhere)
	FVector JumpOffLocalImpulse = FVector(500.0, 0.0, 500.0);

	/* If you should be able to travel in the move spline two way */
	UPROPERTY(EditAnywhere)
	bool bTwoWay = false;

	UPROPERTY(EditAnywhere)
	bool bInheritVelocity = true;

	UPROPERTY(EditAnywhere)
	bool bUseSpiralMovement = true;

	UPROPERTY(EditAnywhere)
	bool bClockwiseTorque = true;

	UPROPERTY(EditAnywhere)
	float StartSpiralRadius = 20.0;

	UPROPERTY(EditAnywhere)
	float EndSpiralRadius = 100.0;

	UPROPERTY(EditAnywhere)
	float SpiralRadiusLerpDuration = 1.5;

	/* If true will use start torque as the start torque, if false will calculate the start torque based on the players ingoing velocity */
	UPROPERTY(EditAnywhere)
	bool bUseStaticStartTorque = false;

	/* How many degrees per second the torque speed should start at, (caps at max torque), will only be used if bUseStaticStartTorque is true */
	UPROPERTY(EditAnywhere, meta = (EditCondition = "bUseStaticStartTorque"))
	float StartTorque = 500.0;

	/* How many degrees per second the current torque accelerates (caps at max torque) */
	UPROPERTY(EditAnywhere)
	float SpiralTorqueAcceleration = 1000;

	/* If true, wont start accelerating torque before done magnetically snapping */
	UPROPERTY(EditAnywhere)
	bool bStartAcceleratingTorqueWhenReachingTargetRadius = false;
	
	/* How many degrees per second the player should spiral around the spline */
	UPROPERTY(EditAnywhere)
	float SpiralMaxTorque = 1000;

	/* This will be multiplied by the velocity the player should have with torque */
	UPROPERTY(EditAnywhere)
	float InheritedTorqueVelocityMultiplier = 0.8;

	/* If true, will draw cylinders around splines so you can see where they are */
	UPROPERTY(EditAnywhere)
	bool bDebugDraw = true;

	/* Instead of assuming the spline has lots of curvature, will just draw straight lines between spline points */
	UPROPERTY(EditAnywhere)
	bool bSimplifyDebugDrawing = false;

	UPROPERTY(EditAnywhere)
	private bool bMoveSplineActive = true;

	/* If true we can switch to this spline from another spline with jump */
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bAllowSwitchingToSpline = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SwitchTargetableActorLocation;
	default SwitchTargetableActorLocation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY()
	FFiaryMoveSplineEvent OnFairyEnterEvent;
	UPROPERTY()
	FFiaryMoveSplineEvent OnFairyExitEvent;

	ATundraFairyMoveSplineSwitchTargetableActor SwitchTargetableActor;
	UTundraPlayerFairyComponent FairyComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerFairySettings FairySettings;
	AHazePlayerCharacter FairyPlayer;
	bool bFairyInSpline = false;
	TOptional<bool> WantedActiveState;

	void OnFairyEnter()
	{
		bFairyInSpline = true;
		
		if(bUseCustomCameraSetting)
			Game::Zoe.ApplyCameraSettings(CameraSettings, 2, this, EHazeCameraPriority::High);

		OnFairyEnterEvent.Broadcast();
		BP_OnFairyEnter();
	}

	void OnFairyExit()
	{
		bFairyInSpline = false;

		if(WantedActiveState.IsSet() && !WantedActiveState.Value)
			Internal_OnDeactivateMoveSpline();

		if(bUseCustomCameraSetting)
			Game::Zoe.ClearCameraSettingsByInstigator(this);

		OnFairyExitEvent.Broadcast();
		BP_OnFairyExit();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFairyEnter() {}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnFairyExit() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FairyPlayer = Game::Zoe;
		SetActorControlSide(FairyPlayer);
		MoveComp = UPlayerMovementComponent::Get(FairyPlayer);

		if(bMoveSplineActive)
		{
			auto ContainerComponent = UTundraFairyMoveSplineContainer::GetOrCreate(FairyPlayer);
			ContainerComponent.MoveSplines.AddUnique(this);
		}
		else
		{
			Internal_OnDeactivateMoveSpline(true);
		}

		SwitchTargetableActor = SpawnActor(SwitchTargetableActorClass, ActorLocation, FRotator::ZeroRotator, FName(f"{Name}_SwitchTargetable"), true);
		SwitchTargetableActor.ParentSpline = this;
		SwitchTargetableActor.MakeNetworked(this, n"_SwitchTargetable");
		FinishSpawningActor(SwitchTargetableActor);

		// We disable the switch targetable if we don't allow switching to this spline but we still want to spawn it since we use it for POI when on the spline.
		if(!bAllowSwitchingToSpline)
			SwitchTargetableActor.Targetable.Disable(this);
		
		if(ShouldTick())
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bDebugDraw)
			DebugDraw();
		
		if(FairyComp == nullptr)
		{
			FairyComp = UTundraPlayerFairyComponent::Get(FairyPlayer);
			FairySettings = UTundraPlayerFairySettings::GetSettings(FairyPlayer);
		}

		if(bAllowSwitchingToSpline && FairyComp != nullptr && FairyComp.bIsOnMoveSpline && FairyComp.CurrentMoveSpline != this)
		{
			if(HasControl())
			{
				float CurrentSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(FairyPlayer.ActorCenterLocation);
				FTransform CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);

				float PlayerToSplinePointHorizontalDistance = FairyComp.CurrentSplineLocation.DistXY(CurrentTransform.Location);
				float SpeedProjectedOnSpline = CurrentTransform.Rotation.ForwardVector.DotProduct(MoveComp.Velocity);
				float HorizontalSwitchSpeed = FairySettings.SwitchMoveSplineTargetableAheadReferenceHorizontalSpeed;
				float DurationForPlayerToReachSpline = PlayerToSplinePointHorizontalDistance / HorizontalSwitchSpeed;

				float AdditionalSplineDistance = SpeedProjectedOnSpline * DurationForPlayerToReachSpline;

				CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance + AdditionalSplineDistance);
				SwitchTargetableActorLocation.Value = CurrentTransform.Location;
			}
			
			SwitchTargetableActor.SetActorLocation(SwitchTargetableActorLocation.Value);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(FairyPlayer == nullptr)
			return;

		auto ContainerComponent = UTundraFairyMoveSplineContainer::GetOrCreate(FairyPlayer);
		ContainerComponent.MoveSplines.RemoveSingleSwap(this);
	}

	bool IsLocationWithinSnapToRange(FVector Location)
	{
		FVector ClosestPoint;
		float SplineDistance;

		return IsLocationWithinSnapToRange(Location, ClosestPoint, SplineDistance);
	}

	bool IsLocationWithinSnapToRange(FVector Location, FVector&out ClosestPoint, float&out SplineDistance)
	{
		SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Location);
		ClosestPoint = Spline.GetWorldLocationAtSplineDistance(SplineDistance);

		return (SplineDistance > 0.0 || SplineDistance < Spline.SplineLength) && ClosestPoint.DistSquared(Location) < Math::Square(MagneticSnapToRange);
	}

	const float SplineDistancePerIteration = 80.0;
	const FLinearColor SplineCapsuleColor = FLinearColor::White;
	const FLinearColor SplineLineColor = FLinearColor::Green;
	const float SplineCapsuleLineThickness = 3.0;
	const float SplineLineThickness = 10.0;
	const int CircleSegments = 16;

	void DebugDraw()
	{
		float CurrentSplineDistance = 0.0;
		FTransform CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
		Debug::DrawDebugCircle(CurrentSplineTransform.Location, MagneticSnapToRange, CircleSegments, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CurrentSplineTransform.Rotation.UpVector);
		Debug::DrawDebugArc(180.0, CurrentSplineTransform.Location, MagneticSnapToRange, -CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CircleSegments, 0.0, false);
		Debug::DrawDebugArc(180.0, CurrentSplineTransform.Location, MagneticSnapToRange, -CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.UpVector, CircleSegments, 0.0, false);

		if(!bSimplifyDebugDrawing)
		{
			while(CurrentSplineDistance < Spline.SplineLength)
			{
				CurrentSplineDistance += SplineDistancePerIteration;
				FTransform NextSplineTransform = Spline.GetWorldTransformAtSplineDistance(CurrentSplineDistance);
				DrawLinesBetweenSplineTransforms(CurrentSplineTransform, NextSplineTransform);

				CurrentSplineTransform = NextSplineTransform;
			}
		}
		else
		{
			for(int i = 0; i < Spline.SplinePoints.Num() - 1; i++)
			{
				FHazeSplinePoint CurrentSplinePoint = Spline.SplinePoints[i];
				FHazeSplinePoint NextSplinePoint = Spline.SplinePoints[i + 1];
				FTransform CurrentSplinePointTransform = FTransform(Spline.WorldTransform.TransformRotation(CurrentSplinePoint.RelativeRotation), Spline.WorldTransform.TransformPosition(CurrentSplinePoint.RelativeLocation));
				FTransform NextSplinePointTransform = FTransform(Spline.WorldTransform.TransformRotation(NextSplinePoint.RelativeRotation), Spline.WorldTransform.TransformPosition(NextSplinePoint.RelativeLocation));

				DrawLinesBetweenSplineTransforms(CurrentSplinePointTransform, NextSplinePointTransform);
			}
		}

		CurrentSplineTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength);
		Debug::DrawDebugCircle(CurrentSplineTransform.Location, MagneticSnapToRange, CircleSegments, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CurrentSplineTransform.Rotation.UpVector);
		Debug::DrawDebugArc(180.0, CurrentSplineTransform.Location, MagneticSnapToRange, CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.RightVector, CircleSegments, 0.0, false);
		Debug::DrawDebugArc(180.0, CurrentSplineTransform.Location, MagneticSnapToRange, CurrentSplineTransform.Rotation.ForwardVector, SplineCapsuleColor, SplineCapsuleLineThickness, CurrentSplineTransform.Rotation.UpVector, CircleSegments, 0.0, false);

		FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(0);
		FVector ArrowOrigin = SplineTransform.Location - SplineTransform.Rotation.ForwardVector * MagneticSnapToRange;
		FVector ArrowDirection = SplineTransform.Rotation.ForwardVector;
		Debug::DrawDebugArrow(ArrowOrigin, ArrowOrigin + ArrowDirection * 100, 50, FLinearColor::Red, 10);
	}

	private void DrawLinesBetweenSplineTransforms(FTransform OriginTransform, FTransform DestinationTransform)
	{
		FVector Line1Origin = OriginTransform.Location + OriginTransform.Rotation.UpVector * MagneticSnapToRange;
		FVector Line2Origin = OriginTransform.Location + OriginTransform.Rotation.UpVector * -MagneticSnapToRange;
		FVector Line3Origin = OriginTransform.Location + OriginTransform.Rotation.RightVector * MagneticSnapToRange;
		FVector Line4Origin = OriginTransform.Location + OriginTransform.Rotation.RightVector * -MagneticSnapToRange;
		FVector SplineLineOrigin = OriginTransform.Location;

		FVector Line1Destination = DestinationTransform.Location + DestinationTransform.Rotation.UpVector * MagneticSnapToRange;
		FVector Line2Destination = DestinationTransform.Location + DestinationTransform.Rotation.UpVector * -MagneticSnapToRange;
		FVector Line3Destination = DestinationTransform.Location + DestinationTransform.Rotation.RightVector * MagneticSnapToRange;
		FVector Line4Destination = DestinationTransform.Location + DestinationTransform.Rotation.RightVector * -MagneticSnapToRange;
		FVector SplineLineDestination = DestinationTransform.Location;

		Debug::DrawDebugLine(Line1Origin, Line1Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
		Debug::DrawDebugLine(Line2Origin, Line2Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
		Debug::DrawDebugLine(Line3Origin, Line3Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
		Debug::DrawDebugLine(Line4Origin, Line4Destination, SplineCapsuleColor, SplineCapsuleLineThickness);
		Debug::DrawDebugLine(SplineLineOrigin, SplineLineDestination, SplineLineColor, SplineLineThickness);
	}

	UFUNCTION()
	void ActivateMoveSpline()
	{
		if(bMoveSplineActive)
		{
			// If pending deactivation, we want to disregard that
			WantedActiveState.Reset();
			return;
		}

		if(WantedActiveState.IsSet() && WantedActiveState.Value)
			return;

		WantedActiveState.Set(true);
		Internal_OnActivateMoveSpline();
	}

	UFUNCTION()
	void DeactivateMoveSpline()
	{
		if(!bMoveSplineActive)
		{
			// If pending activation, we want to disregard that
			WantedActiveState.Reset();
			return;
		}

		if(WantedActiveState.IsSet() && !WantedActiveState.Value)
			return;

		WantedActiveState.Set(false);

		if(!bFairyInSpline)
			Internal_OnDeactivateMoveSpline();
	}

	UFUNCTION()
	bool IsMoveSplineActive()
	{
		return bMoveSplineActive;
	}

	private void Internal_OnActivateMoveSpline()
	{
		bMoveSplineActive = true;
		WantedActiveState.Reset();
		auto ContainerComponent = UTundraFairyMoveSplineContainer::GetOrCreate(FairyPlayer);
		ContainerComponent.MoveSplines.AddUnique(this);

		if(ShouldTick())
			SetActorTickEnabled(true);

		UPlayerFairyMoveSplineEffectHandler::Trigger_OnMoveSplineActivated(this);

		OnActivateMoveSpline();
	}

	private void Internal_OnDeactivateMoveSpline(bool bImmediate = false)
	{
		bMoveSplineActive = false;
		WantedActiveState.Reset();
		auto ContainerComponent = UTundraFairyMoveSplineContainer::GetOrCreate(FairyPlayer);
		ContainerComponent.MoveSplines.RemoveSingleSwap(this);
		SetActorTickEnabled(false);

		UPlayerFairyMoveSplineEffectHandler::Trigger_OnMoveSplineDeactivated(this);

		OnDeactivateMoveSpline(bImmediate);
	}

	bool ShouldTick() const
	{
		if(bDebugDraw)
			return true;

		if(bAllowSwitchingToSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintEvent)
	void OnActivateMoveSpline() {}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateMoveSpline(bool bImmediate) {}
}

class UTundraFairyMoveSplineContainer : UActorComponent
{
	TArray<ATundraFairyMoveSpline> MoveSplines;
}
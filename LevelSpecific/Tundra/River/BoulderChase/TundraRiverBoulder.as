enum ETundraRiverBoulderRubberbandingTarget
{
	None,
	Closest,
	Furthest,
	Mio,
	Zoe
}

event void FTundraRiverBoulderEventNoParams();

UCLASS(Abstract)
class ATundraRiverBoulder : AHazeActor
{
	access ReadOnly = private, * (readonly);

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	TSoftObjectPtr<ASplineActor> FollowSpline;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BaseForwardMaxSpeed = 900.0;

	/* The vector from the boulder to the nearest spline point will be multiplied by this value to determine the correctional speed, this multiplier will be multiplied by rubberband multiplier */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float CorrectionalDeltaMultiplier = 2.0;

	/* The boulder cannot correct faster than this. This will however be multiplied by the rubberband multiplier so this speed will vary a bit. */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float BaseCorrectionalMaxSpeed = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DragAmount = 2.2;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GravityAmount = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	ETundraRiverBoulderRubberbandingTarget BoulderRubberbandingPlayerTarget = ETundraRiverBoulderRubberbandingTarget::Closest;

	/* When the player target is within this distance of the boulder, the boulder will be moving at its slowest speed. */
	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	float ClosestDistance = 2000.0;

	/* When the player target is further away than this distance of the boulder the boulder will be moving at its max speed */
	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	float FurthestDistance = 8000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	float SlowestSpeedScale = 0.8;

	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	float FastestSpeedScale = 1.5;

	/* If true, it will use the same scale to multiply with gravity amount */
	UPROPERTY(EditAnywhere, Category = "Settings|Boulder Rubberbanding")
	bool bAlsoScaleGravityBySpeedScale = false;

	/* If a player is this far behind (or further) the other player the full speed boost multiplier will be used. */
	UPROPERTY(EditAnywhere, Category = "Settings|Player Rubberbanding")
	float PlayerRubberbandingMaxDistance = 8000.0;

	/* x: 0 is when the players are right next to each other, x: 1 is when the players are PlayerRubberbandingMaxDistance apart (or more). x: 0 is normal speed, x: 1 is multiplier speed */
	UPROPERTY(EditAnywhere, Category = "Settings|Player Rubberbanding")
	FRuntimeFloatCurve PlayerRubberbandingCurve;

	/* This max multiplier will be multiplied with the movement speed of the player that is behind (all respective shape movement settings will be updated also) */
	UPROPERTY(EditAnywhere, Category = "Settings|Player Rubberbanding")
	float PlayerRubberbandingMaxMultiplier = 3.0;

	/* This is the position of the component visualizer representation of the player in front. */
	UPROPERTY(EditAnywhere, Category = "Settings|Player Rubberbanding")
	FVector PlayerRubberbandingFakePlayerLocalOffset = FVector(10000.0, 3250.0, 0.0);

	UPROPERTY(EditAnywhere, Category = "Settings|Player Respawning")
	TArray<TSoftObjectPtr<ASplineActor>> RespawnSplines;

	UPROPERTY(EditAnywhere, Category = "Settings|Player Respawning")
	float DistanceAheadOfBoulderToRespawn = 2000.0;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"IgnorePlayerCharacter";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach=Root)
	UHazeMovablePlayerTriggerComponent KillVolume;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent KillVolumeFailsafe;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UMovementResponseBallPhysicsComponent BallPhysics;
	default BallPhysics.Type = EMovementResponseBallPhysicsType::RelativeToActor;

	UPROPERTY(DefaultComponent, Attach = BallPhysics)
	UStaticMeshComponent BoulderMesh;

	UPROPERTY(DefaultComponent)
	UTundraRiverBoulderMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TundraRiverBoulderMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraRiverBoulderPlayerRubberbandingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraRiverBoulderPlayerRespawningCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;

	UPROPERTY(DefaultComponent)
	UTundraRiverBoulderVisualizerComponent VisualizerComp;

	UPROPERTY()
	FTundraRiverBoulderEventNoParams OnBoulderStart;

	UPROPERTY()
	FTundraRiverBoulderEventNoParams OnBoulderStop;

	access:ReadOnly bool bIsActive = false;
	
	TArray<ATundraRiverBoulder_DestructibleObject> ImpactActors;

	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<AActor>> IgnoreCollsionActors;

	TArray<FInstigator> PlayerRespawnBlockers;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(FollowSpline.IsValid())
		{
			FTransform Transform = FollowSpline.Get().Spline.GetWorldTransformAtSplineDistance(0.0);
			ActorTransform = Transform;
			ActorRotation = FRotator::MakeFromZX(FVector::UpVector, Transform.Rotation.ForwardVector);
		}

		BallPhysics.BallRadius = Collision.SphereRadius;
		KillVolume.Shape = FHazeShapeSettings::MakeSphere(Collision.SphereRadius + 10.0);
	}
#endif

	UFUNCTION()
	void StartBoulder()
	{
		bIsActive = true;
		KillVolume.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterKillVolume");
		KillVolumeFailsafe.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterKillVolume");
		
		ImpactActors = TundraRiverBoulderDestructibleObject::GetAllTundraRiverBoulderDestructibleObjects();
		for(auto Actor : ImpactActors)
		{
			Collision.IgnoreActorWhenMoving(Actor, true);
		}

		for(auto ActorPtr : IgnoreCollsionActors)
		{
			auto Actor = ActorPtr.Get();
			if(Actor != nullptr)
			{
				Collision.IgnoreActorWhenMoving(Actor, true);
			}
		}

		OnBoulderStart.Broadcast();
		UTundraRiverBoulder_EffectHandler::Trigger_StartMoving(this);
	}

	UFUNCTION()
	void StopBoulder()
	{
		bIsActive = false;
		KillVolume.OnPlayerEnter.Unbind(this, n"OnPlayerEnterKillVolume");
		KillVolumeFailsafe.OnPlayerEnter.Unbind(this, n"OnPlayerEnterKillVolume");
		OnBoulderStop.Broadcast();
		UTundraRiverBoulder_EffectHandler::Trigger_StopMoving(this);
	}

	UFUNCTION()
	void AddPlayerRespawnBlocker(FInstigator Instigator)
	{
		PlayerRespawnBlockers.AddUnique(Instigator);
	}

	UFUNCTION()
	void RemovePlayerRespawnBlocker(FInstigator Instigator)
	{
		PlayerRespawnBlockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerRespawningBlocked() const
	{
		return PlayerRespawnBlockers.Num() > 0;
	}

	UFUNCTION()
	private void OnPlayerEnterKillVolume(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
	}
}

UCLASS(NotBlueprintable, NotPlaceable)
class UTundraRiverBoulderVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraRiverBoulderComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraRiverBoulderVisualizerComponent;

	bool bFakePlayerSelected = false;

	const float TextMaxDrawDistance = 15000.0;
	const float TextScale = 1.5;
	const float LineThickness = 10.0;
	const float LineLength = 3000.0;

	const FLinearColor ClosestColor = FLinearColor::Green;
	const FLinearColor ReferenceColor = FLinearColor::Yellow;
	const FLinearColor FurthestColor = FLinearColor::Red;
	const FLinearColor PlayerColor = FLinearColor::LucBlue;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		DrawBoulderRubberbandStuff();
		DrawPlayerRubberbandStuff();
	}

	void DrawBoulderRubberbandStuff()
	{
		auto Boulder = Cast<ATundraRiverBoulder>(EditingComponent.Owner);
		const FVector Forward2D = Boulder.ActorForwardVector.GetSafeNormal2D();
		const FVector Right2D = Boulder.ActorRightVector.GetSafeNormal2D();

		const FVector RightOffset = Right2D * (LineLength * 0.5);

		// Draw boulder rubber band stuff
		FVector Origin = Boulder.ActorLocation + Boulder.ActorForwardVector * Boulder.ClosestDistance;
		DrawLine(Origin - RightOffset, Origin + RightOffset, ClosestColor, LineThickness);
		DrawWorldString(f"Slowest Boulder Speed (Multiplier: {Boulder.SlowestSpeedScale})", Boulder.ActorLocation + Forward2D * Boulder.ClosestDistance, ClosestColor, TextScale, TextMaxDrawDistance);

		Origin = Boulder.ActorLocation + Boulder.ActorForwardVector * Boulder.FurthestDistance;
		DrawLine(Origin - RightOffset, Origin + RightOffset, FurthestColor, LineThickness);
		DrawWorldString(f"Fastest Boulder Speed (Multiplier: {Boulder.FastestSpeedScale})", Boulder.ActorLocation + Forward2D * Boulder.FurthestDistance, FurthestColor, TextScale, TextMaxDrawDistance);

		DrawLine(Boulder.ActorLocation + RightOffset, Origin + RightOffset, FurthestColor, LineThickness);
		DrawLine(Boulder.ActorLocation - RightOffset, Origin - RightOffset, FurthestColor, LineThickness);

		if(Boulder.SlowestSpeedScale < 1.0 && Boulder.FastestSpeedScale > 1.0)
		{
			float ReferenceDistance = Math::GetMappedRangeValueClamped(FVector2D(Boulder.SlowestSpeedScale, Boulder.FastestSpeedScale), FVector2D(Boulder.ClosestDistance, Boulder.FurthestDistance), 1.0);
			Origin = Boulder.ActorLocation + Boulder.ActorForwardVector * ReferenceDistance;
			DrawLine(Origin - RightOffset, Origin + RightOffset, ReferenceColor, LineThickness);
			DrawWorldString(f"Multiplier: 1", Boulder.ActorLocation + Forward2D * ReferenceDistance, ReferenceColor, TextScale, TextMaxDrawDistance);
		}
	}

	void DrawPlayerRubberbandStuff()
	{
		auto Boulder = Cast<ATundraRiverBoulder>(EditingComponent.Owner);
		const FVector RightOffset = Boulder.ActorRightVector * (LineLength * 0.5);

		// Draw player rubber band stuff
		SetHitProxy(n"FakePlayer", EVisualizerCursor::Hand);
		FVector FakePlayerLocation = Boulder.ActorTransform.TransformPositionNoScale(Boulder.PlayerRubberbandingFakePlayerLocalOffset);
		DrawWireDiamond(FakePlayerLocation, Boulder.ActorRotation, 100.0, PlayerColor, LineThickness);
		ClearHitProxy();

		DrawWorldString("Fake Player", FakePlayerLocation, PlayerColor, TextScale, TextMaxDrawDistance);
		FVector FakePlayerMaxDistanceOrigin = FakePlayerLocation - Boulder.ActorForwardVector * Boulder.PlayerRubberbandingMaxDistance;
		DrawLine(FakePlayerMaxDistanceOrigin + RightOffset, FakePlayerMaxDistanceOrigin - RightOffset, FLinearColor::Red, LineThickness);
		DrawWorldString("Player Rubberband Max Dist", FakePlayerMaxDistanceOrigin, PlayerColor, TextScale, TextMaxDrawDistance);

		float CurrentSamplingStep = 0.01 / (Boulder.PlayerRubberbandingMaxDistance / 8000.0);

		FRuntimeFloatCurveDrawParams DrawParams;
		DrawParams.CurveColor = FLinearColor::Red;
		DrawParams.bDrawFrame = false;
		DrawParams.FrameColor = PlayerColor;
		DrawParams.FrameThickness = LineThickness;
		DrawParams.CurveThickness = LineThickness;
		DrawParams.SamplingSteps = CurrentSamplingStep;
		DrawParams.bUseCurveRanges = false;
		DrawParams.bLabelRanges = false; 
		DrawParams.bDrawLinesToBottomEverySampleStep = true;
		DrawRuntimeFloatCurve(Boulder.PlayerRubberbandingCurve, FakePlayerLocation, Boulder.PlayerRubberbandingMaxDistance, 1500.0, -Boulder.ActorRightVector, -Boulder.ActorForwardVector, DrawParams);
		DrawRuntimeFloatCurve(Boulder.PlayerRubberbandingCurve, FakePlayerLocation, Boulder.PlayerRubberbandingMaxDistance, 1500.0, Boulder.ActorRightVector, -Boulder.ActorForwardVector, DrawParams);

		DrawLine(FakePlayerLocation + RightOffset, FakePlayerLocation - RightOffset, FLinearColor::Red, LineThickness);
		DrawLine(FakePlayerLocation + RightOffset, FakePlayerMaxDistanceOrigin + RightOffset, FLinearColor::Red, LineThickness);
		DrawLine(FakePlayerLocation - RightOffset, FakePlayerMaxDistanceOrigin - RightOffset, FLinearColor::Red, LineThickness);
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bFakePlayerSelected = false;
	}

	// Handle when the point with the hitproxy is clicked 
	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
							 EInputEvent Event)
	{
		if(HitProxy == n"FakePlayer")
		{
			bFakePlayerSelected = true;
			return true;
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Boulder = Cast<ATundraRiverBoulder>(EditingComponent.Owner);

		if(bFakePlayerSelected)
		{
			OutLocation = Boulder.ActorTransform.TransformPositionNoScale(Boulder.PlayerRubberbandingFakePlayerLocalOffset);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem,
										EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bFakePlayerSelected)
			return false;

		auto Boulder = Cast<ATundraRiverBoulder>(EditingComponent.Owner);
		OutTransform = FTransform(Boulder.ActorRotation);
		return true;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(!bFakePlayerSelected)
			return false;

		auto Boulder = Cast<ATundraRiverBoulder>(EditingComponent.Owner);
		if (!DeltaTranslate.IsNearlyZero())
		{
			Boulder.PlayerRubberbandingFakePlayerLocalOffset += Boulder.ActorTransform.InverseTransformVectorNoScale(DeltaTranslate);
		}

		return true;
	}
}

class UTundraRiverBoulderMovementComponent : UHazeMovementComponent
{
	
}

// For managers, it can be helpful to add a helper function to look it up from the list:
namespace TundraRiverBoulder
{
	// Get the example listed actor in the level
	UFUNCTION()
	ATundraRiverBoulder GetTundraRiverBoulder()
	{
		return TListedActors<ATundraRiverBoulder>().GetSingle();
	}


}
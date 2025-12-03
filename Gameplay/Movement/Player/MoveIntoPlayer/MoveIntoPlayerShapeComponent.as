const FStatID STAT_MoveIntoPlayer_HandleOnMoved(n"MoveIntoPlayer_HandleOnMoved");
const FStatID STAT_MoveIntoPlayer_GetRotationDeltas(n"MoveIntoPlayer_GetRotationDeltas");
const FStatID STAT_MoveIntoPlayer_GetLocationDeltas(n"MoveIntoPlayer_GetLocationDeltas");

event void FMoveIntoPlayerShapeOnImpactPlayer(AHazePlayerCharacter Player);

class UMoveIntoPlayerShapeComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Move Into Player")
	FHazeShapeSettings Shape;
	default Shape.Type = EHazeShapeType::Box;
	default Shape.BoxExtents = FVector(100);
	default Shape.SphereRadius = 100;
	default Shape.CapsuleRadius = 100;
	default Shape.CapsuleHalfHeight = 200;

	/**
	 * Do we want the player to receive velocity when pushed by us?
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player")
	bool bImpartVelocityOnPushedPlayer = true;

	/**
	 * NOTE: Currently only supported for Box shapes.
	 * If enabled, we will substep the hit detection to support the shape rotating.
	 * This is more expensive than just doing a moving sweep, but allows us to have collision
	 * between spinning shapes and the player, which is usually not possible.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player|Rotation")
	bool bSupportRotation = false;

	/**
	 * If enabled, the player will slide along the surface instead of just being pushed in the movement direction.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player|Moving")
	bool bSlideAlongSurface = false;

	/**
	 * How many angles (in degrees) between each rotational overlap iteration. Higher values means less precision, but better performance.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player|Rotation", Meta = (EditCondition = "bSupportRotation", ClampMin = "0.1", ClampMax = "10"))
	float AngleStep = 5;

	/**
	 * How many angles (in degrees) is required to even do a rotational sweep.
	 * If the rotational difference between this frame and the last is less than this value, we just do a move instead since we did not rotate very much.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player|Rotation", Meta = (EditCondition = "bSupportRotation", ClampMin = "0.1", ClampMax = "10"))
	float MinAngleStep = -1;


	/**
	 * The culling distance is the bounds radius multiplied by this value.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player", AdvancedDisplay)
	float CullingMultiplier = 1.5;

#if EDITOR
	UPROPERTY(EditAnywhere, Category = "Move Into Player", AdvancedDisplay)
	bool bVisualizeCullingDistance = false;
#endif

	/**
	 * Sync player location relative to the moving shape in network.
	 */
	UPROPERTY(EditAnywhere, Category = "Move Into Player|Moving")
	bool bCrumbSyncRelativeToShape = true;

	UPROPERTY(BlueprintReadOnly)
	FMoveIntoPlayerShapeOnImpactPlayer OnImpactPlayer;

	float CullingDistanceSquared;
	bool bHasMovedThisFrame = false;
	FTransform PreviousTransform;
	uint64 OnMovedDelegateHandle = 0;

	const bool bRunInTick = false;

	FString MoveCategory;
#if !RELEASE
	uint LastMovedFrame = 0;
	int MovesThisFrame = 0;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousTransform = WorldTransform;

#if !RELEASE
		if(Shape.Type == EHazeShapeType::None || Shape.Type == EHazeShapeType::EHazeShapeType_MAX)
		{
			PrintError(f"Invalid shape type on {Name.ToString()} attached to {Owner.ActorNameOrLabel}!");
			return;
		}
#endif
		
		OnMovedDelegateHandle = SceneComponent::BindOnSceneComponentMoved(this, FOnSceneComponentMoved(this, n"OnSceneComponentMoved"));

		if(bSupportRotation)
		{
			if(!CurrentShapeSupportsRotation())
			{
				PrintWarning(f"MoveIntoPlayerShapeComponent attached to actor {Owner} has bSupportRotation enabled, but the shape ({Shape.Type}) does not support rotation.");
				bSupportRotation = false;
			}
		}

		CullingDistanceSquared = Math::Square(Shape.EncapsulatingSphereRadius * CullingMultiplier);

#if EDITOR
		if(IsDebugging())
		{
			// Make sure there are transform loggers if we are being debugged
			AActor Actor = Owner;
			while(Actor != nullptr)
			{
				UTemporalLogTransformLoggerComponent::GetOrCreate(Actor);
				Actor = Actor.AttachParentActor;
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		SceneComponent::UnbindOnSceneComponentMoved(this, OnMovedDelegateHandle);
		OnMovedDelegateHandle = 0;	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bHasMovedThisFrame)
		{
			SetComponentTickEnabled(false);
			return;
		}

		if(bRunInTick)
		{
			// FB TODO: Check if it is ok to run movement here in Tick instead of OnSceneComponentMoved
			HandleOnMoved(FInstigator(n"Tick"));
		}

		PreviousTransform = WorldTransform;
		SetComponentTickEnabled(false);
	}

	UFUNCTION()
	private void OnSceneComponentMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		#if EDITOR
		if(TemporalLog::IsApplyingScrub())
			return;

		if(IsDebugging())
		{
			if(LastMovedFrame < Time::FrameNumber)
			{
				LastMovedFrame = Time::FrameNumber;
				MovesThisFrame = 1;
			}
			else
			{
				MovesThisFrame++;
			}
		}
		#endif

		if(bIsTeleport)
		{
			PreviousTransform = WorldTransform;
			return;
		}

		// We don't want to run the resolver here, since this function can run multiple times per frame
		// Instead, we just remember that we have moved, so that we can respond later in Tick();
		if(bRunInTick)
		{
			bHasMovedThisFrame = true;
			SetComponentTickEnabled(true);
		}
		else
		{
			FInstigator MoveInstigator = FInstigator(MovedComponent);

#if EDITOR
			UObject InstigatorObject = nullptr;
			for(int i = 0; i < 10; i++)
			{
				InstigatorObject = Debug::EditorGetAngelscriptStackFrameObject(i);

				if(InstigatorObject == nullptr)
					continue;

				if(InstigatorObject == this)
					continue;

				auto MoveComp = Cast<UHazeMovementComponent>(InstigatorObject);
				if(MoveComp != nullptr)
					continue;

				MoveInstigator = FInstigator(InstigatorObject);
				break;
			}
#endif

			HandleOnMoved(MoveInstigator);
			PreviousTransform = WorldTransform;
		}
	}

	private void HandleOnMoved(FInstigator MoveIntoPlayerInstigator)
	{
		FScopeCycleCounter CycleCounter(STAT_MoveIntoPlayer_HandleOnMoved);

		bool bDoRotation = false;

		if(bSupportRotation)
		{
			// FB TODO: Calculate AngleStep from angular distance, rotation delta and box shape?
			const float AngularDistanceDegrees = Math::RadiansToDegrees(PreviousTransform.Rotation.AngularDistance(ComponentQuat));
			if(MinAngleStep < KINDA_SMALL_NUMBER)
				bDoRotation = true;
			else if(AngularDistanceDegrees > MinAngleStep)
				bDoRotation = true;
		}

#if !RELEASE
		MoveCategory = f"Move {MovesThisFrame} from: {MoveIntoPlayerInstigator}";

		if(IsDebugging())
		{
			TEMPORAL_LOG(this).Section(MoveCategory, MovesThisFrame)
				.Value("Move Instigator", MoveIntoPlayerInstigator)
				.Shape("Previous Transform", PreviousTransform.Location, Shape, PreviousTransform.Rotator(), FLinearColor::Red, 5)
				.Shape("World Transform", WorldTransform.Location, Shape, WorldTransform.Rotator(), FLinearColor::Green, 5)
				.Value("Type", bDoRotation ? "Rotating" : "Moving")
			;
		}
#endif

		for(auto Player : Game::Players)
		{
			if(IsCulledForPlayer(Player))
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);

			TArray<USceneComponent> FollowedComponents;
			MoveComp.GetFollowedComponents(FollowedComponents);

			bool bIsFollowingThisActor = false;
			for(auto FollowedComponent : FollowedComponents)
			{
				if(FollowedComponent.Owner == Owner)
				{
					bIsFollowingThisActor = true;
#if !RELEASE
					if(IsDebugging())
						GetTemporalLogForPlayer(Player).Status("Is following component", FLinearColor::Yellow);
#endif
					break;
				}
			}

			// If the player is already following this actor, don't bother handling this move because it should be handled by the follow component resolver
			if(bIsFollowingThisActor)
				continue;

			if(bDoRotation)
			{
				FVector Delta;
				FVector ExtrapolatedDelta;
				if(!GetRotationDeltas(Player, PreviousTransform, WorldTransform, Delta, ExtrapolatedDelta))
					continue;

				MoveComp.HandlePlayerMoveIntoRotating(this, bImpartVelocityOnPushedPlayer, Delta, ExtrapolatedDelta, bCrumbSyncRelativeToShape);
			}
			else
			{
				FVector Delta;
				if(!GetLocationDelta(Player, Delta))
					continue;

				MoveComp.HandlePlayerMoveInto(Delta, this, bImpartVelocityOnPushedPlayer, MoveCategory, bCrumbSyncRelativeToShape);
			}

			OnImpactPlayer.Broadcast(Player);
		}
	}

	private bool IsCulledForPlayer(AHazePlayerCharacter Player) const
	{
		const float DistanceSquared = WorldLocation.DistSquared(Player.CapsuleComponent.WorldLocation);
		return DistanceSquared > CullingDistanceSquared;
	}

	private bool GetRotationDeltas(AHazePlayerCharacter Player, FTransform Start, FTransform End, FVector&out OutDelta, FVector&out OutExtrapolatedDelta) const
	{
		FScopeCycleCounter CycleCounter(STAT_MoveIntoPlayer_GetRotationDeltas);
		
		const float AngularDistanceDegrees = Math::RadiansToDegrees(PreviousTransform.Rotation.AngularDistance(ComponentQuat));

		// FB TODO: Calculate AngleStep from angular distance, rotation delta and box shape?
		const int RotationIterations = Math::CeilToInt(AngularDistanceDegrees / AngleStep);

		if(RotationIterations <= 0)
			return false;

#if !RELEASE
		if(IsDebugging())
			GetTemporalLogForPlayer(Player).Capsule(f"{MoveCategory};Player Capsule", Player.CapsuleComponent.WorldLocation, Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.WorldRotation);
#endif

		bool bHit = false;
		FTransform HitTransform;

		for(int i = 0; i <= RotationIterations; i++)
		{
			const float Alpha = float(i) / RotationIterations;
			const FTransform TraceTransform = LerpTransform(Start, End, Alpha);

			FHazeTraceSettings OverlapSettings = Trace::InitAgainstComponent(Player.CapsuleComponent);
			OverlapSettings.UseShape(Shape, TraceTransform.Rotation);

			const FOverlapResult Overlap = OverlapSettings.QueryOverlapComponent(TraceTransform.Location);

#if !RELEASE
			if(IsDebugging())
			{
				const FString IterationCategory = f"{GetIterationPrefix(i)}Iteration {i}";
				GetTemporalLogForPlayer(Player)
					.OverlapResults(f"{MoveCategory};{IterationCategory};Rotation Overlap", Overlap, OverlapSettings.Shape, TraceTransform.Location)
					.Value(f"{MoveCategory};{IterationCategory};Alpha", Alpha);
			}
#endif

			if(Overlap.bBlockingHit)
			{
				if(i == 0)
				{
					FVector SweepDirection = (LerpTransform(Start, End, Alpha + 0.01).Location - TraceTransform.Location).GetSafeNormal();
					FPlane Plane(TraceTransform.Location, SweepDirection);

					// Don't allow the first hit to be behind the sweep plane
					if(Plane.PlaneDot(Overlap.Component.WorldLocation) < 0)
						continue;
				}

#if !RELEASE
				if(IsDebugging())
				{
					GetTemporalLogForPlayer(Player)
						.Status(f"Rotational Hit! {MoveCategory} Iteration {i}", FLinearColor::Green);
				}
#endif

				bHit = true;
				HitTransform = TraceTransform;
				break;
			}
		}

		if(!bHit)
			return false;

		// If we hit, we want to generate one delta per iteration that was left of this move, making the player move along with the rotation

		// Get location relative to the first hit
		const FVector HitLocation = Player.CapsuleComponent.WorldLocation;
		const FVector HitRelativeLocation = HitTransform.InverseTransformPositionNoScale(Player.CapsuleComponent.WorldLocation);

		const float FinalAlpha = 1;
		const FTransform FinalTransform = LerpTransform(Start, End, FinalAlpha);
		const FVector FinalLocation = FinalTransform.TransformPositionNoScale(HitRelativeLocation);

		// Extrapolate forward a bit to prevent the capsule from penetrating the actor after following the move
		const float ExtrapolatedAlpha = 1.2;
		const FTransform ExtrapolatedTransform = LerpTransform(Start, End, ExtrapolatedAlpha);
		const FVector ExtrapolatedLocation = ExtrapolatedTransform.TransformPositionNoScale(HitRelativeLocation);

		OutDelta = FinalLocation - HitLocation;
		OutExtrapolatedDelta = ExtrapolatedLocation - FinalLocation;

#if !RELEASE
		if(IsDebugging())
		{
			GetTemporalLogForPlayer(Player)
				.DirectionalArrow(f"{MoveCategory};Deltas;Delta", HitLocation, OutDelta)
				.DirectionalArrow(f"{MoveCategory};Deltas;OutExtrapolatedDelta", FinalLocation, OutExtrapolatedDelta)
			;
		}
#endif

		if((OutDelta + OutExtrapolatedDelta).IsNearlyZero())
			return false;

		return true;
	}

	private bool GetLocationDelta(AHazePlayerCharacter Player, FVector&out OutDelta) const
	{
		FScopeCycleCounter CycleCounter(STAT_MoveIntoPlayer_GetLocationDeltas);

		FVector Delta = WorldLocation - PreviousTransform.Location;

		if(Delta.IsNearlyZero())
			return false;

		FVector ToPlayer = Player.CapsuleComponent.WorldLocation - PreviousTransform.Location;

		// If the player is not in the direction of the delta,
		// don't bother sweeping since we are moving away from the player
		if(Delta.DotProduct(ToPlayer) < 0)
			return false;

		FHazeTraceSettings TraceSettings = Trace::InitAgainstComponent(Player.CapsuleComponent);
		TraceSettings.UseShape(Shape, ComponentQuat);
		//TraceSettings.DebugDrawOneFrame();
		FHitResult Hit = TraceSettings.QueryTraceComponent(PreviousTransform.Location, WorldLocation);

#if !RELEASE
		if(IsDebugging())
		{
			GetTemporalLogForPlayer(Player)
				.HitResults(f"{MoveCategory};Component Trace", Hit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
		}
#endif

		if(!Hit.bBlockingHit)
			return false;

#if !RELEASE
		if(IsDebugging())
		{
			GetTemporalLogForPlayer(Player)
				.Status(f"Sweep Hit! {MoveCategory}", FLinearColor::Green);
		}
#endif

		if(bSlideAlongSurface)
		{
			FVector HitNormal = (Shape.GetClosestPointToPoint(WorldTransform, Player.ActorCenterLocation) - WorldLocation).GetSafeNormal();
			//Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, HitNormal, 200, 10, FLinearColor::Red, 3, 1);
			Delta = Delta.ProjectOnToNormal(HitNormal);
		}

		// Only move the rest of the sweep from the hit
		Delta *= (1.0 - Hit.Time);
		OutDelta = Delta;
		return true;
	}

	private FTransform LerpTransform(FTransform A, FTransform B, float Alpha) const
	{
		FVector Location = Math::Lerp(A.Location, B.Location, Alpha);
		FQuat Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		return FTransform(Rotation, Location);
	}

	private bool CurrentShapeSupportsRotation() const
	{
		switch(Shape.Type)
		{
			case EHazeShapeType::Box:
				return true;

			case EHazeShapeType::Capsule:
				return true;

			default:
				return false;
		}
	}

#if !RELEASE
	FTemporalLog GetTemporalLogForPlayer(AHazePlayerCharacter Player) const
	{
		check(IsDebugging());
		return TEMPORAL_LOG(this, Player.IsMio() ? "Mio" : "Zoe");
	}

	private FString GetIterationPrefix(int Iteration) const
	{
		check(IsDebugging());
		return f"{Iteration :03}#";
	}

	bool IsDebugging() const
	{
#if EDITOR
		if(bHazeEditorOnlyDebugBool)
			return true;

		if(Owner.bHazeEditorOnlyDebugBool)
			return true;
#endif

		return false;
	}
#endif

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Move Into Player")
	private void FitSphereToParentComponentBounds()
	{
		if(AttachParent == nullptr)
			return;

		auto BoundingBox = AttachParent.GetComponentLocalBoundingBox();
		Shape.Type = EHazeShapeType::Sphere;
		Shape.SphereRadius = (BoundingBox.Extent * AttachParent.WorldScale) .AbsMax;
		SetRelativeLocationAndRotation(BoundingBox.Center, FRotator::ZeroRotator);
	}

	UFUNCTION(CallInEditor, Category = "Move Into Player")
	private void FitBoxToParentComponentBounds()
	{
		if(AttachParent == nullptr)
			return;

		auto BoundingBox = AttachParent.GetComponentLocalBoundingBox();
		Shape.Type = EHazeShapeType::Box;
		Shape.BoxExtents = BoundingBox.Extent * AttachParent.WorldScale;
		SetRelativeLocationAndRotation(BoundingBox.Center, FRotator::ZeroRotator);
	}
#endif
};

#if EDITOR
class UMoveIntoPlayerShapeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMoveIntoPlayerShapeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto MoveIntoComp = Cast<UMoveIntoPlayerShapeComponent>(Component);
		if(MoveIntoComp == nullptr)
			return;

		DrawWireShape(MoveIntoComp.Shape.CollisionShape, MoveIntoComp.WorldLocation, MoveIntoComp.ComponentQuat, FLinearColor::LucBlue, 3);

		if(MoveIntoComp.bVisualizeCullingDistance)
		{
			const float CullingDistance = MoveIntoComp.Shape.EncapsulatingSphereRadius * MoveIntoComp.CullingMultiplier;
			DrawWireSphere(MoveIntoComp.WorldLocation, CullingDistance, FLinearColor::Red, 1, 12, true);
		}
	}
};
#endif
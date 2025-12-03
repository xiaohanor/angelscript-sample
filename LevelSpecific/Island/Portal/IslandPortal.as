enum EIslandPortalType
{
	/* Only travelers of type None or Red can enter these portals */
	Red,
	/* Only travelers of type None or Blue can enter these portals */
	Blue,
	/* All travelers can enter these portals */
	Both
}

enum EIslandPortalConsumeAirJumpDashType
{
	/* Neither reset nor consume it, if we could air jump/dash before teleporting we can after and vice versa. */
	None,
	/* Reset air jump and dash so we can air jump/dash after teleporting. */
	Reset,
	/* Consume air jump and dash so we can't air jump/dash after teleporting. */
	Consume
}

event void FIslandPortalSignature();
event void FIslandPortalOnEnterSignature(AActor TeleportedActor, AIslandPortal OriginPortal, AIslandPortal DestinationPortal);
event void FIslandPortalOnPlayerEnterSignature(AHazePlayerCharacter TeleportedPlayer, AIslandPortal OriginPortal, AIslandPortal DestinationPortal);

UCLASS(Abstract)
class AIslandPortal : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EffectLocation;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandPortalVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	/* The portal type defines which travelers can enter it, red means Mio and any other travelers with red, same for blue and Zoe. Both means anyone can enter it. */
	UPROPERTY(EditAnywhere)
	EIslandPortalType PortalType;

	UPROPERTY(EditAnywhere)
	EIslandPortalConsumeAirJumpDashType ConsumeAirJumpDashType = EIslandPortalConsumeAirJumpDashType::Reset;

	UPROPERTY(EditAnywhere)
	bool bFixedPlayerVelocityWhenExitingPortal = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bFixedPlayerVelocityWhenExitingPortal", EditConditionHides))
	FVector LocalPlayerVelocityWhenExitingPortal = FVector(100.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bConstrainOutgoingVelocityToPortalNormal = false;

	/* Player will at least have this velocity out from the portal, negative values means no min velocity */
	UPROPERTY(EditAnywhere)
	float MinVelocityOutOfPortal = -1.0;

	UPROPERTY(EditAnywhere, BlueprintHidden, DisplayName = "Destination Portal")
	private AIslandPortal Internal_DestinationPortal;

	UPROPERTY(EditAnywhere)
	bool bNeverClosePortal;

	UPROPERTY(EditAnywhere)
	bool bIgnoreDeathVolumesBehindPortal = true;

	private AIslandPortalManager Manager;
	FTransform PreviousPortalTransform;
	FBox LocalBoundingBox;

	UPROPERTY()
	FIslandPortalSignature OnPortalClosed;

	UPROPERTY()
	FIslandPortalOnEnterSignature OnEnterPortal;

	UPROPERTY()
	FIslandPortalOnPlayerEnterSignature OnPlayerEnterPortal;

	UPROPERTY(EditAnywhere)
	bool bUseOnce = true;

	UPROPERTY()
	UNiagaraSystem ExitEffect;

	UPROPERTY()
	UForceFeedbackEffect BoostFeedback;

	UPROPERTY(EditAnywhere)
	bool bAllowPortalEnteringTraveler = true;

	UPROPERTY(VisibleAnywhere, Transient)
	TArray<AActor> ActorsToIgnoreWhenEnteringPortal;

	int PortalIndex;
	bool bHasDoneInitialTick = false;

#if !RELEASE
	int AmountOfCalculationsPerTick = 0;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AIslandPortalManager> ListedManagers;
		Manager = ListedManagers.Single;
		devCheck(Manager != nullptr, "Forgot to add a portal manager in the level!");

		RegisterPortal();
		LocalBoundingBox = GetActorLocalBoundingBox(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(Manager != nullptr)
			UnregisterPortal();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		RegisterPortal();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UnregisterPortal();
	}

	private void RegisterPortal()
	{
		Manager.Portals.AddUnique(this);
		PortalIndex = Manager.Portals.Num() - 1;
	}

	private void UnregisterPortal()
	{
		Manager.Portals.RemoveSingle(this);
		PortalIndex = -1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PreviousPortalTransform = ActorTransform;

		// Do the initial update the first tick so that we don't have any weirdness if the progress point makes us go into a portal just a few frames after BeginPlay.
		if(!bHasDoneInitialTick)
		{
			CalculateActorsToIgnoreWhenEnteringPortal();
			bHasDoneInitialTick = true;
		}

		// Spread out updates so we only overlap check one portal per frame
		int WrappedFrameNumber = int(Time::FrameNumber % MAX_int32);
		const int FrameUpdateFrequency = 1;
		if(Manager != nullptr && WrappedFrameNumber % (Manager.Portals.Num() * FrameUpdateFrequency) == (PortalIndex * FrameUpdateFrequency))
		{	
			CalculateActorsToIgnoreWhenEnteringPortal();
		}

#if !RELEASE
		AmountOfCalculationsPerTick = 0;
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		for(int i = 0; i < ActorsToIgnoreWhenEnteringPortal.Num(); i++)
		{
			TemporalLog.Value(f"Final ActorsToIgnoreWhenEnteringPortal[{i}]", ActorsToIgnoreWhenEnteringPortal[i]);
		}

		if(ActorsToIgnoreWhenEnteringPortal.Num() == 0)
			TemporalLog.Value(f"Final ActorsToIgnoreWhenEnteringPortal.Num() == 0!", "");
#endif
	}

	void CalculateActorsToIgnoreWhenEnteringPortal()
	{
		ActorsToIgnoreWhenEnteringPortal.Reset();
		// The below used to be InitFromPlayer but we can't do this because that will ignore any actors that the player ignores which will make Zoe not be able to go through the portal if Mio is also going through that portal.
		FHazeTraceSettings Trace = Trace::InitProfile(Game::Mio.CapsuleComponent.GetNonOverrideCollisionProfile());
		FVector2D CapsuleSize;
		CapsuleSize.X = Game::Mio.CapsuleComponent.ScaledCapsuleRadius;
		CapsuleSize.Y = Game::Mio.CapsuleComponent.ScaledCapsuleHalfHeight;
		
		FBox Bounds = Mesh.GetBoundingBoxRelativeToOwner();
		FVector ScaledPortalExtents = Bounds.Extent * ActorScale3D;

		FVector Extents = ScaledPortalExtents;
		if(IsVerticalPortal())
		{
			Extents.X = CapsuleSize.Y * 2.0;
			Extents.Y += CapsuleSize.X;
			Extents.Z += CapsuleSize.X;
		}
		else
		{
			Extents.X = CapsuleSize.X * 2.0;
			Extents.Y += CapsuleSize.X;
			Extents.Z += CapsuleSize.Y;
		}

		Trace.UseBoxShape(Extents, ActorQuat);
		FOverlapResultArray Overlaps1 = Trace.QueryOverlaps(ActorCenterLocation - ActorForwardVector * Extents.X);
		for(auto Overlap : Overlaps1.BlockHits)
		{
			ActorsToIgnoreWhenEnteringPortal.AddUnique(Overlap.Actor);
		}

		for(auto Overlap : Overlaps1.OverlapHits)
		{
			if(Overlap.Actor.IsA(ADeathVolume))
				ActorsToIgnoreWhenEnteringPortal.AddUnique(Overlap.Actor);
		}

		Extents.X = 10.0;
		Trace.UseBoxShape(Extents, ActorQuat);
		FOverlapResultArray Overlaps2 = Trace.QueryOverlaps(ActorCenterLocation + ActorForwardVector * (Extents.X + 5.0));
		for(auto Overlap : Overlaps2.BlockHits)
		{
			ActorsToIgnoreWhenEnteringPortal.RemoveSingleSwap(Overlap.Actor);
		}
#if !RELEASE
		AmountOfCalculationsPerTick++;
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		FString Category = f"CalculateActorsToIgnoreWhenEnteringPortal {AmountOfCalculationsPerTick}";
		TemporalLog.Value(f"{Category};IsVerticalPortal()", IsVerticalPortal());
		TemporalLog.OverlapResults(f"{Category};Overlaps1", Overlaps1);
		TemporalLog.OverlapResults(f"{Category};Overlaps2", Overlaps2);
		for(int i = 0; i < ActorsToIgnoreWhenEnteringPortal.Num(); i++)
		{
			TemporalLog.Value(f"{Category};ActorsToIgnoreWhenEnteringPortal[{i}]", ActorsToIgnoreWhenEnteringPortal[i]);
		}
#endif
	}

	bool IsVerticalPortal() const
	{
		return Math::Abs(ActorForwardVector.DotProduct(FVector::UpVector)) > 0.5;
	}

	UFUNCTION()
	void SetDestinationPortal(AIslandPortal Portal)
	{
		Internal_DestinationPortal = Portal;
	}

	UFUNCTION(BlueprintPure)
	AIslandPortal GetDestinationPortal() property
	{
		return Internal_DestinationPortal;
	}

	FVector GetPortalCenter() const property
	{
		FVector Origin, BoxExtent;
		GetActorBounds(false, Origin, BoxExtent);
		if(BoxExtent.IsNearlyZero())
			return GetActorLocation();
		return Origin;
	}

	FVector GetPortalNormal() const property
	{
		return ActorForwardVector;
	}

	bool ShouldClosePortalWhenPlayerEntering()
	{
		if(bNeverClosePortal)
			return false;
		if(PortalType != EIslandPortalType::Both)
			return true;

		return false;
	}

	UFUNCTION()
	void ClosePortal()
	{
		if (!bUseOnce)
			return;

		AddActorDisable(this);
		DestinationPortal.AddActorDisable(this);
		OnPortalClosed.Broadcast();
		DestinationPortal.OnPortalClosed.Broadcast();
		
		FIslandPortalGenericEffectParams Params;
		Params.Portal = this;
		UIslandPortalEffectHandler::Trigger_OnClosePortal(this, Params);

		Params.Portal = DestinationPortal; 
		UIslandPortalEffectHandler::Trigger_OnClosePortal(DestinationPortal, Params);
	}
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UIslandPortalVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandPortalVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandPortalVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Portal = Cast<AIslandPortal>(Component.Owner);
		DrawPortalNormal(Component);
	}

	private void DrawPortalNormal(const UActorComponent Component)
	{
		auto Portal = Cast<AIslandPortal>(Component.Owner);

		const float PlaneExtents = 50.0;
		const float ArrowLength = 100.0;
		const float ArrowSize = 20.0;
		const float LineThickness = 4.0;
		const float ArrowLineThickness = 4.0;
		const FLinearColor Color = FLinearColor::Red;

		const FRotator Rotator = FRotator::MakeFromX(Portal.PortalNormal);
		const FVector Forward = Rotator.ForwardVector;
		const FVector Right = Rotator.RightVector;
		const FVector Up = Rotator.UpVector;

		const FVector Origin = Portal.PortalCenter;
		const FVector ArrowEnd = Origin + Forward * ArrowLength;

		DrawArrow(Origin, ArrowEnd, Color, ArrowSize, ArrowLineThickness);

		const FVector PlanePoint1 = Origin - Up * PlaneExtents - Right * PlaneExtents;
		const FVector PlanePoint2 = Origin + Up * PlaneExtents - Right * PlaneExtents;
		const FVector PlanePoint3 = Origin + Up * PlaneExtents + Right * PlaneExtents;
		const FVector PlanePoint4 = Origin - Up * PlaneExtents + Right * PlaneExtents;
		//DrawLine(PlanePoint1, PlanePoint2, Color, LineThickness);
		//DrawLine(PlanePoint2, PlanePoint3, Color, LineThickness);
		//DrawLine(PlanePoint3, PlanePoint4, Color, LineThickness);
		//DrawLine(PlanePoint4, PlanePoint1, Color, LineThickness);
		DrawWorldString("Normal", ArrowEnd, Color);
	}
}
#endif
UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/WallRunPointIconBillboardGradient.WallRunPointIconBillboardGradient", EditorSpriteOffset="X=-65 Y=0 Z=0"))
class UGrappleWallrunPointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default GrappleType = EGrapplePointVariations::WallrunPoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;

	UPlayerWallSettings WallSettings;
	UPlayerLedgeGrabSettings LedgeGrabSettings;

	UPROPERTY(EditAnywhere, Category = Settings, meta = (ClampMin = "-90.0", ClampMax = "90.0", UIMin = "-90.0", UIMax = "90.0"))
	float EntryAngle = 20.0;

	//This is the players combined vertical and horizontal entry speed
	UPROPERTY(EditAnywhere, Category = Settings, meta = (ClampMin = "700", ClampMax = "1200", UIMin = "700", UIMax = "1200"))
	float EntrySpeed  = 1000;

	UPROPERTY(EditAnywhere, Category = Settings)
	bool bAllowForward = true;

	UPROPERTY(EditAnywhere, Category = Settings)
	bool bAllowBackwards = true;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto MoveComp = UPlayerMovementComponent::Get(Query.Player);

		if (!VerifyBaseTargetableConditions(Query))
			return false;

		if (!VerifyBaseGrappleConditions(Query))
			return false;
		
		switch (AirActivationSettings)
		{
		case EAirActivationSettings::ActivateOnlyInAir:
			if(MoveComp != nullptr)
				if(!MoveComp.IsInAir())
					return false;
		break;
		case EAirActivationSettings::ActivateOnlyOnGround:
			if(MoveComp != nullptr)
				if(!MoveComp.IsOnWalkableGround())
					return false;
		break;
		default:
		break;
		}

		switch (HeightActivationSettings)
		{
		case EHeightActivationSettings::ActivateOnlyAbove:
			if((Query.Player.ActorLocation - WorldLocation).DotProduct(MoveComp.WorldUp) < 0)
				return false;
		break;
		case EHeightActivationSettings::ActivateOnlyBelow:
			if((Query.Player.ActorLocation - WorldLocation).DotProduct(MoveComp.WorldUp) > 0)
				return false;
		break;
		default:
		break;
		}

		// Too close to the point
		FVector PlayerToPoint = Query.Player.ActorLocation - WorldLocation;
		if (PlayerToPoint.Size() < MinimumRange)
		{
			Query.Result.Score = 0.0;
			return true;
		}

		float ToGrappleDot = PlayerToPoint.DotProduct(GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp));
		if ((!bAllowForward && ToGrappleDot < 0.0) || (!bAllowBackwards && ToGrappleDot >= 0.0))
		{
			Query.Result.Score = 0.0;
			return false;
		}
		
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ScoreLookAtAim(Query);
		Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange, ActivationBufferRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange, ActivationBufferRange);
		
		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazeActor>(Owner));
		LedgeGrabSettings = UPlayerLedgeGrabSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

		FVector GetWallRunForward() const property
	{
		return -RightVector;
	}
	FVector GetWallRunForwardAdjustedByWorldUp(FVector WorldUp) const
	{
		const FVector Axis = FVector::UpVector.CrossProduct(WorldUp);
		const float Angle = FVector::UpVector.AngularDistance(WorldUp);

		return FQuat(Axis, Angle) * WallRunForward;
	}

	FVector GetForwardWithEntryAngle() const property
	{
		FVector Forward = GetWallRunForwardAdjustedByWorldUp(FVector::UpVector);
		FQuat Rotation = FQuat(-ForwardVector, Math::DegreesToRadians(EntryAngle));

		Forward = Rotation * Forward;
		return Forward;
	}

	FVector GetBackwardsWithEntryAngle() const property
	{
		FVector Backwards = -GetWallRunForwardAdjustedByWorldUp(FVector::UpVector);
		FQuat Rotation = FQuat(-ForwardVector, Math::DegreesToRadians(-EntryAngle));

		Backwards = Rotation * Backwards;
		return Backwards;
	}

#if EDITOR
	void AlignWithWall()
	{
		FHazeTraceSettings WallTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		WallTrace.UseLine();
		FHitResult WallHit = WallTrace.QueryTraceSingle(WorldLocation, WorldLocation + (ForwardVector * 1000));

		if (!WallHit.bStartPenetrating && WallHit.bBlockingHit)
		{
			FVector TargetLocation = WallHit.ImpactPoint;
			TargetLocation += WallHit.ImpactNormal * 5;
			FVector FlippedWallNormalDirection = -WallHit.ImpactNormal;
			Owner.SetActorLocationAndRotation(TargetLocation, FlippedWallNormalDirection.ToOrientationQuat());

			UGrappleWallRunPointDrawComponent DrawComp = UGrappleWallRunPointDrawComponent::Get(Owner);
			DrawComp.MarkRenderStateDirty();

			//Ugly reselect of actors to update transform Widgets / etc
			TArray<AActor> SelectedActors = Editor::SelectedActors;
			Editor::SelectActor(nullptr);
			Editor::SelectActors(SelectedActors);
		}	
	}
#endif

}

#if EDITOR
class UHazeGrappleWallrunDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AGrappleWallrunPoint;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		//If we are in blueprint editor then exit out
		if (GetCustomizedObject().World == nullptr)
		{
			HideCategory(n"AlignWithWall");
			return;
		}

		Drawer = AddImmediateRow(n"Functions");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//If we are in blueprint editor then exit out
		if (GetCustomizedObject().World == nullptr)
			return;

		if (!Drawer.IsVisible())
			return;
		
		auto Section = Drawer.Begin();

		FHazeImmediateButtonHandle Button = Section.Button("Align With Wall");
		
		// If button was clicked
		if(Button)
		{	
			if(ObjectsBeingCustomized.Num() > 1)
				Section.Text("Multiple Actors Selected.").Color(FLinearColor::Gray).Bold();

			for (UObject Object : ObjectsBeingCustomized)
			{
				//Cast to our actor, fetch component and call
				AActor ActorCheck = Cast<AActor>(Object);

				if(ActorCheck == nullptr)
					continue;

				UGrappleWallrunPointComponent PointComp = UGrappleWallrunPointComponent::Get(ActorCheck);
				
				if(PointComp == nullptr)
					continue;

				PointComp.AlignWithWall();
			}
		}

		Drawer.End();
	}

}
#endif
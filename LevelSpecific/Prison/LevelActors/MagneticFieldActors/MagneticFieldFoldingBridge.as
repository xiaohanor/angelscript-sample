class AMagneticFieldFoldingBridge : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	/**
	 * This box is only used as the overlap target of the MagneticField ability
	 */
	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UBoxComponent MagneticFieldTargetBoxComp;
	default MagneticFieldTargetBoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAbilityZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent LeftHolder;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	USceneComponent RightHolder;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;
	default MagneticFieldComp.bAffectFauxPhysics = false;

	UPROPERTY(EditAnywhere, Category = "Mesh")
	UStaticMesh MeshAsset;

	UPROPERTY(EditAnywhere)
	int BridgePieceAmount = 40;

	UPROPERTY(EditAnywhere)
	bool bPreviewRolledOut = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<UStaticMeshComponent> BridgePieces;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<float> BridgePiecePitches;

	UPROPERTY(EditAnywhere)
	FVector Scale = FVector(0.2, 4.0, 0.5);

	UPROPERTY(EditAnywhere)
	FRotator Rotation = FRotator(-90.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	float PitchPerPiece = 10.0;

	UPROPERTY(EditAnywhere)
	float PitchModifier = 0.5;

	UPROPERTY(EditAnywhere)
	float MaxPitchModifier = 8.0;

	UPROPERTY(EditAnywhere)
	float Offset = 65.0;

	// If true, the repel only works when the repel force comes from the rolled up side of the bridge
	UPROPERTY(EditInstanceOnly)
	bool bOneSided = true;

	UPROPERTY(EditDefaultsOnly)
	float KillVelocityThreshold = 200;

	const float SLEEP_THRESHOLD = 0.1;

	UPROPERTY(EditDefaultsOnly, Category="Audio")
	float StartRollingPitchThreshold = 5;

	UPROPERTY(EditDefaultsOnly, Category="Audio")
	float StopRollingPitchThreshold = 0.2;

	UPROPERTY(EditDefaultsOnly, Category="Audio")
	float PiecePlacedPitchThreshold = 5;

	private bool bIsRolling = false;
	private int LastPieceUnfolding = -1;

	float HolderRot = 0.0;

	FVector PieceRelativeOrigin;
	float PreviousDeathTraceX;
	uint PreviousDeathTraceXFrame = 0;

	bool bForceExtending = false;

	bool bBurstCooldownActive = false;
	bool bBurstSpamCounterForceActive = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BridgePieces.Empty();
		BridgePiecePitches.Empty();
		USceneComponent AttachComp = BridgeRoot;

		for (int i = 0; i < BridgePieceAmount; i++)
		{
			UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this, FName(f"BridgePiece_{i}"));
			MeshComp.AttachToComponent(AttachComp);
			if (AttachComp != BridgeRoot)
				MeshComp.SetRelativeLocation(FVector(Offset, 0.0, 0.0));

			float Pitch = bPreviewRolledOut ? 0.0 : PitchPerPiece;
			float Modifier = Math::Clamp(i * PitchModifier, 0.0, MaxPitchModifier);
			Pitch *= Modifier;
			BridgePiecePitches.Add(Pitch);

			MeshComp.SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));

			AttachComp = MeshComp;
			BridgePieces.Add(MeshComp);

			MeshComp.SetStaticMesh(MeshAsset);

			MeshComp.RemoveTag(ComponentTags::WallScrambleable);
			MeshComp.RemoveTag(ComponentTags::WallRunnable);
			MeshComp.RemoveTag(ComponentTags::LedgeGrabbable);
			MeshComp.RemoveTag(ComponentTags::LedgeClimbable);
			MeshComp.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);

			MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
			// MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
			MeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAbilityZoe, ECollisionResponse::ECR_Block);
		}

		TranslateComp.MaxX = BridgePieceAmount * (Offset - 2.5);
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetLastBridgePiece()
	{
		if (BridgePieces.IsEmpty())
			return nullptr;

		return BridgePieces[BridgePieces.Num() - 1];
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticFieldComp.OnBurst.AddUFunction(this, n"OnBurst");
		MagneticFieldComp.OnPush.AddUFunction(this, n"OnPush");

		PieceRelativeOrigin = MeshAsset.BoundingBox.Center;
	}

	UFUNCTION()
	private void OnBurst(FMagneticFieldData Data)
	{
		if (bForceExtending)
			return;

		if(!IsOriginValid(Data.ForceOrigin))
			return;

		MagneticFieldComp.ApplyBurstImpulseToFauxPhysics(Data);

		Activate();
		UMagneticFieldFoldingBridgeEventHandler::Trigger_OnBurst(this);

		if (bBurstCooldownActive)
			bBurstSpamCounterForceActive = true;

		bBurstCooldownActive = true;

		Timer::SetTimer(this, n"ResetBurstCooldown", 1.0);
	}

	UFUNCTION()
	private void ResetBurstCooldown()
	{
		bBurstCooldownActive = false;
		bBurstSpamCounterForceActive = false;
	}

	UFUNCTION()
	private void OnPush(FMagneticFieldData Data)
	{
		if (bForceExtending)
			return;

		if(!IsOriginValid(Data.ForceOrigin))
			return;

		MagneticFieldComp.ApplyRepelForceToFauxPhysics(Data);

		Activate();
	}

	private bool IsOriginValid(FVector Origin) const
	{
		if(!bOneSided)
			return true;

		FPlane BridgePlane = FPlane(ActorLocation, ActorUpVector);
		if(BridgePlane.PlaneDot(Origin) < 0)
			return false;

		return true;
	}

	UFUNCTION()
	void ForceExtend()
	{
		bForceExtending = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bBurstSpamCounterForceActive)
			TranslateComp.ApplyForce(TranslateComp.WorldLocation, TranslateComp.ForwardVector * -25000.0);

		FBox RollBounds;
		TickPieces(DeltaTime, RollBounds);

		if(!RollBounds.Extent.IsNearlyZero())
		{
			TickPlayerOverlap(DeltaTime, RollBounds);
		}
	}

	private void TickPieces(float DeltaTime, FBox&out OutRollBounds)
	{
		const float TranslationAlpha = TranslateComp.RelativeLocation.X / TranslateComp.MaxX;

		if (bForceExtending)
			TranslateComp.ApplyForce(TranslateComp.WorldLocation, TranslateComp.ForwardVector * Math::Lerp(5000.0, 30000.0, TranslationAlpha));

		bool bAllPiecesHaveReverted = true;
		float AnyPitchChanges = 0;
		float TotalPitch = 0;

		for (int i = 0; i < BridgePieces.Num(); i++)
		{
			const float AlphaPerPiece = 1.0 / BridgePieces.Num();
			const float PieceAlphaStart = i * AlphaPerPiece;
			const float PieceAlphaEnd = PieceAlphaStart + AlphaPerPiece;

			// We use an alpha to set the target pitch instead of a hard cutoff to prevent snapping rotations
			const float PieceAlpha = Math::NormalizeToRange(TranslationAlpha, PieceAlphaStart, PieceAlphaEnd);
			const float TargetPitch = Math::Lerp(BridgePiecePitches[i], 0, Math::Saturate(PieceAlpha));

			const float CurrentPitch = BridgePieces[i].RelativeRotation.Pitch;
			const float Pitch = Math::FInterpTo(CurrentPitch, TargetPitch, DeltaTime, 4.0);
			
			TotalPitch += Pitch;

			if (PieceAlpha > 0)
			{
				// Extending Piece

				if(Pitch > SLEEP_THRESHOLD)
					bAllPiecesHaveReverted = false;

				AnyPitchChanges += Math::Abs(CurrentPitch - Pitch);
				BridgePieces[i].SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));

				if (Math::IsNearlyZero(Pitch, PiecePlacedPitchThreshold) && i - 1 == LastPieceUnfolding)
				{
					LastPieceUnfolding = i;
					UMagneticFieldFoldingBridgeEventHandler::Trigger_PiecePlaced(this);
				}
			}
			else
			{
				// Reverting piece

				if(TotalPitch > 50)
				{
					// This piece is rolled up, and could potentially kill the player
					// Add it's bounds to the roll bounds
					FBox Bounds = BridgePieces[i].GetBoundingBoxRelativeToOwner();

					if(OutRollBounds.Equals(FBox()))
						OutRollBounds = Bounds;
					else
						OutRollBounds += Bounds;
				}

				if(Pitch < TargetPitch - SLEEP_THRESHOLD)
					bAllPiecesHaveReverted = false;

				AnyPitchChanges += Math::Abs(CurrentPitch - Pitch);
				BridgePieces[i].SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));

				if (!Math::IsNearlyZero(Pitch, 0.01) && i == LastPieceUnfolding)
				{
					LastPieceUnfolding = i - 1;
					UMagneticFieldFoldingBridgeEventHandler::Trigger_PieceRetracted(this);
				}
			}
		}

		if (AnyPitchChanges < StopRollingPitchThreshold && bIsRolling)
		{
			bIsRolling = false;
			UMagneticFieldFoldingBridgeEventHandler::Trigger_StopRolling(this);
		}
		else if (!bIsRolling && AnyPitchChanges > StartRollingPitchThreshold)
		{
			bIsRolling = true;
			UMagneticFieldFoldingBridgeEventHandler::Trigger_StartRolling(this);
		}

		float HolderTargetRot = TranslateComp.RelativeLocation.X < 5.0 ? 0.0 : 45.0;
		HolderRot = Math::FInterpTo(HolderRot, HolderTargetRot, DeltaTime, 16.0);
		// LeftHolder.SetRelativeRotation(FRotator(0.0, 180.0, HolderRot));
		// RightHolder.SetRelativeRotation(FRotator(0.0, 0.0, HolderRot));

		if(bAllPiecesHaveReverted && TranslateComp.RelativeLocation.X < SLEEP_THRESHOLD)
			Deactivate();
	}

	private void TickPlayerOverlap(float DeltaTime, FBox RollBounds)
	{
		// Transform roll box center to world space
		const FVector DeathTraceLocation = ActorTransform.TransformPositionNoScale(FVector(RollBounds.Center.X, 0, RollBounds.Center.Z));

		float DeathTraceVelocity = 0;

		// If we moved last frame, calculate our velocity
		if(PreviousDeathTraceXFrame == Time::FrameNumber - 1)
			DeathTraceVelocity = (RollBounds.Center.X - PreviousDeathTraceX) / DeltaTime;

		PreviousDeathTraceXFrame = Time::FrameNumber;
		PreviousDeathTraceX = RollBounds.Center.X;

		// Check if we are moving fast enough to kill
		if(Math::Abs(DeathTraceVelocity) < KillVelocityThreshold)
			return;

		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			// Check if the player is below the bridge, then don't kill them
			const FPlane FloorPlane = FPlane(ActorLocation, ActorUpVector);
			if(FloorPlane.PlaneDot(Player.ActorCenterLocation) < 0)
				continue;

			// Check if the player is in front of the moving direction, if behind the moving direction, don't kill
			const FPlane VelocityPlane = FPlane(DeathTraceLocation, ActorForwardVector * Math::Sign(DeathTraceVelocity));
			if(VelocityPlane.PlaneDot(Player.ActorCenterLocation) < 0)
				continue;

			auto TraceSettings = Trace::InitAgainstComponent(Player.CapsuleComponent);
			TraceSettings.UseBoxShape(RollBounds.Extent, ActorQuat);
			//TraceSettings.DebugDrawOneFrame();

			FOverlapResult Overlap = TraceSettings.QueryOverlapComponent(DeathTraceLocation);
			if(Overlap.Actor == nullptr)
				continue;

			Player.KillPlayer();
		}
	}

	private void Activate()
	{
		SetActorTickEnabled(true);
	}

	private void Deactivate()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void EnableTick()
	{
		bIsRolling = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SnapFoldedOut()
	{
		SetActorTickEnabled(false);
		for (USceneComponent Piece : BridgePieces)
		{
			Piece.SetRelativeRotation(FRotator::ZeroRotator);
		}
	}
}
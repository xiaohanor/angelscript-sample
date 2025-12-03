event void FMotherKiteEvent();

class AMotherKite : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent KiteRoot;

	UPROPERTY(DefaultComponent, Attach = KiteRoot)
	USceneComponent KiteHoverRoot;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent KiteTiltRoot;

	UPROPERTY(DefaultComponent, Attach = KiteTiltRoot)
	USphereComponent CollectTrigger;

	UPROPERTY(DefaultComponent, Attach = KiteTiltRoot)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocationComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotationComp;

	UPROPERTY()
	FMotherKiteEvent OnEnoughCompanionsCollected;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FlyCameraShake;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat AlphaScaleCurve;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	FSplinePosition SplinePos;
	float CurrentSplineOffset = 0.0;
	float MaxSplineOffset = 1200.0;

	float MoveSpeed = 1800.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve TiltCurve;
	float CurrentTilt = 0.0;
	float MaxTilt = 12.0;
	float MaxTiltAffectRange = 500.0;

	float MaxStrafeSpeed = 600.0;
	float StrafeDecelerationOffset = 500.0;
	FHazeAcceleratedFloat AccStrafeSpeed;

	bool bFlying = false;

	bool bSinglePlayerModeActive = false;

	UPROPERTY(EditAnywhere)
	bool bTrapped = false;

	float HoverHeight = 75.0;

	UPROPERTY(NotEditable, NotVisible)
	TArray<UArrowComponent> CompanionTargetComps;
	int CompanionsCollected = 0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMotherKiteCompanion> CompanionClass;

	int CompanionWidth = 4;
	int CompanionHeight = 7;
	float CompanionBackOffset = -1200.0;
	float CompanionInitialSideOffset = 350.0;
	float CompanionSideOffset = 70.0;
	float CompanionSideOffsetPerColumn = 100.0;
	float CompanionForwardOffsetPerColumn = 150.0;
	int CompanionsPerCluster = 4;

	bool bEnoughCompanionsCollected = false;

	bool bPlayerControlled = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bool bLeftSide = true;
		for (int X = 0; X < CompanionHeight; ++X)
		{
			for (int Y = 0; Y < CompanionWidth * 2; ++Y)
			{
				bLeftSide = !bLeftSide;
				float InitialSideOffset = bLeftSide ? -CompanionInitialSideOffset : CompanionInitialSideOffset;
				float SideOffsetPerColumn = bLeftSide ? -CompanionSideOffsetPerColumn : CompanionSideOffsetPerColumn;
				float SideOffset = bLeftSide ? -CompanionSideOffset : CompanionSideOffset;
				
				UArrowComponent ArrowComp = UArrowComponent::Create(this);
				ArrowComp.AttachToComponent(KiteHoverRoot);
				FVector Loc = FVector::ZeroVector;
				Loc.X = CompanionBackOffset + (X * CompanionForwardOffsetPerColumn);
				Loc.Y  = InitialSideOffset + (Y * SideOffset) + (X * SideOffsetPerColumn);
				ArrowComp.SetRelativeLocation(Loc);
				ArrowComp.SetArrowSize(3.0);
				CompanionTargetComps.Add(ArrowComp);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	void Rescue()
	{
		bTrapped = false;
	}

	UFUNCTION()
	void StartFlying(ASplineActor Spline = nullptr)
	{
		if (Spline != nullptr)
			FollowSpline = Spline;
		
		SplinePos = FSplinePosition(FollowSpline.Spline, FollowSpline.Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation), true);
		bTrapped = false;
		bFlying = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(FlyCameraShake, this);
	}

	UFUNCTION()
	void ActivateSinglePlayerMode()
	{
		bSinglePlayerModeActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bTrapped)
		{
			float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 12.0) * 0.2);
			float Pitch = Math::DegreesToRadians(Math::Cos(Time::GameTimeSeconds * 16.0) * 0.2);
			FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);
			KiteRoot.SetRelativeRotation(Rotation);
		}

		if (bFlying)
		{
			UHazeMovementComponent MioMoveComp = UHazeMovementComponent::Get(Game::Mio);
			FVector MioRelativeLoc = ActorTransform.InverseTransformPosition(Game::Mio.ActorLocation);
			if (MioMoveComp.GroundContact.Actor != this)
				MioRelativeLoc = FVector::ZeroVector;
			float MioAlpha = Math::GetMappedRangeValueClamped(FVector2D(-MaxTiltAffectRange, MaxTiltAffectRange), FVector2D(-0.5, 0.5), MioRelativeLoc.Y);

			UHazeMovementComponent ZoeMoveComp = UHazeMovementComponent::Get(Game::Zoe);
			FVector ZoeRelativeLoc = ActorTransform.InverseTransformPosition(Game::Zoe.ActorLocation);
			if (ZoeMoveComp.GroundContact.Actor != this)
				ZoeRelativeLoc = FVector::ZeroVector;
			float ZoeAlpha = Math::GetMappedRangeValueClamped(FVector2D(-MaxTiltAffectRange, MaxTiltAffectRange), FVector2D(-0.5, 0.5), ZoeRelativeLoc.Y);

			float TotalAlpha = AlphaScaleCurve.GetFloatValue(MioAlpha + ZoeAlpha);
			if (bSinglePlayerModeActive)
				TotalAlpha = MioAlpha * 2.0;

			if (!bPlayerControlled)
				TotalAlpha = 0.0;

			float TargetTilt = Math::Lerp(0.0, MaxTilt, TiltCurve.GetFloatValue(TotalAlpha));
			CurrentTilt = Math::FInterpTo(CurrentTilt, TargetTilt, DeltaTime, 2.0);
			KiteTiltRoot.SetRelativeRotation(FRotator(0.0, 0.0, CurrentTilt));

			if (HasControl())
			{
				float TargetStrafeSpeed = Math::Lerp(0.0, MaxStrafeSpeed, TotalAlpha);

				int MoveDirection = TargetStrafeSpeed > 0.0 ? 1 : -1;
				float StrafeSpeedMultiplier = 1.0;
				if (MoveDirection == -1)
					StrafeSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(-MaxSplineOffset, -MaxSplineOffset + StrafeDecelerationOffset), FVector2D(0.0, 1.0), CurrentSplineOffset);
				else if (MoveDirection == 1)
					StrafeSpeedMultiplier = Math::GetMappedRangeValueClamped(FVector2D(MaxSplineOffset, MaxSplineOffset - StrafeDecelerationOffset), FVector2D(0.0, 1.0), CurrentSplineOffset);

				AccStrafeSpeed.AccelerateTo(TargetStrafeSpeed * StrafeSpeedMultiplier, 1.0, DeltaTime);

				FVector DeltaMove = (ActorForwardVector * MoveSpeed) + (ActorRightVector * AccStrafeSpeed.Value);

				if (FollowSpline != nullptr)
				{
					SplinePos.Move(MoveSpeed * DeltaTime);
					if (bPlayerControlled)
						CurrentSplineOffset += AccStrafeSpeed.Value * DeltaTime;
					else
						CurrentSplineOffset = Math::FInterpConstantTo(CurrentSplineOffset, 0.0, DeltaTime, 300.0);
					CurrentSplineOffset = Math::Clamp(CurrentSplineOffset, -MaxSplineOffset, MaxSplineOffset);
					FVector Loc = SplinePos.WorldLocation;
					FRotator Rot = SplinePos.WorldRotation.Rotator();
					Loc += Rot.RightVector * CurrentSplineOffset;
					SetActorLocationAndRotation(Loc, Rot);

					SyncedLocationComp.SetValue(Loc);
					SyncedRotationComp.SetValue(Rot);
				}
			}
			else
			{
				SetActorLocationAndRotation(SyncedLocationComp.Value, SyncedRotationComp.Value);
			}

			float Time = Time::GameTimeSeconds;

			float Pitch = Math::Sin((Time + 1.0) * 1.0) * 2.0;
			KiteHoverRoot.SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));

			float ZOffset = Math::Sin(Time * 1.0) * HoverHeight;
			FVector Offset = (FVector(0.0, 0.0, ZOffset));
			KiteHoverRoot.SetRelativeLocation(Offset);
		}
	}

	UFUNCTION()
	void CollectCluster(AMotherKiteCluster Cluster)
	{
		if (CompanionsCollected >= CompanionTargetComps.Num() - 1)
			return;

		Crumb_CollectCluster(Cluster);
	}

	UFUNCTION(CrumbFunction)
	void Crumb_CollectCluster(AMotherKiteCluster Cluster)
	{
		Cluster.Disperse();

		for (int i = 0; i < CompanionsPerCluster; i++)
		{
			AMotherKiteCompanion Companion = Cast<AMotherKiteCompanion>(SpawnActor(CompanionClass));
			Companion.AttachToComponent(CompanionTargetComps[CompanionsCollected]);
			Companion.Spawn();
			CompanionsCollected++;
		}

		if (CompanionsCollected >= CompanionTargetComps.Num() - 1)
		{
			EnoughCompanionsCollected();
		}
	}

	UFUNCTION(DevFunction)
	void EnoughCompanionsCollected()
	{
		if (bEnoughCompanionsCollected)
			return;

		bEnoughCompanionsCollected = true;
		bPlayerControlled = false;
		OnEnoughCompanionsCollected.Broadcast();
	}

	UFUNCTION()
	void OpenPortal(AActor Portal)
	{
		float Offset = 8000.0;
		float SplineDist = Math::Wrap(SplinePos.CurrentSplineDistance + Offset, 0.0, SplinePos.CurrentSpline.SplineLength);
		FVector Loc = SplinePos.CurrentSpline.GetWorldLocationAtSplineDistance(SplineDist);
		FRotator Rot = SplinePos.CurrentSpline.GetWorldRotationAtSplineDistance(SplineDist).Rotator();
		Portal.SetActorLocationAndRotation(Loc, Rot);
	}

	UFUNCTION(DevFunction)
	void MaxOutClusters()
	{
		for (int i = 0; i < CompanionTargetComps.Num() - 1; i++)
		{
			AMotherKiteCompanion Companion = Cast<AMotherKiteCompanion>(SpawnActor(CompanionClass));
			Companion.AttachToComponent(CompanionTargetComps[i]);
			Companion.Spawn();
			CompanionsCollected++;
		}
	}
}
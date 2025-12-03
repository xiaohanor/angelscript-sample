event void FOnArenaHydraHeadDeath();

enum ESanctuaryBossArenaHydraHead
{
	Center,
	One,
	Two,
	Three,
	Four,
	Extra
}

asset SanctuaryHydraHeadSheet of UHazeCapabilitySheet
{
	// dive emerge
	Capabilities.Add(USanctuaryBossArenaHydraHeadShouldDiveCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadDiveCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadSurfaceCapability);
	
	// attacks
	Capabilities.Add(USanctuaryBossArenaHydraHeadProjectileAttackCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadWaveAttackCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadRainAttackCapability);
	Capabilities.Add(USanctuaryBossArenaHydraCrunchPlatformCapability);
	
	// to attack - aka - player aviating towards hydra 
	Capabilities.Add(USanctuaryBossArenaHydraHeadToAttackCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadToAttackProjectileCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadToAttackBiteCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadToAttackAnticipateSequenceCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadToAttackIncomingStrangleCapability);

	// deathening
	Capabilities.Add(USanctuaryBossArenaHydraHeadFreeStrangleCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadFriendDeathCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadKilledCapability);

	// feedback
	Capabilities.Add(USanctuaryBossArenaHydraFadeInEmissiveFaceCapability);
	Capabilities.Add(USanctuaryBossArenaHydraFadeOutEmissiveFaceCapability);

	Capabilities.Add(USanctuaryBossArenaHydraHeadExtraLookCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadCenterLookCapability);
	Capabilities.Add(USanctuaryBossArenaHydraHeadExtraAttackCapability);
};

class ASanctuaryBossArenaHydraHead : AHazeActor
{
	FOnArenaHydraHeadDeath OnHeadDeath;

	UPROPERTY(EditInstanceOnly)
	ESanctuaryBossArenaHydraHead HeadID;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComponent;

	UPROPERTY(DefaultComponent, Attach = OffsetComponent)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent HeadPivot;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	USceneComponent LaunchPivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	USceneComponent SubmergedHeadPivot;

	UPROPERTY(DefaultComponent)
    UHazeMeshPoseDebugComponent MeshPoseDebugComponent;

	UPROPERTY(DefaultComponent, Attach = BasePivot) 
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.RelativeScale3D = FVector::OneVector * 0.7;

	UPROPERTY(EditAnywhere)
	USkeletalMesh DecapitatedSkeletalMesh;
	USkeletalMesh NormalSkeletalMesh;

	UPROPERTY(EditAnywhere)
	FName SpitProjectileName = n"Tongue8";  // This might be totally whack, feel free to change

	UPROPERTY(EditAnywhere)
	FName DecapitationBoneName = n"Spine43"; // This might be totally whack, feel free to change
	FName DecapitationMioBoneName = n"Spine44";
	FName DecapitationZoeBoneName = n"Spine43";

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = "Spine43")
	USceneComponent ButtonMashAttachComponent;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossArenaDecapitatedHead DecapitatedHead = nullptr;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInstance> DecapMaterials;

	UPROPERTY(EditAnywhere)
	UMaterialInstance NormalNeckMaterial;
	UMaterialInstanceDynamic EmissiveFaceDynamicMaterial = nullptr;
	FHazeAcceleratedFloat AccEmissiveFace;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve EmissiveFaceFadeInCurve; 
	default EmissiveFaceFadeInCurve.AddDefaultKey(0.0, 0.0);
	default EmissiveFaceFadeInCurve.AddDefaultKey(0.5, 5.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve EmissiveFaceFadeOutCurve; 
	default EmissiveFaceFadeOutCurve.AddDefaultKey(0.0, 5.0);
	default EmissiveFaceFadeOutCurve.AddDefaultKey(0.1, 0.9);
	default EmissiveFaceFadeOutCurve.AddDefaultKey(2.0, 0.0);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SanctuaryHydraHeadSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	ULocomotionFeatureHydraBoss LocomotionFeature;

	FHazeRuntimeSpline RuntimeSpline;

	FTransform InitialHeadPivotRelativeTransform;
	FTransform NewHeadTransform;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer Player;

	UPlayerMovementComponent TargetPlayerMoveComp;
	AHazePlayerCharacter TargetPlayer;
	
	ESanctuaryArenaSide ArenaSide;

	UPROPERTY(EditAnywhere)
	ESanctuaryArenaSideOctant HalfSide;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossArenaHydraHead Friend;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossArenaHydraHead LaneBuddy;

	UPROPERTY(EditInstanceOnly)
	AHydraHeadStartPosRef StartPosRef;

	ASanctuaryBossArenaHydraHead OppositeBuddy;
	float MinDistanceToOpposite = 0.0;

	UPROPERTY(Category = Settings)
	UForceFeedbackEffect BiteForceFeedbackEffect;

	TArray<FInstigator> ActorsToFightBack;
	FHazeAcceleratedFloat AccFightBack;

	float SubmergedDepth = -15000.0;
	
	FSanctuaryBossHeadStates LocalHeadState;
	private FSanctuaryBossHeadStates SyncedHeadState;

	float AttackPitch = 0.0;

	UPROPERTY()
	bool bTargetIsFlying = false;

	UPROPERTY()
	bool bTargetIsIncoming = true;

	UPROPERTY()
	bool bIsTargeted = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryBossArenaHydraProjectile> ProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryBossArenaHydraToAttackProjectile> ToAttackProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryBossArenaHydraRainProjectile> RainProjectileClass;

	FHazeAcceleratedRotator AccTrackPlayerRotator;

	USanctuaryCompanionAviationPlayerComponent ZoePlayerAviationComp;
	USanctuaryCompanionAviationPlayerComponent MioPlayerAviationComp;
	USanctuaryCompanionAviationPlayerComponent TargetPlayerAviationComp;

	FHazeAcceleratedVector AccActorLocation;
	FVector OriginalActorLocation;
	FHazeAcceleratedRotator AccActorRot;
	FRotator OriginalActorRot;

	FHazeAcceleratedVector AccHeadLocation;
	FHazeAcceleratedRotator AccHeadRot;
	FRotator OriginalHeadRot;

	FVector OverrideTargetHeadWorldLocation;
	FVector OverrideTargetHeadWorldLookDirection;
	FVector OriginalHeadRelativeLocation;
	FVector OriginalHeadWorldLocation;

	bool bAntiClimaxPhase = false;
	FHazeAcceleratedFloat AccAntiClimaxRise;

	ASanctuaryBossArenaHydra ParentBody;
	ASanctuaryBossArenaManager OrigoActor;
	FVector RightSideRelativeToOrigo;
	FVector LeftSideRelativeToOrigo;

	FTransform TransformBeforeSequencer;

	//Hannes ugly code
	int LaunchedProjectiles = 0;

	float CheckCruncyPlatformsCooldown = 0.0;
	bool bIsCutsceneDisabled = false;

	TArray<ASanctuaryBossArenaFloatingPlatform> PlatformsToCrunchQueue;

	UArenaHydraSettings GetSettings() property
	{
		return Cast<UArenaHydraSettings>(
			GetSettings(UArenaHydraSettings)
		);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialHeadPivotRelativeTransform = HeadPivot.RelativeTransform;
		NormalSkeletalMesh = SkeletalMesh.SkeletalMeshAsset;
		OriginalActorLocation = StartPosRef != nullptr ? StartPosRef.ActorLocation : ActorLocation;
		AccActorLocation.SnapTo(OriginalActorLocation);

		auto SelectedPlayers = Game::GetPlayersSelectedBy(Player);

		if (SelectedPlayers.Num() > 0)
		{
			TargetPlayer = Game::GetPlayersSelectedBy(Player).Last();
			SetActorControlSide(TargetPlayer);
		}

		AccTrackPlayerRotator.SnapTo(GetActorRotation());
		OriginalActorRot = BasePivot.WorldRotation;
		OriginalHeadRot = HeadPivot.WorldRotation;
		AccActorRot.SnapTo(OriginalActorRot);
		AccHeadRot.SnapTo(OriginalHeadRot);
		OriginalHeadRelativeLocation = HeadPivot.RelativeLocation;
		OriginalHeadWorldLocation = HeadPivot.WorldLocation;
		AccHeadLocation.SnapTo(OriginalHeadWorldLocation);
		DisableDecapHead();

		SetupEmissiveFaceMaterial();
	}

	void SetupEmissiveFaceMaterial()
	{
		if (SkeletalMesh.NumMaterials == 0)
			return;
		EmissiveFaceDynamicMaterial = Material::CreateDynamicMaterialInstance(this, SkeletalMesh.GetMaterial(0));
		SkeletalMesh.SetMaterial(0, EmissiveFaceDynamicMaterial);
		EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * EmissiveFaceFadeInCurve.GetFloatValue(0.0));
	}

	bool ShouldHaveEmissiveFace() const
	{
		if (LocalHeadState.bShouldLaunchProjectile)
			return true;
		if (LocalHeadState.bToAttackProjectile)
			return true;
		if (LocalHeadState.bRainAttack)
			return true;
		return false;
	}

	void BelatedSetup()
	{
		if (TargetPlayer != nullptr)
			SetupAviationListening();

		if (ZoePlayerAviationComp == nullptr && Game::Zoe != nullptr)
			ZoePlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Zoe);
		if (MioPlayerAviationComp == nullptr && Game::Mio != nullptr)
			MioPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Game::Mio);

		if (OrigoActor == nullptr)
		{
			TListedActors<ASanctuaryBossArenaManager> OrigoActors;
			if (ensure(OrigoActors.Num() == 1, "Found more or less than one ASanctuaryBossArenaManager!"))
				OrigoActor = OrigoActors[0];
			
			if (ArenaSide == ESanctuaryArenaSide::Right)
			{
				RightSideRelativeToOrigo = StartPosRef.ActorLocation - OrigoActor.ActorLocation;
				LeftSideRelativeToOrigo = RightSideRelativeToOrigo * FVector(-1.0, -1.0, 1.0);
			}
			else
			{
				LeftSideRelativeToOrigo = StartPosRef.ActorLocation - OrigoActor.ActorLocation;
				RightSideRelativeToOrigo = LeftSideRelativeToOrigo * FVector(-1.0, -1.0, 1.0);
			}
		}
		
		if (OppositeBuddy == nullptr)
		{
			TListedActors<ASanctuaryBossArenaHydraHead> Heads;
			for (auto Head : Heads)
			{
				if (Head.HeadID == ESanctuaryBossArenaHydraHead::Center)
					continue;
				if (Head.HeadID == ESanctuaryBossArenaHydraHead::Extra)
					continue;
				if (Head == this)
					continue;
				if (Head == LaneBuddy)
					continue;
				OppositeBuddy = Head;
				MinDistanceToOpposite = (OppositeBuddy.StartPosRef.ActorLocation - StartPosRef.ActorLocation).Size();
			}
		}
	}

	FString GetHydraNumber() const
	{
		FString NameNumber = FString("" + GetName());
		NameNumber = NameNumber.RightChop(NameNumber.Len() -1);
		return NameNumber;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!LocalHeadState.Equals(SyncedHeadState) && HasControl())
			CrumbSyncHeadState(LocalHeadState);

		TemporalLogging();

		if (bIsCutsceneDisabled)
			return;

		if (SanctuaryHydraDevToggles::Drawing::PrintHydraTarget.IsEnabled())
		{
			FVector NumberLocation = HeadPivot.WorldLocation; 
			NumberLocation.Z += 500.0;
			Debug::DrawDebugString(NumberLocation, GetHydraNumber(), ColorDebug::Flaxen);
		}

		if (ActorsToFightBack.Num() > 0)
			AccFightBack.AccelerateTo(1.0, 3.0, DeltaSeconds);
		else
			AccFightBack.AccelerateTo(0.0, 2.0, DeltaSeconds);

		BelatedSetup();
		UpdateLocationsAndRotations(DeltaSeconds);
		UpdateMeshSpline();

		CheckCruncyPlatformsCooldown -= DeltaSeconds;
		if (HasControl() && CheckCruncyPlatformsCooldown < 0.0 && HeadID != ESanctuaryBossArenaHydraHead::Center && HeadID != ESanctuaryBossArenaHydraHead::Extra)
		{
			CheckCruncyPlatformsCooldown = 0.2;
			CheckCruncyTargets();
		}
	}

	private void TemporalLogging()
	{
#if EDITOR
		if (TargetPlayer != nullptr)
		{
			FString HydraCategory = "Hydra " + GetHydraNumber() + " ";
			TEMPORAL_LOG(this, "Hydra Arena").Value(HydraCategory + "Quad Side", ArenaSide);
			TEMPORAL_LOG(this, "Hydra Arena").Sphere("HeadPivotLocation", HeadPivot.WorldLocation, 500.0, ColorDebug::Ruby, 5.0);
			
		}
#endif
	}

	private void CheckCruncyTargets()
	{
		TArray<ASanctuaryBossArenaHydraTarget> Targets = TListedActors<ASanctuaryBossArenaHydraTarget>().GetArray();
		for (int iTarget = 0; iTarget < Targets.Num(); ++iTarget)
		{
			bool bHydraIsTargetingZoe = TargetPlayer != nullptr && TargetPlayer.IsZoe();
			if (Targets[iTarget].FloatingPlatform.bIsOnZoeSide != bHydraIsTargetingZoe)
				continue;
			if (Targets[iTarget].HalfHydraTargeting != HalfSide)
				continue;
			if (!Targets[iTarget].bCruncyTarget || Targets[iTarget].bCruncyTargeted)
				continue;
			Targets[iTarget].bCruncyTargeted = true;
			CrumbAddCrunchTarget(Targets[iTarget].FloatingPlatform);
			break;
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAddCrunchTarget(ASanctuaryBossArenaFloatingPlatform Platformy)
	{
		if (!PlatformsToCrunchQueue.Contains(Platformy))
			PlatformsToCrunchQueue.Add(Platformy);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSyncHeadState(FSanctuaryBossHeadStates NewState)
	{
		SyncedHeadState = NewState;
	}

	const FSanctuaryBossHeadStates& GetReadableState() const
	{
		return SyncedHeadState;
	}

	void UpdateLocationsAndRotations(float DeltaSeconds)
	{
		if (TargetPlayer != nullptr)
		{
			if (ShouldTrackPlayer())
			{
				FVector ToTargetActor = TargetPlayer.ActorLocation - OrigoActor.ActorLocation;
				ToTargetActor.Z = 0.0;
				FVector FromHeadToTargetActor = TargetPlayer.ActorLocation - HeadPivot.WorldLocation;
				FRotator ToPlayerRot = FRotator::MakeFromXZ(ToTargetActor.GetSafeNormal(), FVector::UpVector);
				FRotator FromHeadToPlayerRot = FRotator::MakeFromXZ(FromHeadToTargetActor.GetSafeNormal(), FVector::UpVector);
				AccActorRot.AccelerateTo(ToPlayerRot, 3.0, DeltaSeconds);
				AccHeadRot.AccelerateTo(FromHeadToPlayerRot, 0.8, DeltaSeconds);

				FVector NewDesiredTarget;
				bool bOtherBuddyIsClose = false;
				if (IsAnyPlayerAviating())
					NewDesiredTarget = OriginalActorLocation;
				else
				{
					NewDesiredTarget = OrigoActor.ActorLocation + ToTargetActor.GetSafeNormal() * RightSideRelativeToOrigo.Size();
					FRotator OurArenaRotation = FRotator::MakeFromXZ(NewDesiredTarget.GetSafeNormal(), FVector::UpVector);

					// clamp if appropriate
					FVector OrigoToOpposite = OppositeBuddy.ActorLocation - OrigoActor.ActorLocation;
					OrigoToOpposite.Z = 0.0;

					FVector ToBuddy = OppositeBuddy.ActorLocation - ActorLocation;
					float DistanceToBuddy = ToBuddy.Size();
					bOtherBuddyIsClose = DistanceToBuddy < 8000.0;
					
					if (SanctuaryHydraDevToggles::Drawing::PrintHydraTarget.IsEnabled())
					{
						Debug::DrawDebugString(ActorLocation + ToBuddy * 0.5, "Dist " + DistanceToBuddy, ColorDebug::Grapefruit);
					}

					if (bOtherBuddyIsClose)
					{
						// see the arena as a rotation around Z. We figure out which yaw direction we have, and then we know our yaw +-45 degrees is our "max" allowed location
						FVector OrigoToOurQuadCenter = OriginalActorLocation - OrigoActor.ActorLocation;
						OrigoToOurQuadCenter.Z = 0.0;
						FRotator OurCenterRotation = FRotator::MakeFromXZ(OrigoToOurQuadCenter.GetSafeNormal(), FVector::UpVector);
						const float MaxAllowedDeviationAngle = 25.0;
						float CClockwiseYaw = Math::Wrap(OurCenterRotation.Yaw - MaxAllowedDeviationAngle, 0.0, 360.0);
						float ClockwiseYaw = Math::Wrap(OurCenterRotation.Yaw + MaxAllowedDeviationAngle, 0.0, 360.0);
						float NewYaw = Math::ClampAngle(OurArenaRotation.Yaw, CClockwiseYaw, ClockwiseYaw);

						if (SanctuaryHydraDevToggles::Drawing::PrintHydraTarget.IsEnabled())
						{
							const float ArenaSize = 10000.0;
							Debug::DrawDebugLine(OrigoActor.ActorLocation, OrigoActor.ActorLocation + FRotator(0.0, CClockwiseYaw, 0.0).ForwardVector * ArenaSize, ColorDebug::Cerulean, 20.0, 0.0, true);
							Debug::DrawDebugLine(OrigoActor.ActorLocation, OrigoActor.ActorLocation + FRotator(0.0, ClockwiseYaw, 0.0).ForwardVector * ArenaSize, ColorDebug::Carmine, 20.0, 0.0, true);
						}

						FRotator ClampedArenaRotationDirection(0.0, NewYaw, 0.0);

						NewDesiredTarget = OrigoActor.ActorLocation + ClampedArenaRotationDirection.ForwardVector * OrigoToOurQuadCenter.Size();
					}
				}

				AccActorLocation.AccelerateTo(NewDesiredTarget, 0.8, DeltaSeconds);

				if (SanctuaryHydraDevToggles::Drawing::PrintHydraTarget.IsEnabled())
				{
					FString PlayerName = TargetPlayer.IsMio() ? "Mio" : "Zoe" ;
					FVector TrackingLocation = HeadPivot.WorldLocation; 
					TrackingLocation.Z += 200.0;
					Debug::DrawDebugString(TrackingLocation, "Tracking " + PlayerName, ColorDebug::Grapefruit);
					Debug::DrawDebugSphere(NewDesiredTarget, 500.0, 12, ColorDebug::Saffron, 10.0, 0.0, true);
					Debug::DrawDebugLine(OppositeBuddy.ActorLocation, ActorLocation, bOtherBuddyIsClose ? ColorDebug::Ruby : ColorDebug::Leaf, 10.0, 0.0, true);
				}
			}
			else
			{
				AccActorRot.AccelerateTo(OriginalActorRot, 0.3, DeltaSeconds);
				AccHeadRot.AccelerateTo(OriginalHeadRot, 0.8, DeltaSeconds);
				AccActorLocation.AccelerateTo(OriginalActorLocation, 0.8, DeltaSeconds);
			}

			if (StartPosRef != nullptr && SanctuaryHydraDevToggles::Drawing::DrawHydraCoords.IsEnabled())
			{
				Debug::DrawDebugString(HeadPivot.WorldLocation, "" + GetHydraNumber(), ColorDebug::Flaxen);
				Debug::DrawDebugString(StartPosRef.ActorLocation, "Start Loc: " + GetHydraNumber(), ColorDebug::Flaxen);
				Debug::DrawDebugSphere(StartPosRef.ActorLocation, 500.0, 12, ColorDebug::Rainbow(2.0), 10.0, 0.0, true);
			}

			SetActorLocation(AccActorLocation.Value);
		}
		else if (ParentBody != nullptr && OrigoActor != nullptr) // auto positioning in center
		{
			// Try find position between other heads
			FVector AvaragePosition;
			for (auto Head : ParentBody.HydraHeads)
			{
				if (Head.HeadID == ESanctuaryBossArenaHydraHead::Center || Head.HeadID == ESanctuaryBossArenaHydraHead::Extra)
					continue;

				FVector FromOrigoPos = Head.ActorLocation - OrigoActor.ActorLocation;
				AvaragePosition += FromOrigoPos.GetSafeNormal();
			}
			
			AvaragePosition.Z = 0.0;
			FRotator BetweenHeadsRot = FRotator::MakeFromXZ(AvaragePosition.GetSafeNormal(), FVector::UpVector);
			if (HeadID == ESanctuaryBossArenaHydraHead::Extra)
			{
				BetweenHeadsRot.Yaw += 35.0;
			}
			AccActorRot.AccelerateTo(BetweenHeadsRot, 5.0, DeltaSeconds);

			const float TurnHeadDuration = 3.0;
			if (OverrideTargetHeadWorldLookDirection.Size() > KINDA_SMALL_NUMBER)
				AccHeadRot.AccelerateTo(FRotator::MakeFromXZ(OverrideTargetHeadWorldLookDirection, FVector::UpVector), TurnHeadDuration, DeltaSeconds);
			else
				AccHeadRot.AccelerateTo(ActorRotation, TurnHeadDuration, DeltaSeconds);
			HeadPivot.SetWorldRotation(AccHeadRot.Value);
		}

		if (SanctuaryHydraDevToggles::Drawing::DrawHydraCoords.IsEnabled())
		{
			FVector BaseLocation = ActorLocation;
			BaseLocation.Z += 500;
			// Debug::DrawDebugCoordinateSystem(ActorLocation, ActorRotation, 6000.0, 100.0, 0.0, true);
			float Thicc = 15.0;
			Debug::DrawDebugSphere(ActorLocation, 200.0, 12, ColorDebug::Cyan, Thicc, 0.0, true);
			Debug::DrawDebugLine(ActorLocation, ActorLocation + ActorRotation.ForwardVector * 6000.0, ColorDebug::Cyan, Thicc, 0.0, true);
			Debug::DrawDebugSphere(BaseLocation, 200.0, 12, ColorDebug::Magenta, Thicc, 0.0, true);
			Debug::DrawDebugLine(BaseLocation, BaseLocation + BasePivot.WorldRotation.ForwardVector * 4000.0, ColorDebug::Magenta, Thicc, 0.0, true);
			// Debug::DrawDebugCoordinateSystem(BaseLocation, BasePivot.WorldRotation, 4000.0, 75.0, 0.0, true);
			Debug::DrawDebugCoordinateSystem(HeadPivot.WorldLocation, HeadPivot.WorldRotation, 2000.0, 55.0, 0.0, true);
		}

		SetActorRotation(AccActorRot.Value);
		UpdateHeadPivotLocation(DeltaSeconds);
	}

	void UpdateHeadPivotLocation(float DeltaSeconds)
	{
		if (OverrideTargetHeadWorldLocation.Size() > 1.0)
		{
			float InterpolationDuration = Settings.HeadPivotInterpolationDuration;
			AccHeadLocation.AccelerateTo(OverrideTargetHeadWorldLocation, InterpolationDuration, DeltaSeconds);
			HeadPivot.SetWorldLocation(AccHeadLocation.Value);
		}
		else
		{
			FVector TargetWorldLocation = BasePivot.WorldLocation + BasePivot.WorldRotation.RotateVector(OriginalHeadRelativeLocation);
			float InterpolationDuration = Settings.HeadPivotInterpolationDuration;
			AccHeadLocation.AccelerateTo(TargetWorldLocation, InterpolationDuration, DeltaSeconds);
			HeadPivot.SetWorldLocation(AccHeadLocation.Value);
			// Debug::DrawDebugCoordinateSystem(TargetWorldLocation, HeadPivot.WorldRotation, 4000.0, 75.0);
			// Debug::DrawDebugCoordinateSystem(AccHeadLocation.Value, HeadPivot.WorldRotation, 4000.0, 75.0);
		}

		if (TargetPlayer != nullptr)
			HeadPivot.SetWorldRotation(AccHeadRot.Value);
	}

	void UpdateMeshSpline()
	{
		RuntimeSpline = FHazeRuntimeSpline();
		RuntimeSpline.AddPoint(BasePivot.WorldLocation);
		RuntimeSpline.AddPoint(BasePivot.WorldLocation + BasePivot.UpVector * 6000.0);
		RuntimeSpline.AddPoint(IdleTransform.Location - IdleTransform.Rotation.ForwardVector * 1000.0);
		RuntimeSpline.AddPoint(IdleTransform.Location);

		TArray<FVector> UpDirections;
		UpDirections.Add(-BasePivot.ForwardVector);
		UpDirections.Add(-BasePivot.ForwardVector + IdleTransform.Rotation.UpVector);
		UpDirections.Add(IdleTransform.Rotation.UpVector);
		UpDirections.Add(IdleTransform.Rotation.UpVector);
		RuntimeSpline.UpDirections = UpDirections;
		RuntimeSpline.SetCustomEnterTangentPoint(BasePivot.WorldLocation - BasePivot.UpVector);
		RuntimeSpline.SetCustomExitTangentPoint(IdleTransform.Location + IdleTransform.Rotation.ForwardVector);
	}

	FTransform GetIdleTransform() const property
	{
		FTransform WorldTransform = HeadPivot.WorldTransform;
		FVector IdleLocation = WorldTransform.Location;
		FQuat IdleRotation = WorldTransform.Rotation;

		float LocationOffsetScale = 0.5;
		float RotationOffsetScale = 0.5;

		float UniqueNumber = ActorLocation.X + ActorLocation.Y;

		FVector LocationOffset = FVector(
			Math::Cos(UniqueNumber + Time::GameTimeSeconds * 0.25) * 1000.0 * LocationOffsetScale,
			0.0,
			Math::Sin(UniqueNumber - Time::GameTimeSeconds) * 500.0 * LocationOffsetScale
		);

		FQuat RotationOffset = FRotator(
			Math::Cos(UniqueNumber + Time::GameTimeSeconds) * 5.0 * RotationOffsetScale + AttackPitch,
			Math::Sin(UniqueNumber - Time::GameTimeSeconds * 0.65) * 10.0 * RotationOffsetScale,
			Math::Sin(UniqueNumber + Time::GameTimeSeconds * 0.5) * 10.0 * RotationOffsetScale,
		).Quaternion();

		IdleRotation *= RotationOffset.Inverse();
		IdleLocation += LocationOffset;

		return FTransform(
			IdleRotation,
			IdleLocation
		);
	}

	FTransform LerpTransform(FTransform A, FTransform B, float Alpha)
	{
		FTransform LerpedTransform;
		LerpedTransform.Location = Math::Lerp(A.Location, B.Location, Alpha);
		LerpedTransform.Rotation = FQuat::Slerp(A.Rotation, B.Rotation, Alpha);
		LerpedTransform.Scale3D = Math::Lerp(A.Scale3D, B.Scale3D, Alpha);

		return LerpedTransform;
	}

	private void SetupAviationListening()
	{
		if (TargetPlayerAviationComp == nullptr)
		{
			TargetPlayerAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(TargetPlayer);
			if (TargetPlayerAviationComp != nullptr)
			{
				TargetPlayerAviationComp.UpdateCurrentOctant();
				TListedActors<ASanctuaryBossArenaManager> ArenaManagers;
				if (ArenaManagers.Num() == 0) // we're streaming the level probably
					return;

				ArenaSide = SanctuaryCompanionAviationStatics::GetArenaSideForLocation(ArenaManagers.Single, TargetPlayer, ActorLocation);
				TargetPlayerAviationComp.OnAttackFailed.AddUFunction(this, n"PlayerAttackFail");
				if (TargetPlayerAviationComp.CurrentQuadrantSide != ArenaSide)
					LocalHeadState.bShouldDive = true;

				TargetPlayerAviationComp.OnAviationStarted.AddUFunction(this, n"PlayerStartedFlying");
				TargetPlayerAviationComp.OnAviationStopped.AddUFunction(this, n"PlayerStoppedFlying");
				TargetPlayerAviationComp.OnArenaSideChanged.AddUFunction(this, n"PlayerChangedSide");
			}
		}
	}

	bool ShouldTrackPlayer()
	{
		const FSanctuaryBossHeadStates& ReadableState = GetReadableState();
		if (bAntiClimaxPhase)
			return false;
		if (ReadableState.bDeath)
			return false;
		// if (Friend != nullptr && Friend.bDeath)
		// 	return false;
		if (ReadableState.bMioTightenStrangle && ReadableState.bZoeTightenStrangle)
			return false;
		if (ReadableState.bMioTightenStrangle || ReadableState.bZoeTightenStrangle)
			return false;
		if (ReadableState.bMioStrangled && ReadableState.bZoeStrangled)
			return false;
		if (ReadableState.bMioStrangled || ReadableState.bZoeStrangled)
			return false;
		// if (Friend != nullptr && (Friend.bMioStrangled || Friend.bZoeStrangled))
		// 	return false;
		// if (ReadableState.bShouldSurface)
		// 	return false;
		// if (Friend != nullptr && Friend.bShouldDive)
		// 	return false;
		if (ReadableState.bShouldDive)
			return false;

		if (IsBiting())
			return false;

		bool bPlayerIsTrackable = true;
		if (TargetPlayer.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			bPlayerIsTrackable = TargetPlayerAviationComp.bIsRideReady || PlayerInTrackableState();
		if (!bPlayerIsTrackable)
			return false;

		return true;
	}

	private bool PlayerInTrackableState() const
	{
		if (TargetPlayerAviationComp.AviationState == EAviationState::SwoopingBack)
			return true;
		if (TargetPlayerAviationComp.AviationState == EAviationState::Entry)
			return true;
		if (TargetPlayerAviationComp.AviationState == EAviationState::ToAttack)
			return true;
		// if (TargetPlayerAviationComp.AviationState == EAviationState::InitAttack)
		// 	return true;
		// if (TargetPlayerAviationComp.AviationState == EAviationState::SwoopInAttack)
		// 	return true;
		return false;
	}

	bool PlayerIsInAviationSwoopback() const
	{
		return TargetPlayerAviationComp != nullptr && TargetPlayerAviationComp.AviationState == EAviationState::SwoopingBack;
	}

	bool PlayerIsInAviationEntry() const
	{
		return TargetPlayerAviationComp != nullptr && TargetPlayerAviationComp.AviationState == EAviationState::Entry;
	}

	bool IsInFriendDeath() const
	{
		if (Friend != nullptr && Friend.GetReadableState().bDeath && MyPlayerIsAviating())
			return true;
		if (TargetPlayerAviationComp != nullptr && TargetPlayerAviationComp.CurrentQuadrantSide != ArenaSide)
			return true;
		return  false;
	}

	bool MyPlayerIsAviating() const
	{
		return TargetPlayer != nullptr && TargetPlayerAviationComp != nullptr && TargetPlayerAviationComp.GetIsAviationActive();
	}

	bool IsAnyPlayerAviating() const
	{
		if (ZoePlayerAviationComp != nullptr && ZoePlayerAviationComp.GetIsAviationActive())
			return true;
		if (MioPlayerAviationComp != nullptr && MioPlayerAviationComp.GetIsAviationActive())
			return true;
		return false;
	}

	bool MyPlayerIsAttacking() const
	{
		return TargetPlayer != nullptr && TargetPlayerAviationComp != nullptr && (TargetPlayerAviationComp.AviationState == EAviationState::Attacking || TargetPlayerAviationComp.AviationState == EAviationState::TryExitAttack);
	}

	bool ExtraHeadReactAttack() const
	{
		if (HeadID != ESanctuaryBossArenaHydraHead::Extra)
			return false;
		return Friend.GetReadableState().bMioStrangled || Friend.GetReadableState().bZoeStrangled;
	}

	bool ExtraHeadReactIncoming() const
	{
		if (HeadID != ESanctuaryBossArenaHydraHead::Extra)
			return false;
		if (IsAnyPlayerAviating())
			return true;
		return false;
	}

	bool MyPlayerSuccessAttack() const
	{
		if (CompanionAviation::bCoopKill)
			return true;
		return TargetPlayer != nullptr && TargetPlayerAviationComp != nullptr && TargetPlayerAviationComp.AviationState == EAviationState::AttackingSuccessCircling;
	}

	bool IsBiting() const
	{
		const FSanctuaryBossHeadStates& ReadableState = GetReadableState();
		return ReadableState.bToAttackBiteLunge || ReadableState.bToAttackBiteDown || ReadableState.bToAttackBiteRetract;
	}

	bool IsAttacking() const
	{
		const FSanctuaryBossHeadStates& ReadableState = GetReadableState();
		return IsBiting() || ReadableState.bToAttackProjectile || ReadableState.bShouldLaunchProjectile || ReadableState.bRainAttack || ReadableState.bWaveAttack;
	}

	bool IsDying() const
	{
		const FSanctuaryBossHeadStates& ReadableState = GetReadableState();
		return ReadableState.bZoeStrangled || ReadableState.bZoeStrangled || ReadableState.bShouldDive || ReadableState.bDeath;
	}

	float GetBarProgress()
	{
		if (ZoePlayerAviationComp != nullptr && MioPlayerAviationComp != nullptr)
		{
			float TotalValue = MioPlayerAviationComp.SyncedKillValue.Value + ZoePlayerAviationComp.SyncedKillValue.Value;
			return Math::Clamp(1.0 - (TotalValue * 0.5), 0.0, 1.0);
		}
		return 0.0;
	}

	void Die()
	{
		LocalHeadState.bDeath = true;
		if (DecapitatedHead != nullptr)
		{
			SwitchToDecapNeck();
			DecapitatedHead.RemoveActorDisable(this);
			DecapitatedHead.SetActorHiddenInGame(false);
			DecapitatedHead.PlayDecapitationAnimation(this);
			Timer::SetTimer(this, n"DisableDecapHead", Settings.DeathAnimationDuration);
		}
		OnHeadDeath.Broadcast();
		Timer::SetTimer(this, n"ComebackSurface", Settings.EmergeAfterDeathDuration);
	}

	bool CanDoProjectile() const
	{
		if (GetIsIncapacitatedHead())
			return false;
		FSanctuaryBossHeadStates NoSpecialState;
		if (LocalHeadState.Equals(NoSpecialState))
			return true;
		return false;
	}

	bool GetIsIncapacitatedHead() const
	{
		return GetReadableState().bIsDecapitated || IsActorDisabled();
	}

	void SwitchToDecapNeck()
	{
		if (LocalHeadState.bIsDecapitated)
			return;
		if (DecapitatedHead == nullptr)
			return;
		LocalHeadState.bIsDecapitated = true;
		if (DecapitatedSkeletalMesh != nullptr)
		{
			SkeletalMesh.SkeletalMeshAsset = DecapitatedSkeletalMesh;
			for (int iMaterial = 0; iMaterial < DecapMaterials.Num(); ++iMaterial)
				SkeletalMesh.SetMaterial(iMaterial, DecapMaterials[iMaterial]);
		}
	}

	UFUNCTION()
	private void DisableDecapHead()
	{
		LocalHeadState.bIsDecapitated = false;
		if (DecapitatedHead != nullptr)
		{
			DecapitatedHead.AddActorDisable(this);
			DecapitatedHead.SetActorHiddenInGame(true);
		}
		if (DecapitatedSkeletalMesh != nullptr)
			SkeletalMesh.SkeletalMeshAsset = NormalSkeletalMesh;
		if (NormalNeckMaterial != nullptr && EmissiveFaceDynamicMaterial != nullptr)
		{
			SkeletalMesh.SetMaterial(0, EmissiveFaceDynamicMaterial);
			SkeletalMesh.SetMaterial(1, NormalNeckMaterial);
		}
	}

	UFUNCTION()
	private void ComebackSurface()
	{
		LocalHeadState.bShouldSurface = true;
		LocalHeadState.bDeath = false;
	}

	UFUNCTION()
	void DisableAfterTimer()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	private void PlayerStartedFlying(AHazePlayerCharacter InPlayer)
	{
		bTargetIsFlying = true;
	}

	UFUNCTION()
	private void PlayerStoppedFlying(AHazePlayerCharacter InPlayer)
	{
		bTargetIsFlying = false;
	}

	UFUNCTION()
	private void PlayerChangedSide(ESanctuaryArenaSide NewSide)
	{
		if (NewSide != ArenaSide)
			LocalHeadState.bShouldSurface = true;
	}

	UFUNCTION()
	private void PlayerAttackFail()
	{
		LocalHeadState.bShouldDive = true;
	}

	UFUNCTION()
	void ChangedSide()
	{
		LocalHeadState.bDeath = false;
		ArenaSide = ArenaSide == ESanctuaryArenaSide::Left ? ESanctuaryArenaSide::Right : ESanctuaryArenaSide::Left;
		FVector NewHeadForward = OriginalHeadRot.ForwardVector * -1.0;
		FVector NewRelative = ArenaSide == ESanctuaryArenaSide::Right ? RightSideRelativeToOrigo : LeftSideRelativeToOrigo ;
		OriginalActorLocation = OrigoActor.ActorLocation + NewRelative;
		SetActorLocation(OriginalActorLocation);
		AccActorLocation.SnapTo(OriginalActorLocation);

		PlatformsToCrunchQueue.Reset(4);

		FVector NewActorForward = NewRelative;
		NewActorForward.Z = 0.0;
		NewActorForward = NewActorForward.GetSafeNormal();
		SetActorRotation(FRotator::MakeFromXZ(NewActorForward, ActorRotation.UpVector));
		OriginalActorRot = FRotator::MakeFromXZ(NewActorForward, OriginalActorRot.UpVector);
		OriginalHeadRot = FRotator::MakeFromXZ(NewHeadForward, OriginalHeadRot.UpVector);

		AccActorRot.SnapTo(OriginalActorRot);
		AccHeadRot.SnapTo(OriginalHeadRot);

		FVector TargetWorldLocation = BasePivot.WorldLocation + BasePivot.WorldRotation.RotateVector(OriginalHeadRelativeLocation);
		AccHeadLocation.SnapTo(TargetWorldLocation);
		AccHeadLocation.Velocity = FVector::ZeroVector;

		bool bShouldNotBeDecapitated = HeadID == ESanctuaryBossArenaHydraHead::Center || HeadID == ESanctuaryBossArenaHydraHead::Extra || Settings.DeathType != EArenaHydraDeadType::Decapitated;
		if (DecapitatedSkeletalMesh != nullptr && bShouldNotBeDecapitated)
			SkeletalMesh.SkeletalMeshAsset = NormalSkeletalMesh;
	}

	UFUNCTION(DevFunction)
	void ProjectileAttack()
	{
		if (!bTargetIsFlying)
			LocalHeadState.bShouldLaunchProjectile = true;
	}

	void WaveAttack()
	{
		if (GetIsIncapacitatedHead())
			return;
		if (!bTargetIsFlying)
			LocalHeadState.bWaveAttack = true;
	}

	void RainAttack()
	{
		if (GetIsIncapacitatedHead())
			return;
		if (!bTargetIsFlying)
		{
			LocalHeadState.bRainAttack = true;
			Timer::SetTimer(this, n"LaunchRainProjectile", Settings.RainProjectileAnticipationDuration);
		}
	}

	void LaunchProjectile()
	{
		if (TargetPlayer == nullptr)
			return;

		if (DevToggleHydraPrototype::SplineRunMachineGun.IsEnabled())
			return;

		auto Targets = TListedActors<ASanctuaryBossArenaHydraTarget>();
		float ClosestDistance = BIG_NUMBER;
		ASanctuaryBossArenaHydraTarget ClosestTarget;
		if (TargetPlayerMoveComp == nullptr)
			TargetPlayerMoveComp = UPlayerMovementComponent::Get(TargetPlayer);
		FVector PlayerVelocity = TargetPlayerMoveComp.GetVelocity() * 2.0;
		FVector PredictedFutureLocation = TargetPlayer.ActorLocation + PlayerVelocity;

		if (SanctuaryHydraDevToggles::Drawing::DrawHydraProjectileTargeting.IsEnabled())
		{
			PrintToScreen("" + TargetPlayer.GetName() + " " + PlayerVelocity);
			Debug::DrawDebugLine(TargetPlayer.ActorLocation, PredictedFutureLocation, TargetPlayer.GetPlayerUIColor(), 5.0, 5.0);
		}

		for (auto Target : Targets)
		{
//			Debug::DrawDebugSphere(Target.ActorLocation, 200.0, 12, FLinearColor::Green, 3.0, 2.0);
			if (!Target.bTargetable)
				continue;

			if (Target.bProjectileTargeted)
				continue;

			float DistanceToTarget = (Target.ActorLocation - PredictedFutureLocation).Size();
			if (DistanceToTarget < ClosestDistance)
			{
				ClosestTarget = Target;
				ClosestDistance = DistanceToTarget;
			}
		}

		if (ClosestTarget == nullptr)
			return;

		if (SanctuaryHydraDevToggles::Drawing::DrawHydraProjectileTargeting.IsEnabled())
			Debug::DrawDebugSphere(ClosestTarget.ActorLocation, 100.0, 12, TargetPlayer.GetPlayerUIColor());

//		Debug::DrawDebugSphere(ClosestTarget.TargetComp.WorldLocation, 500.0, 12, FLinearColor::Red, 3.0, 2.0);
		FTransform ProjectileSpitTransform = SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location; // + ProjectileSpitTransform.Rotation.ForwardVector * 400.0;
		FVector ToTarget = ClosestTarget.TargetComp.WorldLocation - LaunchLocation;

		auto Projectile = SpawnActor(ProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		//Projectile.TargetLocation = ClosestTarget.TargetComp.WorldLocation;
		Projectile.FloatingPlatform = ClosestTarget.FloatingPlatform;
		Projectile.TargetActor = ClosestTarget;
		
		FinishSpawningActor(Projectile);

		// for (int i = 0; i < 4; i++)
		// {
		// 	auto ExtraProjectile = SpawnActor(ProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		// 	ExtraProjectile.TargetOffset = Math::GetRandomPointInCircle_YZ() * 1200.0;
		// 	ExtraProjectile.TargetActor = ClosestTarget;
		
		// 	FinishSpawningActor(ExtraProjectile);
		// }
	}

	void LaunchToAttackProjectile()
	{
		if (TargetPlayer == nullptr)
			return;

		FTransform ProjectileSpitTransform = SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		auto Projectile = SpawnActor(ToAttackProjectileClass, LaunchLocation, HeadPivot.WorldRotation, bDeferredSpawn = true);
		FVector TargetOffset = TargetPlayer.ActorForwardVector * TargetPlayerAviationComp.Settings.ToAttackForwardSpeed * Settings.ProjectileTargetSpotSecondsInFrontOfPlayer;
		TargetOffset.Z = 0.0;
		FVector NewToTarget = (TargetPlayer.ActorLocation + TargetOffset) - LaunchLocation;
		Projectile.TargetLocation = LaunchLocation + NewToTarget.GetSafeNormal() * 1000.0;// Arena is about 9k radius
		Projectile.CachedCenter = OrigoActor.ActorLocation;
		// auto Result = Math::LineSphereIntersection(TargetPlayer.ActorLocation, TargetPlayer.ActorForwardVector, 20000.0, ActorLocation, 6000.0);
		// Debug::DrawDebugLine(TargetPlayer.ActorLocation, TargetPlayer.ActorLocation + TargetPlayer.ActorForwardVector * 20000.0, ColorDebug::Leaf, 5.0, 10.0, true);
		// Debug::DrawDebugSphere(ActorLocation, 6000.0, 12, ColorDebug::Cyan, 3.0, 10.0);

		Projectile.TargetPlayer = TargetPlayer;
		FinishSpawningActor(Projectile);
	}

	void NewLaunchToAttackProjectile(FVector Direction)
	{
		if (TargetPlayer == nullptr)
			return;

		FTransform ProjectileSpitTransform = SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		FVector ToTarget = TargetPlayer.ActorLocation - LaunchLocation;
		auto Projectile = SpawnActor(ToAttackProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		Projectile.TargetLocation = LaunchLocation + Direction * 8000.0; // Arena is about 9k radius
		FinishSpawningActor(Projectile);
	}

	UFUNCTION()
	void LaunchRainProjectile()
	{
		if (RainProjectileClass == nullptr)
			return;

		FTransform ProjectileSpitTransform = SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		auto Projectile = SpawnActor(RainProjectileClass, LaunchLocation, ActorRotation, bDeferredSpawn = true);
		FVector ForwardsOffset = FVector(ActorForwardVector * Math::RandRange(0.0, 4000.0) + ActorRightVector * Math::RandRange(-1000.0, 1000.0));
		FVector UpwardsOffset = ActorUpVector * 30000.0;
		Projectile.TargetLocation = HeadPivot.WorldLocation + ForwardsOffset + UpwardsOffset;
		FinishSpawningActor(Projectile);

		//Hannes ugly loop code
		LaunchedProjectiles++;

		if (LaunchedProjectiles < 5)
			Timer::SetTimer(this, n"LaunchRainProjectile", 0.3);
		else
			LaunchedProjectiles = 0;
	}

	UFUNCTION()
	void SaveLocationBeforeSequencer()
	{
		TransformBeforeSequencer = ActorTransform;
	}

	UFUNCTION()
	void LerpBackLocationAfterSequencer()
	{
		FInstigator Instigator = this;
		FVector Location = TransformBeforeSequencer.Location;
		FRotator Rotation = TransformBeforeSequencer.Rotator();
		this.SmoothTeleportActor(Location, Rotation, Instigator, 0.2);
	}
};

AWingSuit GetWingSuitFromPlayer(AActor Player)
{
 	return UWingSuitPlayerComponent::Get(Player).WingSuit;
}

UFUNCTION()
void ActivateWingsuitCameraFromCutscene(AHazePlayerCharacter Player)
{
	auto WingSuitComp = UWingSuitPlayerComponent::Get(Player);
	WingSuitComp.Manager.ActivateWingsuitCapabilitiesForPlayer(Player);
	WingSuitComp.bActivateWingsuitCameraFromCutscene = true;
	Player.CapsuleComponent.OverrideCapsuleHalfHeight(Player.CapsuleComponent.CapsuleRadius, WingSuitComp);
	Player.MeshOffsetComponent.SnapToRelativeTransform(WingSuitComp, Player.RootOffsetComponent, FTransform(FRotator(), FVector(0.0, 0.0, -100.0)));
}

UFUNCTION()
void ActivateWingSuit(AHazePlayerCharacter OnPlayer, bool bBlockContextualPoints = false, FVector StartVelocity = FVector::ZeroVector, bool bFromCutscene = false, UWingSuitSettings OptionalSettings = nullptr, EHazeSettingsPriority SettingsPriority = EHazeSettingsPriority::Gameplay)
{
	auto WingSuitComp = UWingSuitPlayerComponent::Get(OnPlayer);
	WingSuitComp.bBlockContextualPoints = bBlockContextualPoints;
	WingSuitComp.Manager.ActivateWingsuitCapabilitiesForPlayer(OnPlayer);
	WingSuitComp.bActivateWingsuitCameraFromCutscene = false;

	#if !RELEASE
	if(WingSuitComp == nullptr)
	{
		devError("Can call ActivateWingSuit on " + OnPlayer.GetName() + ". Did you forget to add the wingsuit sheet to the level?");
		return;
	}
	#endif

	WingSuitComp.SpawnWingSuit(StartVelocity, bFromCutscene);

	if(OptionalSettings != nullptr)
	{
		OnPlayer.ApplySettings(OptionalSettings, WingSuitComp.WingSuit, SettingsPriority);
	}
}

UFUNCTION()
void DeactivateWingSuit(AHazePlayerCharacter OnPlayer)
{
	auto WingSuitComp = UWingSuitPlayerComponent::Get(OnPlayer);

	#if !RELEASE
	if(WingSuitComp == nullptr)
	{
		devError("Can call ActivateWingSuit on " + OnPlayer.GetName() + ". Did you forget to add the wingsuit sheet to the level?");
		return;
	}
	#endif

	WingSuitComp.DestroyWingSuit();
	OnPlayer.ResetMovement();
}

struct FWingSuitAnimData
{
	int ActiveBarrelRollDirection = 0;
	bool bIsGrappling = false;
	float YawTurnSpeedDegrees;
	bool bIsTransitioningToWaterski = false;
	bool bCloseToWaterSurface = false;
	bool bIsLandingOnGround = false;
	bool bIsFlyingOffRamp = false;
}

UCLASS(Abstract, HideCategories = "Activation ComponentTick Cooking Variable Disable Collision ComponentReplication")
class UWingSuitPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = WingSuit)
	TSubclassOf<AWingSuit> WingSuitClass;

	TSubclassOf<UHazeCapabilitySheet> ActiveWingSuitSheet;

	UPROPERTY(Category = WingSuit)
	UWingSuitSettings WingSuitDefaultSettings;

	UPROPERTY(Category = Animation)
	TPerPlayer<UHazeLocomotionFeatureBundle> PlayerFeatureBundle;

	UPROPERTY()
	AHazePlayerCharacter PlayerOwner;

	AWingSuit WingSuit;
	bool bWingsuitActive = false;

	UPROPERTY(Category = "Death")
	TSubclassOf<UDeathEffect> DefaultDeathEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShakeDeath;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShakeBarrelRoll;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackBarrelRoll;

	FVector CurrentCameraForward = FVector::ZeroVector;
	UHazeCrumbSyncedRotatorComponent SyncedHorizontalMovementOrientation;
	UHazeCrumbSyncedRotatorComponent SyncedInternalRotation;
	FRotator InterpedRotation;

	float LastGrappleTargetReleaseTime = 0;
	FVector2D LastGrappleReleaseSpeed = FVector2D::ZeroVector;
	int WantedBarrelRollDirection = 0;
	private int Internal_ActiveBarrelRollDirection = 0;
	bool bHasEverBarrelRolled = false;
	bool bTransitioningFromWaterski = false;
	bool bBlockContextualPoints = false;
	bool bActivateWingsuitCameraFromCutscene = false;

	FSplinePosition ClosestSplineRespawnPosition;

	float AutoSteeringTimeLeft = 0;
	AWingsuitManager Manager;

	float RubberBandSpeedBonus = 0;
    float BarrelRollCooldownTime = 0;
	float CurrentPitchOffset;
	uint FrameOfDestroyWingsuit;
	FWingSuitAnimData AnimData;
	TArray<FInstigator> TrailBlockers;
	TArray<FInstigator> RubberbandBlockers;
	uint FrameOfCreateWingsuit;
	bool bShouldRespawnInWaterski = false;
	bool bActivatedFromCutscene = false;
	bool bLerpMesh = false;
	bool bCameFromFlyingOffRamp = false;
	bool bShouldSnapCameraPostRespawn = false;
	FHazeAcceleratedFloat AccMeshOffset;
	USceneComponent RespawnInWaterskiAttachPoint;

	TInstigated<bool> bWingSuitSplineRespawningActive;
	default bWingSuitSplineRespawningActive.DefaultValue = true;

	TInstigated<bool> bDisableWingsuitOnRespawnBlock;
	default bDisableWingsuitOnRespawnBlock.DefaultValue = true;
	
	const FTransform WingsuitRelativeTransform = FTransform(FRotator(78.0, 0.0, 0.0), FVector(-20.0, 0.0, -35.0));
	UWingSuitSettings WingSuitPlayerSettings;
	UWingSuitBoundarySplineContainerComponent BoundarySplineContainer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		WingSuitPlayerSettings = UWingSuitSettings::GetSettings(PlayerOwner);
		
		WingSuit = SpawnActor(WingSuitClass, Name = FName(PlayerOwner.GetName() + "_WingSuit"), bDeferredSpawn = true);
		WingSuit.PlayerOwner = PlayerOwner;
		WingSuit.MakeNetworked(this);
		WingSuit.SetActorControlSide(PlayerOwner);
		PlayerOwner.ApplyDefaultSettings(WingSuitDefaultSettings);
		FinishSpawningActor(WingSuit);
		WingSuit.AttachToComponent(PlayerOwner.Mesh, n"Backpack");
		WingSuit.ActorRelativeTransform = WingsuitRelativeTransform;
		PlayerOwner.Mesh.AddLocomotionFeatureBundle(PlayerFeatureBundle[PlayerOwner], this);
		FrameOfCreateWingsuit = Time::FrameNumber;
		AddWingSuitTrailBlocker(this, true);

		SyncedInternalRotation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(PlayerOwner, n"SyncedWingSuitInternalRotation");
		SyncedInternalRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		SyncedHorizontalMovementOrientation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(PlayerOwner, n"SyncedHorizontalMovementOrientation");
		SyncedHorizontalMovementOrientation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		BoundarySplineContainer = UWingSuitBoundarySplineContainerComponent::GetOrCreate(Game::Mio);
	}

	// For live offsetting, don't forget to turn on tick if you want to use this
	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaSeconds)
	// {
	// 	WingSuit.ActorRelativeTransform = WingsuitRelativeTransform;
	// }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		DestroyWingSuit();
		WingSuit.DestroyActor();
		PlayerOwner.Mesh.RemoveLocomotionFeatureBundle(PlayerFeatureBundle[PlayerOwner], this);
	}

	UFUNCTION(BlueprintEvent)
	void SpawnWingSuit(FVector StartVelocity, bool bFromCutscene)
	{
		bActivatedFromCutscene = bFromCutscene;
		if(bWingsuitActive)
			return;
		
		bWingsuitActive = true;
		RemoveWingSuitTrailBlocker(this);

		// Reset animation so wingsuit will play the start animation and fold out the wings.
		//WingSuit.Mesh.ResetAllAnimation();

		PlayerOwner.CapsuleComponent.OverrideCapsuleHalfHeight(PlayerOwner.CapsuleComponent.CapsuleRadius, this);

		if(!AnimData.bIsFlyingOffRamp)
		{
			PlayerOwner.MeshOffsetComponent.SnapToRelativeTransform(this, PlayerOwner.RootOffsetComponent, FTransform(FRotator(), FVector(0.0, 0.0, -100.0)));
		}
		else
		{
			AccMeshOffset.SnapTo(0.0);
			bLerpMesh = true;
		}

		bCameFromFlyingOffRamp = AnimData.bIsFlyingOffRamp;

		PlayerOwner.BlockCapabilities(n"ShoulderTurret", this);
		PlayerOwner.SetActorVelocity(StartVelocity);

		CurrentCameraForward = PlayerOwner.ControlRotation.ForwardVector;
		AutoSteeringTimeLeft = 0.0;

		if(bBlockContextualPoints)
			PlayerOwner.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);

		AnimData.bIsFlyingOffRamp = false;
		UWingSuitEffectHandler::Trigger_OnActivateWingsuit(WingSuit);
	}

	UFUNCTION(BlueprintEvent)
	void DestroyWingSuit()
	{
		if(!bWingsuitActive)
			return;

		if(bLerpMesh)
		{
			AccMeshOffset.SnapTo(0.0);
			PlayerOwner.MeshOffsetComponent.SnapToRelativeTransform(this, PlayerOwner.RootOffsetComponent, FTransform(FRotator(), PlayerOwner.Mesh.RelativeLocation));
			PlayerOwner.Mesh.RelativeLocation = FVector::ZeroVector;
			bLerpMesh = false;
		}
		
		bShouldRespawnInWaterski = false;
		bWingsuitActive = false;
		AddWingSuitTrailBlocker(this);
		PlayerOwner.CapsuleComponent.ClearCapsuleSizeOverride(this);
		PlayerOwner.MeshOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, PlayerOwner.CapsuleComponent, 0.5);
		PlayerOwner.SetActorVelocity(FVector::ZeroVector);
		PlayerOwner.UnblockCapabilities(n"ShoulderTurret", this);
		FrameOfDestroyWingsuit = Time::FrameNumber;

		if(bBlockContextualPoints)
		{
			bBlockContextualPoints = false;
			PlayerOwner.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
		}

		UWingSuitEffectHandler::Trigger_OnDeactivateWingsuit(WingSuit);
	}

	float GetWingSuitMaxAngle() const
	{
		UWingSuitBoundarySplineComponent SplineComp = GetClosestWingSuitBoundarySplineComp();
		if(SplineComp != nullptr)
		{
			FVector2D VolumeAlpha = SplineComp.GetVolumeAlphaForLocation(PlayerOwner.ActorLocation);
			float Angle = Math::Lerp(WingSuitPlayerSettings.PitchUpMaxAngle, SplineComp.PitchUpMinMaxAngle, VolumeAlpha.Y);
			return Angle;
		}

		return WingSuitPlayerSettings.PitchUpMaxAngle;
	}

	float GetWingSuitDefaultAngle() const
	{
		float BaseDefaultAngle = 0.0;

		UWingSuitBoundarySplineComponent SplineComp = GetClosestWingSuitBoundarySplineComp();
		if(SplineComp != nullptr && SplineComp.bOffsetDefaultAngleAlso)
		{
			FVector2D VolumeAlpha = SplineComp.GetVolumeAlphaForLocation(PlayerOwner.ActorLocation);
			float Angle = Math::Lerp(WingSuitPlayerSettings.PitchUpMaxAngle, SplineComp.PitchUpMinMaxAngle, VolumeAlpha.Y);
			if(SplineComp.AngleOffsetMode == EWingSuitBoundarySplineAngleOffsetMode::Clamp)
			{
				if(BaseDefaultAngle > Angle)
					return Angle;
			}
			else if(SplineComp.AngleOffsetMode == EWingSuitBoundarySplineAngleOffsetMode::EqualOffset)
			{
				float Offset = Angle - WingSuitPlayerSettings.PitchUpMaxAngle;
				return BaseDefaultAngle + Offset;
			}
			else
				devError("Forgot to add case");
		}

		return BaseDefaultAngle;
	}

	float GetWingSuitMinAngle() const
	{
		float BaseMinAngle = -WingSuitPlayerSettings.PitchDownMaxAngle;

		UWingSuitBoundarySplineComponent SplineComp = GetClosestWingSuitBoundarySplineComp();
		if(SplineComp != nullptr && SplineComp.bOffsetMinAngleAlso)
		{
			FVector2D VolumeAlpha = SplineComp.GetVolumeAlphaForLocation(PlayerOwner.ActorLocation);
			float Angle = Math::Lerp(WingSuitPlayerSettings.PitchUpMaxAngle, SplineComp.PitchUpMinMaxAngle, VolumeAlpha.Y);
			if(SplineComp.AngleOffsetMode == EWingSuitBoundarySplineAngleOffsetMode::Clamp)
			{
				if(BaseMinAngle > Angle)
					return Angle;
			}
			else if(SplineComp.AngleOffsetMode == EWingSuitBoundarySplineAngleOffsetMode::EqualOffset)
			{
				float Offset = Angle - WingSuitPlayerSettings.PitchUpMaxAngle;
				return BaseMinAngle + Offset;
			}
			else
				devError("Forgot to add case");
		}

		return BaseMinAngle;
	}

	float GetWingSuitHorizontalSteerbackAlpha() const
	{
		UWingSuitBoundarySplineComponent SplineComp = GetClosestWingSuitBoundarySplineComp();
		if(SplineComp != nullptr)
		{
			FVector2D VolumeAlpha = SplineComp.GetVolumeAlphaForLocation(PlayerOwner.ActorLocation);
			return VolumeAlpha.X;
		}

		return 0.0;
	}

	void AddWingSuitTrailBlocker(FInstigator Instigator, bool bDeactivateImmediately = false)
	{
		if(!HasControl())
			return;

		CrumbAddWingSuitTrailBlocker(Instigator, bDeactivateImmediately);
	}

	void RemoveWingSuitTrailBlocker(FInstigator Instigator)
	{
		if(!HasControl())
			return;

		CrumbRemoveWingSuitTrailBlocker(Instigator);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAddWingSuitTrailBlocker(FInstigator Instigator, bool bDeactivateImmediately)
	{
		bool bWasBlocked = TrailBlockers.Num() > 0;
		TrailBlockers.AddUnique(Instigator);
		if(!bWasBlocked)
			WingSuit.BP_DisableWingsuitTrail(bDeactivateImmediately);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRemoveWingSuitTrailBlocker(FInstigator Instigator)
	{
		bool bWasBlocked = TrailBlockers.Num() > 0;
		TrailBlockers.RemoveSingleSwap(Instigator);
		if(bWasBlocked && TrailBlockers.Num() == 0)
			WingSuit.BP_EnableWingsuitTrail();
	}

	void AddWingSuitRubberbandBlocker(FInstigator Instigator)
	{
		RubberbandBlockers.AddUnique(Instigator);
	}

	void RemoveWingSuitRubberbandBlocker(FInstigator Instigator)
	{
		RubberbandBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsWingSuitRubberbandBlocked() const
	{
		return RubberbandBlockers.Num() > 0;
	}

	UWingSuitBoundarySplineComponent GetClosestWingSuitBoundarySplineComp(bool bOnlyGetVolumesPlayerIsInside = true) const
	{
		UWingSuitBoundarySplineComponent ClosestBoundarySplineComp;
		float ClosestSquaredDistance = MAX_flt;
		for(UWingSuitBoundarySplineComponent SplineComp : BoundarySplineContainer.BoundarySplineComponents)
		{
			if(SplineComp.IsLocationWithinSplineBounds(PlayerOwner.ActorLocation))
			{
				ClosestBoundarySplineComp = SplineComp;
				break;
			}

			if(!bOnlyGetVolumesPlayerIsInside)
			{
				float DistSqr = SplineComp.GetClosestLocationToVolume(PlayerOwner.ActorLocation).DistSquared(PlayerOwner.ActorLocation);
				if(DistSqr < ClosestSquaredDistance)
				{
					ClosestSquaredDistance = DistSqr;
					ClosestBoundarySplineComp = SplineComp;
				}
			}
		}

		return ClosestBoundarySplineComp;
	}

	int GetActiveBarrelRollDirection() const property
	{
		return Internal_ActiveBarrelRollDirection;
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSetActiveBarrelRollDirection(int NewDirection)
	{
		Internal_ActiveBarrelRollDirection = NewDirection;
		AnimData.ActiveBarrelRollDirection = NewDirection;
		bHasEverBarrelRolled = true;

		if(NewDirection == 0)
			return;
			
		FWingSuitBarrelRollEffectParams Params;
		Params.BarrelRollDirection = NewDirection;
		UWingSuitEffectHandler::Trigger_OnBarrelRoll(WingSuit, Params);
	}
}
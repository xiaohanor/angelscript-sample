struct FTundraPlayerTreeGuardianRangedInteractGrappleAnimData
{
	UPROPERTY()
	bool bRootsAttached = false;

	UPROPERTY()
	bool bAboutToReachGrapple = false;

	UPROPERTY()
	bool bAboutToKickback = false;

	UPROPERTY()
	bool bAttached = false;

	UPROPERTY()
	FVector2D AttachedAimingDirection;

	// This angle will be 0 into the wall, 180 out from the wall, 90 to the right of the tree guardian, -90 to the left.
	UPROPERTY()
	float AttachedAimingYawAngle;

	// This angle will be 0 to the right and left, 90 up, -90 down
	UPROPERTY()
	float AttachedAimingRollAngle;

	UPROPERTY()
	bool bIsInAiming = false;

	UPROPERTY()
	bool bIsInRangedHit = false;
}

struct FTundraPlayerTreeGuardianRangedInteractAnimData
{
	UPROPERTY()
	bool bAimingOnGrappleInteract = false;

	UPROPERTY()
	bool bAimingOnRangedLifeGivingInteract = false;
}

struct FTundraPlayerTreeGuardianRangedHitAnimData
{
	UPROPERTY()
	bool bHasReachedTarget = false;
}

struct FTundraPlayerTreeGuardianLifeGiveAnimData
{
	UPROPERTY()
	bool bEnterInstant;

	UPROPERTY()
	bool bExitInstant;

	UPROPERTY()
	float LifeGivingHorizontalAlpha;

	UPROPERTY()
	float LifeGivingVerticalAlpha;

	UPROPERTY()
	bool bShouldExit;
	
	UPROPERTY()
	float AnimationScrubTime;
}

struct FTundraPlayerTreeGuardianHoldDownIceKingAnimData
{
	UPROPERTY()
	bool bSuccess = false;

	UPROPERTY()
	bool bFail = false;

	UPROPERTY()
	float ButtonMashProgress = 0.0;
}

struct FTundraTreeGuardianTurnAroundAnimData
{
	bool bTurnaroundIsClockwise;
}

UCLASS(Abstract)
class UTundraPlayerTreeGuardianComponent : UTundraPlayerShapeBaseComponent
{
	default ShapeType = ETundraShapeshiftShape::Big;

	UPROPERTY(Category = "General")
	TSubclassOf<ATundraPlayerTreeGuardianActor> TreeGuardianActorClass;

	UPROPERTY(Category = "General")
	UTundraPlayerTreeGuardianSettings SettingsOverride;

	UPROPERTY(Category = "General")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "General")
	UMovementSteppingSettings SteppingSettings;

	UPROPERTY(Category = "Life Giving")
	UMaterialInterface LifeGivingPostProcess;

	UPROPERTY(Category = "Life Giving")
	float LifeGivingPostProcessBlendTime = 0.5;

	UPROPERTY(Category = "Ranged Interactions")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsWhenAiming;

	UPROPERTY(Category = "Ranged Interactions")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsWhenFoundRangedInteraction;

	UPROPERTY(Category = "Ranged Interactions")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsWhenAttachedAiming;

	UPROPERTY(Category = "Ranged Interactions")
	UHazeCameraSpringArmSettingsDataAsset CameraSettingsWhenAttachedFoundRangedInteraction;

	UPROPERTY(Category = "Ranged Interactions")
	TSubclassOf<UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget> RangedInteractionCrosshairClass;

	UPROPERTY(Category = "Ranged Interactions")
	TSubclassOf<UTundraPlayerTreeGuardianRangedInteractionTargetableWidget> RangedInteractionTargetableWidget2DClass;

	UPROPERTY(Category = "Ranged Interactions")
	UForceFeedbackEffect GrappleStartLeftFF;

	UPROPERTY(Category = "Ranged Interactions")
	UForceFeedbackEffect GrappleStartRightFF;

	UPROPERTY(Category = "Ranged Interactions")
	UForceFeedbackEffect GrappleRootsAttachFF;

	UPROPERTY(Category = "Ranged Interactions")
	UForceFeedbackEffect GrappleTreeStuckLandingFF;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	UHazeCameraSpringArmSettingsDataAsset RangedShootCameraSettings;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	TSubclassOf<UCameraShakeBase> RangedShootCameraShake;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	UForceFeedbackEffect RangedShootForceFeedback;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	UForceFeedbackEffect RangedShootForceFeedbackOnShoot;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	float RangedShootCameraBlendInTime = 4.0;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	float RangedShootCameraBlendOutTime = 3.0;

	bool bIsActive = false;
	bool bCurrentlyLifeGiving = false;
	bool bEnteringLifeGiving = false;
	bool bPostProcessApplied = false;
	TOptional<float> TimeOfExitLifeGiveAnimation;
	bool bInLifeGivingAnimation;
	UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget TargetedRangedInteractionCrosshair;

	UPROPERTY()
	FVector CurrentRangedLifeGivingRootEndLocation;

	FVector RangedHitRootTravelDirection;

	UPROPERTY()
	USceneComponent RootsDestination;

	// Anim data
	FTundraPlayerTreeGuardianLifeGiveAnimData LifeGiveAnimData;
	FTundraTreeGuardianTurnAroundAnimData TurnAroundAnimData;

	FTundraPlayerTreeGuardianRangedInteractGrappleAnimData GrappleAnimData;
	FTundraPlayerTreeGuardianRangedInteractAnimData RangedInteractAnimData;
	FTundraPlayerTreeGuardianRangedHitAnimData RangedHitAnimData;
	UPROPERTY(BlueprintReadOnly)
	FTundraPlayerTreeGuardianHoldDownIceKingAnimData HoldDownIceKingAnimData;
	// End anim data

	UTundraGroundedLifeReceivingTargetableComponent CurrentlyFoundGroundedLifeReceivingTargetable;
	UTundraTreeGuardianRangedInteractionTargetableComponent CurrentlyFoundRangedInteractionTargetable;
	UTundraTreeGuardianRangedInteractionTargetableComponent CurrentRangedGrapplePoint;
	UTundraTreeGuardianRangedInteractionTargetableComponent CurrentRangedLifeGivingTargetable;
	UTundraTreeGuardianRangedInteractionTargetableComponent RangedInteractionTargetableToForceEnter;
	bool bCameFromGrapple = false;
	bool bInKickback = false;
	private TArray<FInstigator> LifeGivingPostProcessInstigators;
	float CurrentLifeGivingPostProcessOpacityAlpha = 0.0;
	UMaterialInstanceDynamic LifeGivingPostProcessMaterialDynamic;
	UPostProcessingComponent PostProcessComp;
	UPlayerMovementComponent MoveComp;
	UTundraLifeReceivingComponent CurrentLifeReceivingComp;
	float TimeOfExitLifeGiving = -100.0;
	UTundraPlayerTreeGuardianSettings Settings;
	bool bCurrentLifeGiveIsRanged = false;
	UTundraTreeGuardianRangedShootTargetable CurrentRangedShootTargetable;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	ATundraPlayerTreeGuardianActor TreeGuardianActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		PostProcessComp = UPostProcessingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);

		LifeGivingPostProcessMaterialDynamic = Material::CreateDynamicMaterialInstance(this, LifeGivingPostProcess);

		if(SettingsOverride != nullptr)
			Player.ApplyDefaultSettings(SettingsOverride);

		if(TreeGuardianActorClass != nullptr)
		{
			TreeGuardianActor = SpawnActor(TreeGuardianActorClass, bDeferredSpawn = true);
			TreeGuardianActor.Player = Player;
			FinishSpawningActor(TreeGuardianActor);
			TreeGuardianActor.MakeNetworked(this, n"_TreeGuardianActor");
			
			TreeGuardianActor.AttachToComponent(Player.Mesh);
			TreeGuardianActor.ActorRelativeTransform = FTransform::Identity;
			Player.Mesh.LinkMeshComponentToLocomotionRequests(TreeGuardianActor.Mesh);
			TreeGuardianActor.Mesh.SetOverrideRootMotionReceiverComponent(Player.RootComponent);
			TreeGuardianActor.AddActorDisable(ShapeshiftingComp);
			Outline::ApplyOutlineOnActor(TreeGuardianActor, Game::Mio, Outline::GetMioOutlineAsset(), this, EInstigatePriority::Level);

			UPlayerRenderingSettingsComponent::GetOrCreate(Player).AdditionalSubsurfaceMeshes.Add(TreeGuardianActor.Mesh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float LifeGivingPostProcessTarget = IsLifeGivingPostProcessActive() ? 1.0 : 0.0;

		if(IsLifeGivingPostProcessActive() && !bPostProcessApplied)
		{
			PostProcessComp.ApplyPostProcess(LifeGivingPostProcessMaterialDynamic, this, EInstigatePriority::Normal);
			bPostProcessApplied = true;
		}

		if(LifeGivingPostProcessTarget == CurrentLifeGivingPostProcessOpacityAlpha)
			return;

		CurrentLifeGivingPostProcessOpacityAlpha = Math::FInterpConstantTo(CurrentLifeGivingPostProcessOpacityAlpha, LifeGivingPostProcessTarget, DeltaTime, 1.0 / LifeGivingPostProcessBlendTime);

		LifeGivingPostProcessMaterialDynamic.SetScalarParameterValue(n"Opacity", CurrentLifeGivingPostProcessOpacityAlpha);

		if(CurrentLifeGivingPostProcessOpacityAlpha == 0.0)
		{
			PostProcessComp.ClearPostProcess(this);
			bPostProcessApplied = false;
		}
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	AHazeCharacter GetShapeActor() const override
	{
		return TreeGuardianActor;
	}

	UHazeCharacterSkeletalMeshComponent GetShapeMesh() const override
	{
		return TreeGuardianActor.Mesh;
	}

	FVector2D GetShapeCollisionSize() const override
	{
		return TundraShapeshiftingStatics::TreeGuardianCollisionSize;
	}

	void GetMaterialTintColors(FLinearColor &PlayerColor, FLinearColor &ShapeColor) const override
	{
		PlayerColor = Settings.MorphPlayerTint;
		ShapeColor = Settings.MorphShapeTint;
	}

	float GetShapeGravityAmount() const override
	{
		return Settings.GravityAmount;
	}

	float GetShapeTerminalVelocity() const override
	{
		return Settings.TerminalVelocity;
	}

	bool ShouldConsumeShapeshiftInput() const override
	{
		return true;
	}

	float GetToShapeGravityBlendTime() const override
	{
		return Settings.GravityBlendTime;
	}

	void AddLifeGivingPostProcessInstigator(FInstigator Instigator)
	{
		LifeGivingPostProcessInstigators.AddUnique(Instigator);
	}

	void RemoveLifeGivingPostProcessInstigator(FInstigator Instigator)
	{
		LifeGivingPostProcessInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsLifeGivingPostProcessActive()
	{
		return !Player.IsPendingFullscreen() && LifeGivingPostProcessInstigators.Num() > 0;
	}

	void TriggerRangedInteractionRootsHitSurfaceEffectEvent(UTundraTreeGuardianRangedInteractionTargetableComponent Targetable, ETundraTreeGuardianRangedInteractionType InteractionType)
	{
		FHazeTraceSettings Trace = Trace::InitProfile(n"BlockAllDynamic");
		Trace.IgnorePlayers();
		Trace.UseShape(FCollisionShape::MakeSphere(100.0));
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Targetable.WorldLocation);
		TArray<FOverlapResult> OverlapArray = Overlaps.GetBlockHits();

		FHitResult RelevantHitResult;

		if(OverlapArray.Num() > 0)
		{
			FVector ClosestPoint;
			float ClosestDistance = MAX_flt;
			UPrimitiveComponent ClosestComponent;
			
			for(FOverlapResult Overlap : OverlapArray)
			{
				FVector TempClosestPoint;
				Overlap.Component.GetClosestPointOnCollision(Targetable.WorldLocation, TempClosestPoint);
				float TempDistance = TempClosestPoint.Distance(Targetable.WorldLocation);

				if(TempDistance < ClosestDistance)
				{
					ClosestDistance = TempDistance;
					ClosestPoint = TempClosestPoint;
					ClosestComponent = Overlap.Component;
				}
			}

			FVector TraceOrigin = Targetable.WorldLocation;
			FVector TraceDestination = ClosestPoint + (ClosestPoint - TraceOrigin).GetSafeNormal() * 1.0;

			if(TraceOrigin.Equals(TraceDestination))
				TraceOrigin = TraceOrigin + (Player.ActorCenterLocation - TraceOrigin).GetSafeNormal() * 100.0;
		
			Trace.UseLine();
			Trace.SetReturnPhysMaterial(true);
			RelevantHitResult = Trace.QueryTraceSingle(TraceOrigin, TraceDestination);
		}
		else
		{
			RelevantHitResult = FHitResult();
		}

		FTundraPlayerTreeGuardianRangedHitSurfaceEffectParams EffectParams;
		EffectParams.HitResult = RelevantHitResult;
		EffectParams.InteractionType = InteractionType;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnRootsHitSurface(TreeGuardianActor, EffectParams);
	}
}
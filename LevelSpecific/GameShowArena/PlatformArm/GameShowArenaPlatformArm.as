struct FGameShowArenaPlatformArmConfig
{
	FGameShowArenaPlatformArmConfig()
	{
	}
	FGameShowArenaPlatformArmConfig(EBombTossPlatformPosition InPosition)
	{
		switch (InPosition)
		{
			case EBombTossPlatformPosition::Hidden:
				BaseArmExtension = 0;
				break;
			case EBombTossPlatformPosition::Neutral:
				BaseArmExtension = 1650;
				break;
			case EBombTossPlatformPosition::WallUp:
				BaseArmExtension = 1850;
				PlatformArmExtension = 115;
				UpperArmPitch = 10.35;
				PlatformRootPitch = 79.65;
				BaseArmYaw = 180;
				break;
			case EBombTossPlatformPosition::WallDown:
				BaseArmExtension = 1850;
				PlatformArmExtension = 115;
				UpperArmPitch = 10.35;
				PlatformRootPitch = 79.65;
				break;
			case EBombTossPlatformPosition::WallLeft:
				BaseArmExtension = 1850;
				PlatformArmExtension = 115;
				UpperArmPitch = 10.35;
				PlatformRootPitch = 79.65;
				BaseArmYaw = 90;
				break;
			case EBombTossPlatformPosition::WallRight:
				BaseArmExtension = 1850;
				PlatformArmExtension = 115;
				UpperArmPitch = 10.35;
				PlatformRootPitch = 79.65;
				BaseArmYaw = 270;
				break;
			case EBombTossPlatformPosition::DoubleWallLeft:
				BaseArmExtension = 2745;
				UpperArmPitch = 90;
				BaseArmYaw = 90;
				PlatformArmExtension = 100.75;
				break;
			case EBombTossPlatformPosition::DoubleWallRight:
				BaseArmExtension = 2745;
				UpperArmPitch = 90;
				BaseArmYaw = 270;
				PlatformArmExtension = 100.75;
				break;
			case EBombTossPlatformPosition::Raised:
				BaseArmExtension = 2450;
				break;
			case EBombTossPlatformPosition::TiltRight:
				BaseArmExtension = 1404;
				LowerArmExtension = 300;
				UpperArmPitch = 30.5;
				BaseArmYaw = 270;
				PlatformRootPitch = -UpperArmPitch;
				break;
			case EBombTossPlatformPosition::TiltLeft:
				BaseArmExtension = 1404;
				LowerArmExtension = 300;
				UpperArmPitch = 30.5;
				BaseArmYaw = 90;
				PlatformRootPitch = -UpperArmPitch;
				break;
			case EBombTossPlatformPosition::TiltRightRaised:
				BaseArmExtension = 2504;
				UpperArmPitch = 30.5;
				BaseArmYaw = 270;
				PlatformRootPitch = -UpperArmPitch;
				break;
			case EBombTossPlatformPosition::TiltLeftRaised:
				BaseArmExtension = 2504;
				UpperArmPitch = 30.5;
				BaseArmYaw = 90;
				PlatformRootPitch = -UpperArmPitch;
				break;
			default:
				break;
		}

		Position = InPosition;
	}
	void Randomize(FRandomStream RandStream)
	{
		BaseArmExtension = RandStream.RandRange(0, 3000);
		LowerArmExtension = RandStream.RandRange(0, 400);
		PlatformArmExtension = RandStream.RandRange(0, 200);
		UpperArmPitch = RandStream.RandRange(-120, 120);
		BaseArmYaw = RandStream.RandRange(0, 360);
		PlatformRootPitch = RandStream.RandRange(-120, 120);
	}

	bool opEquals(FGameShowArenaPlatformArmConfig Other) const
	{
		return Other.Position == Position;
	}
	EBombTossPlatformPosition Position;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "0", ClampMax = "400.0", UIMin = "0.0", UIMax = "400.0"))
	float LowerArmExtension = 0;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "200.0", UIMin = "0.0", UIMax = "200.0"))
	float PlatformArmExtension = 0;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "3000.0", UIMin = "0.0", UIMax = "3000.0"))
	float BaseArmExtension = 0;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "-120", ClampMax = "120", UIMin = "-120", UIMax = "120.0"))
	float UpperArmPitch = 0;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "360", UIMin = "0.0", UIMax = "360"))
	float BaseArmYaw = 0;
	UPROPERTY(EditAnywhere, meta = (ClampMin = "-120", ClampMax = "120.0", UIMin = "-120.0", UIMax = "120.0"))
	float PlatformRootPitch = 0;
}

event void FGameShowArenaPlatformArmMovementFinished();
event void FGameShowArenaPlatformArmMovementStarted();
class AGameShowArenaPlatformArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseArm;
	default BaseArm.RelativeLocation = FVector::ZeroVector;
	default BaseArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = BaseArm)
	UStaticMeshComponent LowerArm;
	default LowerArm.RelativeLocation = FVector(0, 0, LowerArmOffset);
	default LowerArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = LowerArm)
	UStaticMeshComponent UpperArm;
	default UpperArm.RelativeRotation = FRotator::ZeroRotator;
	default UpperArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = UpperArm)
	UStaticMeshComponent PlatformArm;
	default PlatformArm.RelativeLocation = FVector(0, 0, PlatformArmOffset);
	default PlatformArm.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = PlatformArm)
	UStaticMeshComponent PlatformMesh;
	default PlatformMesh.RelativeLocation = FVector(0, 0, PlatformOffset);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaPlatformPlayerReactionCapability);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;
	default ActionQueueComp.bLogQueueToTemporalLog = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DecalComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface PanelMaterial;
	
	FGameShowArenaPlatformArmConfig PreviousConfig;
	FGameShowArenaPlatformArmConfig TargetConfig;

	const float PlatformArmOffset = 390;
	const float PlatformOffset = 110;
	const float LowerArmOffset = 80;

	FRotator BaseStartRotation;
	FVector BaseStartLocation;
	FVector LowerStartLocation;
	FRotator UpperStartRotation;
	FRotator PlatformStartRotation;
	FVector PlatformArmStartLocation;

	FRotator CurrentBaseRotation;
	FVector CurrentBaseLocation;
	FVector CurrentLowerLocation;
	FRotator CurrentUpperRotation;
	FRotator CurrentPlatformRotation;
	FVector CurrentPlatformArmLocation;

	UPROPERTY(EditInstanceOnly)
	TMap<EBombTossChallenges, FGameShowArenaSimpleDisplayDecalParams> PerChallengeDecalData;
	UPROPERTY(EditAnywhere)
	FGameShowArenaPlatformMoveData LayoutMoveData;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	UPROPERTY()
	FGameShowArenaPlatformArmMovementFinished OnMovementFinished;

	UPROPERTY()
	FGameShowArenaPlatformArmMovementFinished OnMovementStarted;

	UPROPERTY()
	UCurveFloat WiggleCurve;

	UPROPERTY(VisibleAnywhere)
	FGuid ArmGuid;

	AHazeActor AttachedActor;

	bool bHasBlockedCollision;
	bool bHasBlockedVisuals;

	FRandomStream GlitchRandStream;

	FRotator PlatformArmAttachRotation;

	private AGameShowArenaPlatformManager PlatformManager;

#if EDITOR
	UFUNCTION(CallInEditor)
	void AssignGUID()
	{
		ArmGuid = ActorGuid;
	}

	UFUNCTION(CallInEditor)
	void PreviewLocation(EBombTossPlatformPosition Position)
	{
		TargetConfig = FGameShowArenaPlatformArmConfig(Position);
		BaseStartRotation = FRotator::ZeroRotator;
		BaseStartLocation = FVector::ZeroVector;
		LowerStartLocation = FVector(0, 0, LowerArmOffset);
		UpperStartRotation = FRotator::ZeroRotator;
		PlatformStartRotation = FRotator::ZeroRotator;
		PlatformArmStartLocation = FVector(0, 0, PlatformArmOffset);
		RotateBase(1.0);
		ExtendBase(1.0);
		ExtendLower(1.0);
		PitchUpper(1.0);
		ExtendPlatform(1.0);
	}

	void EditorSnapToMoveData(FGameShowArenaPlatformMoveData MoveData)
	{
		LayoutMoveData = MoveData;
		PreviewLocation(MoveData.Position);
	}
#endif
	void DisplayChallengeDecal()
	{
		EBombTossChallenges Challenge = PlatformManager.GetCurrentChallenge();
		if (PerChallengeDecalData.Contains(Challenge))
		{
			DecalComp.UpdateMaterialParameters(PerChallengeDecalData[Challenge], bIsAlternateDecal);
		}
		else if (PerChallengeDecalData.Num() > 0)
		{
			FGameShowArenaSimpleDisplayDecalParams Params;
			Params.Opacity = 0;
			DecalComp.UpdateMaterialParameters(Params, bIsAlternateDecal);
		}
	}

	void AttachActorToPlatformPosition(AHazeActor Actor)
	{
		Actor.AttachToComponent(PlatformMesh);
		PlatformMesh.AddComponentCollisionBlocker(Actor);
		PlatformMesh.AddComponentVisualsBlocker(Actor);
	}

	void DetachActorFromPlatform(AHazeActor Actor)
	{
		Actor.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		PlatformMesh.RemoveComponentCollisionBlocker(Actor);
		PlatformMesh.RemoveComponentVisualsBlocker(Actor);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlatformManager == nullptr)
			PlatformManager = GameShowArena::GetGameShowArenaPlatformManager();

		DecalComp.AssignTarget(PlatformMesh, nullptr);
		PlatformArmAttachRotation = PlatformArm.RelativeRotation;
		PreviousConfig = FGameShowArenaPlatformArmConfig();
		BaseStartRotation = FRotator::ZeroRotator;
		BaseStartLocation = FVector::ZeroVector;
		LowerStartLocation = FVector(0, 0, LowerArmOffset);
		UpperStartRotation = FRotator::ZeroRotator;
		PlatformStartRotation = FRotator::ZeroRotator;
		PlatformArmStartLocation = FVector(0, 0, PlatformArmOffset);
		LayoutMoveData = FGameShowArenaPlatformMoveData();
		RotateBase(1.0);
		ExtendBase(1.0);
		ExtendLower(1.0);
		PitchUpper(1.0);
		ExtendPlatform(1.0);
		EnableCollision();
		CheckShouldEnableVisuals();
		FinishMoving();
	}

	void SnapToPosition(FGameShowArenaPlatformMoveData MoveData)
	{
		TargetConfig = FGameShowArenaPlatformArmConfig(MoveData.Position);
		if (MoveData.bShouldGlitch)
		{
			if (HasControl())
				CrumbStartGlitching(Math::Rand());
		}
		else
		{
			RotateBase(1.0);
			ExtendBase(1.0);
			ExtendLower(1.0);
			PitchUpper(1.0);
			ExtendPlatform(1.0);
			DisableCollision();
			EnableCollision();
			CheckShouldEnableVisuals();
			FinishMoving();
			ActionQueueComp.Empty();
		}
	}

	UFUNCTION()
	void StartMoving(FGameShowArenaPlatformMoveData MoveData)
	{
		TargetConfig = FGameShowArenaPlatformArmConfig(MoveData.Position);

		if (TargetConfig == PreviousConfig && !MoveData.bShouldGlitch)
		{
			DisplayChallengeDecal();
			return;
		}

		if (MoveData.bShouldGlitch)
		{
			if (HasControl())
				CrumbStartGlitching(Math::Rand());
		}
		else
		{
			ActionQueueComp.Empty();
			ActionQueueComp.SetLooping(false);
			OnMovementStarted.Broadcast();
			ActionQueueComp.Idle(MoveData.MoveDelay);
			ActionQueueComp.Event(this, n"DisableCollision");
			ActionQueueComp.Event(this, n"CheckShouldEnableVisuals");
			if (!Math::IsNearlyEqual(TargetConfig.BaseArmYaw, PreviousConfig.BaseArmYaw))
				ActionQueueComp.Duration(0.3, this, n"RotateBase");

			if (!Math::IsNearlyEqual(TargetConfig.BaseArmExtension, PreviousConfig.BaseArmExtension))
			{
				ActionQueueComp.Event(this, n"TriggerAudioStartMoving");
				ActionQueueComp.Duration(MoveData.MoveDuration, this, n"ExtendBase");
				ActionQueueComp.Event(this, n"TriggerAudioStopMoving");
			}

			if (MoveData.bRotateBeforeExtending)
			{
				EnqueuePlatformRotations(MoveData);
				EnqueueExtensions(MoveData);
			}
			else
			{
				EnqueueExtensions(MoveData);
				EnqueuePlatformRotations(MoveData);
			}

			ActionQueueComp.Event(this, n"EnableCollision");
			ActionQueueComp.Event(this, n"FinishMoving");
		}
	}

	void EnqueueExtensions(FGameShowArenaPlatformMoveData MoveData)
	{
		ActionQueueComp.Event(this, n"TriggerAudioStartMoving");
		
		if (!Math::IsNearlyEqual(TargetConfig.LowerArmExtension, PreviousConfig.LowerArmExtension))
			ActionQueueComp.Duration(0.4, this, n"ExtendLower");

		if (!Math::IsNearlyEqual(TargetConfig.PlatformArmExtension, PreviousConfig.PlatformArmExtension))
			ActionQueueComp.Duration(0.4, this, n"ExtendPlatform");

		ActionQueueComp.Event(this, n"TriggerAudioStopMoving");
	}

	void EnqueuePlatformRotations(FGameShowArenaPlatformMoveData MoveData)
	{
		if (!Math::IsNearlyEqual(TargetConfig.UpperArmPitch, PreviousConfig.UpperArmPitch))
		{
			ActionQueueComp.Event(this, n"TriggerAudioStartTilting");
			ActionQueueComp.Duration(0.6, this, n"PitchUpper");
			ActionQueueComp.Event(this, n"TriggerAudioStopMoving");
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartGlitching(int RandSeed)
	{
		GlitchRandStream = FRandomStream(RandSeed);
		TargetConfig = FGameShowArenaPlatformArmConfig(EBombTossPlatformPosition::Neutral);
		Glitch();
	}

	UFUNCTION()
	void Glitch()
	{
		ActionQueueComp.Empty();
		ActionQueueComp.Event(this, n"RandomizeConfig");
		ActionQueueComp.Idle(GlitchRandStream.RandRange(0.1, 0.5));
		OnMovementStarted.Broadcast();
		int Seed = GlitchRandStream.CurrentSeed;
		ActionQueueComp.Event(this, n"DisableCollision");
		ActionQueueComp.Event(this, n"CheckShouldEnableVisuals");
		if (GlitchRandStream.RandRange(0, 1) == 1)
			ActionQueueComp.Duration(GlitchRandStream.RandRange(0.1, 0.3), this, n"RotateBase");
		if (GlitchRandStream.RandRange(0, 1) == 1)
		{
			ActionQueueComp.Event(this, n"TriggerAudioStartMoving");
			ActionQueueComp.Duration(GlitchRandStream.RandRange(0.5, 1.2), this, n"ExtendBase");
			ActionQueueComp.Event(this, n"TriggerAudioStopMoving");
		}
		if (GlitchRandStream.RandRange(0, 1) == 1)
			ActionQueueComp.Duration(GlitchRandStream.RandRange(0.2, 0.4), this, n"ExtendLower");
		if (GlitchRandStream.RandRange(0, 1) == 1)
			ActionQueueComp.Duration(GlitchRandStream.RandRange(0.2, 0.4), this, n"ExtendPlatform");
		if (GlitchRandStream.RandRange(0, 1) == 1)
		{
			ActionQueueComp.Event(this, n"TriggerAudioStartTilting");
			ActionQueueComp.Duration(GlitchRandStream.RandRange(0.2, 0.5), this, n"PitchUpper");
			ActionQueueComp.Event(this, n"TriggerAudioStopMoving");
		}
		ActionQueueComp.Event(this, n"EnableCollision");
		ActionQueueComp.Event(this, n"FinishMoving");
		ActionQueueComp.Event(this, n"Glitch");
	}

	UFUNCTION()
	private void RandomizeConfig()
	{
		TargetConfig.Randomize(GlitchRandStream);
	}

	UFUNCTION()
	private void CheckShouldEnableVisuals()
	{
		if (TargetConfig.Position != EBombTossPlatformPosition::Hidden && bHasBlockedVisuals)
		{
			RemoveActorVisualsBlock(this);
			bHasBlockedVisuals = false;
		}
	}

	UFUNCTION()
	private void FinishMoving()
	{
		PreviousConfig = TargetConfig;
		CurrentBaseRotation = BaseArm.RelativeRotation;
		CurrentBaseLocation = BaseArm.RelativeLocation;
		CurrentLowerLocation = LowerArm.RelativeLocation;
		CurrentPlatformArmLocation = PlatformArm.RelativeLocation;
		CurrentPlatformRotation = PlatformArmAttachRotation;
		CurrentUpperRotation = UpperArm.RelativeRotation;
		OnMovementFinished.Broadcast();
		if (TargetConfig.Position == EBombTossPlatformPosition::Hidden && !bHasBlockedVisuals)
		{
			AddActorVisualsBlock(this);
			bHasBlockedVisuals = true;
		}
		DisplayChallengeDecal();
	}

	UFUNCTION()
	private void TriggerAudioStartMoving()
	{
		FGameShowArenaPlatformArmStartMovingParams Params;
		Params.PlatformArmActor = this;
		Params.PlatformMesh = PlatformMesh;
		UGameShowArenaPlatformArmEventHandler::Trigger_StartMoving(this, Params);
	}

	UFUNCTION()
	private void TriggerAudioStopMoving()
	{
		FGameShowArenaPlatformArmStopMovingParams Params;
		Params.PlatformArmActor = this;
		Params.PlatformMesh = PlatformMesh;
		UGameShowArenaPlatformArmEventHandler::Trigger_StopMoving(this, Params);
	}

	UFUNCTION()
	private void TriggerAudioStartTilting()
	{
		FGameShowArenaPlatformArmStartTiltingParams Params;
		Params.PlatformArmActor = this;
		Params.PlatformMesh = PlatformMesh;
		UGameShowArenaPlatformArmEventHandler::Trigger_StartTiltingArm(this, Params);
	}

	UFUNCTION()
	private void DisableCollision()
	{
		if (bHasBlockedCollision)
			return;

		AddActorCollisionBlock(this);
		bHasBlockedCollision = true;
	}

	UFUNCTION()
	private void EnableCollision()
	{
		if (!bHasBlockedCollision)
			return;

		// Adding and removing block because sometimes unreal collision breaks and this fixes it
		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);
	}

	UFUNCTION()
	private void ExtendPlatform(float Alpha)
	{
		PlatformArm.RelativeLocation = Math::Lerp(CurrentPlatformArmLocation, PlatformArmStartLocation + FVector(0, 0, TargetConfig.PlatformArmExtension), Alpha * Alpha * Alpha);
	}

	UFUNCTION()
	private void PitchUpper(float Alpha)
	{
		UpperArm.RelativeRotation = FQuat::Slerp(CurrentUpperRotation.Quaternion(), (UpperStartRotation + FRotator(TargetConfig.UpperArmPitch, 0, 0)).Quaternion(), Alpha).Rotator();
		PlatformArmAttachRotation = PlatformArm.RelativeTransform.InverseTransformRotation(FQuat::Slerp(CurrentPlatformRotation.Quaternion(), (PlatformStartRotation + FRotator(TargetConfig.PlatformRootPitch, 0, 0)).Quaternion(), Alpha).Rotator());

		PlatformMesh.RelativeRotation = PlatformArmAttachRotation;
		PlatformMesh.RelativeLocation = PlatformArmAttachRotation.UpVector * PlatformOffset;

		if (AttachedActor != nullptr)
		{
			AttachedActor.ActorRelativeRotation = PlatformMesh.RelativeRotation;
			AttachedActor.ActorRelativeLocation = PlatformMesh.RelativeLocation;
		}
	}

	UFUNCTION()
	private void ExtendLower(float Alpha)
	{
		LowerArm.RelativeLocation = Math::Lerp(CurrentLowerLocation, LowerStartLocation + FVector(0, 0, TargetConfig.LowerArmExtension), Alpha);
	}

	UFUNCTION()
	private void ExtendBase(float Alpha)
	{
		BaseArm.RelativeLocation = Math::Lerp(CurrentBaseLocation, BaseStartLocation + FVector(0, 0, TargetConfig.BaseArmExtension), WiggleCurve.GetFloatValue(Alpha));
		// BaseArm.RelativeLocation = Math::Lerp(CurrentBaseLocation, BaseStartLocation + FVector(0, 0, TargetConfig.BaseArmExtension), Alpha * Alpha * Alpha);
	}

	UFUNCTION()
	private void RotateBase(float Alpha)
	{
		BaseArm.RelativeRotation = FQuat::Slerp(CurrentBaseRotation.Quaternion(), (BaseStartRotation + FRotator(0, TargetConfig.BaseArmYaw, 0)).Quaternion(), Alpha).Rotator();
	}
};
asset SketchbookGoatIdleSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USketchbookGoatIdleCapability);
	Capabilities.Add(USketchbookGoatIdleAirMovementCapability);
};

asset SketchbookGoatMountedSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USketchbookGoatInputCapability);
	Capabilities.Add(USketchbookGoatAirMovementCapability);
	Capabilities.Add(USketchbookGoatMountedCapability);
	Capabilities.Add(USketchbookGoatDeathCapability);
	Capabilities.Add(USketchbookGoatGroundMovementCapability);
	Capabilities.Add(USketchbookGoatJumpCapability);
	Capabilities.Add(USketchbookGoatPerchJumpCapability);
	Capabilities.Add(USketchbookGoatMeshOffsetCapability);

	Components.Add(USketchbookGoatSplineMovementComponent);
};

UCLASS(Abstract)
class ASketchbookGoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent RootOffsetComp;

	UPROPERTY(DefaultComponent, Attach = RootOffsetComp)
	UHazeCapsuleCollisionComponent CapsuleComp;

	UPROPERTY(DefaultComponent, Attach = RootOffsetComp)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Hips)
	USceneComponent PlayerAttachmentRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.InitialStoppedSheets.Add(SketchbookGoatIdleSheet);
	default CapabilityComp.InitialStoppedSheets.Add(SketchbookGoatMountedSheet);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	USketchbookDrawableObjectComponent DrawableObjectComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedHorizontalInput;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedRawInput;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 2000;

	UPROPERTY(EditAnywhere)
	float LenghtModifier = 0;

	UPROPERTY()
	UForceFeedbackEffect JumpForceFeedback;

	UPROPERTY(EditAnywhere)
	EHazePlayer CopyStencilDepthFrom;

	UPROPERTY(EditAnywhere)
	float MinRespawnDistanceFromScreen = 1500;

	ASketchbookGoat OtherGoat;

	ASketchbookGoatPerchJumpZone JumpZone;
	ASketchbookGoatPerchJumpZone PreviousJumpZone;
	int PerchPointIndex = 0;
	bool bPerchJumping = false;
	bool bPerchWasForced = false;


	AHazePlayerCharacter MountedPlayer;
	private UPlayerMovementComponent PlayerMoveComp;
	private USketchbookGoatSplineMovementComponent GoatSplineMoveComp;
	USketchbookGoatSplineMovementComponent GetGoatSplineMoveComp()
	{
		if(!IsMounted())
			return nullptr;

		if(GoatSplineMoveComp == nullptr)
			GoatSplineMoveComp = USketchbookGoatSplineMovementComponent::Get(this);

		return GoatSplineMoveComp;
	}

	UFUNCTION(BlueprintPure)
	bool IsInAir()
	{
		auto SplineMoveComp = GetGoatSplineMoveComp();
		if(SplineMoveComp == nullptr)
			return false;
		
		return SplineMoveComp.IsInAir();
	}

	// We don't start using the MovementComponent until we have been mounted, because we may be attached to something
	bool bHasEverBeenMounted = false;

	bool bIsDead = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(!RootOffsetComp.RelativeLocation.IsNearlyZero())
		{
			AddActorLocalOffset(RootOffsetComp.RelativeLocation);
			RootOffsetComp.SetRelativeLocation(FVector(0, 0, 0));
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartCapabilitySheet(SketchbookGoatIdleSheet, this);

		UMovementGravitySettings::SetTerminalVelocity(this, Sketchbook::Goat::TerminalVelocity, this);

		PlayerAttachmentRoot.AddRelativeLocation(FVector(LenghtModifier, 0, 0));

		DrawableObjectComp.OnStartBeingDrawn.AddUFunction(this, n"OnBeingDrawn");

		UPlayerMovementComponent::Get(Game::GetOtherPlayer(CopyStencilDepthFrom)).AddMovementIgnoresActor(this, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("IsMounted", IsMounted());
		TemporalLog.Value("bHasEverBeenMounted", bHasEverBeenMounted);
		//FTransform Trans = GetGoatSplineMoveComp().SplinePosition.WorldTransform;
		//TemporalLog.Transform("SplineTransform", Trans);

#endif

		if(OtherGoat == nullptr)
			OtherGoat = GetOtherGoat();
	}

	UFUNCTION()
	void OnBeingDrawn()
	{
		const AHazePlayerCharacter CopyStencilDepthFromActor = Game::GetPlayer(CopyStencilDepthFrom);
		Mesh.SetRenderCustomDepth(true);
		Mesh.SetCustomDepthStencilValue(CopyStencilDepthFromActor.Mesh.CustomDepthStencilValue);
	}

	void Mount(USketchbookGoatPlayerComponent PlayerComp)
	{
		if(!HasControl())
			return;

		if(MountedPlayer != nullptr)
			return;

		CrumbMountPlayer(PlayerComp);
	}

	UFUNCTION(CrumbFunction)
	void CrumbMountPlayer(USketchbookGoatPlayerComponent PlayerComp)
	{
		PlayerComp.MountGoat(this);
	}

	void OnMounted(AHazePlayerCharacter Player)
	{
		if(!ensure(!IsMounted() && Player != nullptr))
			return;

		Mesh.SetRelativeLocation(FVector::ZeroVector);
		MountedPlayer = Player;
		SetActorControlSide(Player);
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);

		// Can't be attached while using movement component
		if(AttachParentActor != nullptr)
			DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		bHasEverBeenMounted = true;

		StopCapabilitySheet(SketchbookGoatIdleSheet, this);
		StartCapabilitySheet(SketchbookGoatMountedSheet, this);

		SetActorVelocity(FVector::ZeroVector);

		OnGoatMounted();

		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"HandleRespawn");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride, EInstigatePriority::High);

		SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintEvent)
	void OnGoatMounted() {}
	
	void OnDismounted(AHazePlayerCharacter Player)
	{
		if(!ensure(IsMounted() && MountedPlayer == Player))
			return;

		StopCapabilitySheet(SketchbookGoatMountedSheet, this);
		StartCapabilitySheet(SketchbookGoatIdleSheet, this);

		// FB TODO: Temp!
		AddActorCollisionBlock(this);

		MountedPlayer.ClearRespawnPointOverride(this);
		MountedPlayer = nullptr;

		SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
	}

	bool IsMounted() const
	{
		return MountedPlayer != nullptr;
	}

	FVector GetMovementInput() const
	{
		if(!IsMounted())
			return FVector::ZeroVector;

		return PlayerMoveComp.MovementInput;
	}

	FVector GetWorldRight() const
	{
		return FVector::RightVector.VectorPlaneProject(MovementWorldUp).GetSafeNormal(ResultIfZero = FVector::RightVector);
	}

	ASketchbookGoat GetOtherGoat() const
	{
		if(OtherGoat != nullptr)
			return OtherGoat;

		if(MountedPlayer == nullptr)
			return nullptr;

		auto OtherGoatComp = USketchbookGoatPlayerComponent::Get(MountedPlayer.OtherPlayer);
		if(OtherGoatComp == nullptr)
			return nullptr;

		if(!OtherGoatComp.HasMountedGoat())
			return nullptr;

		return OtherGoatComp.MountedGoat;
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OtherGoat = GetOtherGoat();
		if(OtherGoat != nullptr)
		{
			JumpZone = OtherGoat.JumpZone;

			if(OtherGoat.bPerchJumping)
			{
				PerchPointIndex = OtherGoat.PerchPointIndex;

				JumpZone = OtherGoat.PreviousJumpZone;
				if(OtherGoat.JumpZone != nullptr)
					JumpZone = OtherGoat.JumpZone;

				check(JumpZone != nullptr);
				
				bPerchJumping = true;
				bPerchWasForced = true;
				//RootOffsetComp.SetWorldRotation(FRotator(0, OtherGoat.RootOffsetComp.WorldRotation.Yaw, 0));
				OutLocation.RespawnTransform.SetLocation(JumpZone.JumpPoints[PerchPointIndex].ActorLocation);
				OutLocation.RespawnTransform.SetRotation(OtherGoat.ActorRotation);
				return true;
			}
		}


		auto ClosestSpline = Sketchbook::Goat::GetClosestSpline(Player.OtherPlayer.ActorLocation);

		UHazeSplineComponent SplineComp = Spline::GetGameplaySpline(ClosestSpline);
		if (SplineComp == nullptr)
		{
			devError("No spline specified to respawn on for RespawnOnSplineNearOtherPlayerVolume");
			return false;
		}

		OutLocation.RespawnPoint = nullptr;
		OutLocation.RespawnRelativeTo = nullptr;
		OutLocation.RespawnTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(Player.OtherPlayer.ActorLocation);

		float Distance = SplineComp.GetClosestSplineDistanceToWorldLocation(OutLocation.RespawnTransform.Location);

		if(Distance >= SplineComp.SplineLength - 100)
		{
			OutLocation.RespawnTransform = SplineComp.GetWorldTransformAtSplineDistance(SplineComp.SplineLength - 100);
		}
		else if(Distance <= 300)
		{
			OutLocation.RespawnTransform = SplineComp.GetWorldTransformAtSplineDistance(MinRespawnDistanceFromScreen);
		}

		OutLocation.bRecalculateOnRespawnTriggered = true;
		bPerchJumping = false;
		
		PreviousJumpZone = nullptr;
		PerchPointIndex = 0;

		return true;
	}

};

namespace Sketchbook::Goat
{
	TArray<ASketchbookGoat> GetGoats()
	{
		return TListedActors<ASketchbookGoat>().GetArray();
	}
}

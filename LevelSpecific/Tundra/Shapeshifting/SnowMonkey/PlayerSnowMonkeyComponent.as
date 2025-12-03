struct FTundraSnowMonkeyOnGroundSlamParams
{
	TArray<UTundraPlayerSnowMonkeyGroundSlamResponseComponent> ResponseComponents;
	ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType;
	FVector PlayerLocation;
}

struct FTundraSnowMonkeyTurnAroundAnimData
{
	bool bTurnaroundIsClockwise;
}

struct FTundraSnowMonkeyPunchInteractAnimData
{
	bool bPunchingThisFrame = false;
}

UCLASS(Abstract)
class UTundraPlayerSnowMonkeyComponent : UTundraPlayerShapeBaseComponent
{
	access ReadOnly = private, * (readonly);
	default ShapeType = ETundraShapeshiftShape::Big;

	UPROPERTY(Category = "Settings")
	TSubclassOf<ATundraPlayerSnowMonkeyActor> SnowMonkeyActorClass;
	
	UPROPERTY(Category = "Settings")
	UTundraPlayerSnowMonkeySettings DefaultSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CeilingCameraSettings;

	UPROPERTY(Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset ThrowOtherPlayerCameraSettings;

	UPROPERTY(Category = "Settings")
	UPlayerFloorMotionSettings FloorMotionSettings;

	UPROPERTY(Category = "Settings")
	UPlayerAirMotionSettings AirMotionSettings;

	UPROPERTY(Category = "Settings")
	UPlayerSprintSettings SprintSettings;

	UPROPERTY(Category = "Settings")
	UPlayerPoleClimbSettings PoleClimbSettings;

	UPROPERTY(Category = "Settings")
	USnowMonkeyLedgeGrabSettings LedgeGrabSettings;

	UPROPERTY(Category = "Settings")
	UPlayerSlideJumpSettings SlideJumpSettings;

	UPROPERTY(Category = "Settings")
	UPlayerPerchSettings PerchSettings;

	UPROPERTY(Category = "Settings")
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings BossPunchSettings;

	bool bIsInThrowMode = false;
	bool bJustCeilingClimbed = false;
	bool bJustSuckedUp = false;
	bool bCeilingMovementWasConstrained = false;
	ETundraPlayerSnowMonkeyTraversalPointType CustomWalkingMode = ETundraPlayerSnowMonkeyTraversalPointType::MAX;
	float TimeOfLastGroundSlam = -100.0;
	float TimeOfTurnIntoSnowMonkey = -100.0;
	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerSwingComponent SwingComp;
	bool bCurrentGroundSlamIsGrounded = false;
	bool bGroundedGroundSlamHandsHitGround = false;
	float TimeOfGroundSlamHandsHitGround = 0.0;
	bool bSnowMonkeyGravityUsed = false;
	bool bIsActive = false;
	bool bCanTriggerGroundedGroundSlam = false;
	bool bPunchInteractPerformed = false;
	access:ReadOnly UTundraPlayerSnowMonkeyCeilingClimbComponent CurrentCeilingComponent;
	bool bForceEnteredCurrentCeilingComp;
	FTundraSnowMonkeyTurnAroundAnimData TurnAroundAnimData;
	FTundraSnowMonkeyPunchInteractAnimData PunchInteractAnimData;
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent CurrentPunchInteractTargetable;
	UTundraPlayerSnowMonkeyCeilingClimbComponent CurrentAnimationCeilingComponent;
	UTundraPlayerSnowMonkeyCeilingClimbDataComponent CeilingClimbDataComponent;
	float TimeOfPunch = -100.0;
	bool bHasPunched = false;
	bool bInPunchInteractComboWindow = false;
	bool bIsInCeilingSuckup = false;
	bool bIsInCeilingCoyoteSuckup = false;
	float SuckupDuration;
	ETundraPlayerSnowMonkeyPunchInteractAnimationType CurrentPunchInteractAnimationType;
	uint FrameOfStopGroundSlam;
	uint FrameOfStopPunch;
	uint FrameOfEndSuckUp;
	FVector SuckUpVelocity;

	private TOptional<uint> FrameToForceClearGravity;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	ATundraPlayerSnowMonkeyActor SnowMonkeyActor;

	UTundraPlayerSnowMonkeySettings Settings;
	TArray<UTundraPlayerSnowMonkeyCeilingClimbComponent> TeleportedToCeilings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Settings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::Get(Player);
		CeilingClimbDataComponent = UTundraPlayerSnowMonkeyCeilingClimbDataComponent::GetOrCreate(Game::Mio);

		FHazeDevInputInfo TeleportToNextInfo;
		TeleportToNextInfo.Name = n"Teleport To Next Ceiling";
		TeleportToNextInfo.Category = n"Ceiling Climb";
		TeleportToNextInfo.OnTriggered.BindUFunction(this, n"OnDevTeleportToNextCeiling");
		TeleportToNextInfo.OnStatus.BindUFunction(this, n"OnStatusTeleportToNextCeiling");
		TeleportToNextInfo.AddKey(EKeys::Gamepad_FaceButton_Top);
		TeleportToNextInfo.AddKey(EKeys::Y);
		Player.RegisterDevInput(TeleportToNextInfo);

		FHazeDevInputInfo TeleportToClosest;
		TeleportToClosest.Name = n"Teleport To Closest Ceiling";
		TeleportToClosest.Category = n"Ceiling Climb";
		TeleportToClosest.OnTriggered.BindUFunction(this, n"OnDevTeleportToClosestCeiling");
		TeleportToClosest.AddKey(EKeys::Gamepad_FaceButton_Left);
		TeleportToClosest.AddKey(EKeys::T);
		Player.RegisterDevInput(TeleportToClosest);

		FHazeDevInputInfo RemoveLastCeiling;
		RemoveLastCeiling.Name = n"Remove Last Teleport To Next Ceiling";
		RemoveLastCeiling.Category = n"Ceiling Climb";
		RemoveLastCeiling.OnTriggered.BindUFunction(this, n"OnDevRemoveLastTeleportToNextCeiling");
		RemoveLastCeiling.AddKey(EKeys::Gamepad_FaceButton_Right);
		RemoveLastCeiling.AddKey(EKeys::G);
		Player.RegisterDevInput(RemoveLastCeiling);

		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);

		if(SnowMonkeyActorClass != nullptr)
		{
			SnowMonkeyActor = SpawnActor(SnowMonkeyActorClass, bDeferredSpawn = true);
			SnowMonkeyActor.Player = Player;
			FinishSpawningActor(SnowMonkeyActor);
			SnowMonkeyActor.MakeNetworked(this, n"_SnowMonkeyActor");

			SnowMonkeyActor.AttachToComponent(Player.Mesh);
			SnowMonkeyActor.ActorRelativeTransform = FTransform::Identity;
			Player.Mesh.LinkMeshComponentToLocomotionRequests(SnowMonkeyActor.Mesh);
			SnowMonkeyActor.Mesh.SetOverrideRootMotionReceiverComponent(Player.RootComponent);
			SnowMonkeyActor.AddActorDisable(ShapeshiftingComp);
			Outline::ApplyOutlineOnActor(SnowMonkeyActor, Game::Zoe, Outline::GetZoeOutlineAsset(), this, EInstigatePriority::Level);

			UPlayerRenderingSettingsComponent::GetOrCreate(Player).AdditionalSubsurfaceMeshes.Add(SnowMonkeyActor.Mesh);
		}
	}

	UFUNCTION()
	private void OnDevTeleportToNextCeiling()
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);
		UTundraPlayerSnowMonkeyCeilingClimbComponent ClosestCeiling;
		float ClosestSqrDistance = MAX_flt;
		FVector TopOfPlayerCapsule = Player.ActorLocation + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
		for(UTundraPlayerSnowMonkeyCeilingClimbComponent CeilingComp : CeilingClimbDataComponent.AllCeilings)
		{
			if(TeleportedToCeilings.Contains(CeilingComp))
				continue;

			FTundraPlayerSnowMonkeyCeilingData CeilingData = CeilingComp.GetCeilingData();
			const FVector ClosestPoint = CeilingData.GetClosestPointOnCeiling(TopOfPlayerCapsule);
			const float SqrDistanceToCeiling = ClosestPoint.DistSquared(TopOfPlayerCapsule);

			if(SqrDistanceToCeiling < ClosestSqrDistance)
			{
				ClosestSqrDistance = SqrDistanceToCeiling;
				ClosestCeiling = CeilingComp;
			}
		}

		if(ClosestCeiling == nullptr)
			return;

		TeleportedToCeilings.AddUnique(ClosestCeiling);
		FTundraPlayerSnowMonkeyCeilingData CeilingData = ClosestCeiling.GetCeilingData();
		CeilingData.Pushback += 100.0;
		FVector Point = CeilingData.GetClosestPointOnCeiling(Player.ActorLocation);
		Point += FVector::DownVector * (Player.CapsuleComponent.CapsuleHalfHeight * 2.0 + 1.0);
		Player.ActorLocation = Point;
		Player.SetActorVelocity(FVector::UpVector * 100.0);
	}

	UFUNCTION()
	private void OnStatusTeleportToNextCeiling(FString& OutDescription, FLinearColor& OutColor)
	{
		OutDescription = f"({CeilingClimbDataComponent.AllCeilings.Num() - TeleportedToCeilings.Num()} Left)";
		OutColor = FLinearColor::White;
	}

	UFUNCTION()
	private void OnDevTeleportToClosestCeiling()
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);
		UTundraPlayerSnowMonkeyCeilingClimbComponent ClosestCeiling;
		float ClosestSqrDistance = MAX_flt;
		FVector TopOfPlayerCapsule = Player.ActorLocation + FVector::UpVector * TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 2.0;
		for(UTundraPlayerSnowMonkeyCeilingClimbComponent CeilingComp : CeilingClimbDataComponent.AllCeilings)
		{
			FTundraPlayerSnowMonkeyCeilingData CeilingData = CeilingComp.GetCeilingData();
			const FVector ClosestPoint = CeilingData.GetClosestPointOnCeiling(TopOfPlayerCapsule);
			const float SqrDistanceToCeiling = ClosestPoint.DistSquared(TopOfPlayerCapsule);

			if(SqrDistanceToCeiling < ClosestSqrDistance)
			{
				ClosestSqrDistance = SqrDistanceToCeiling;
				ClosestCeiling = CeilingComp;
			}
		}

		if(ClosestCeiling == nullptr)
			return;

		FTundraPlayerSnowMonkeyCeilingData CeilingData = ClosestCeiling.GetCeilingData();
		CeilingData.Pushback += 100.0;
		FVector Point = CeilingData.GetClosestPointOnCeiling(Player.ActorLocation);
		Point += FVector::DownVector * (Player.CapsuleComponent.CapsuleHalfHeight * 2.0 + 1.0);
		Player.ActorLocation = Point;
		Player.SetActorVelocity(FVector::UpVector * 100.0);
	}

	UFUNCTION()
	private void OnDevRemoveLastTeleportToNextCeiling()
	{
		if(TeleportedToCeilings.Num() > 0)
			TeleportedToCeilings.RemoveAt(TeleportedToCeilings.Num() - 1);
	}

	AHazeCharacter GetShapeActor() const override
	{
		return SnowMonkeyActor;
	}

	UHazeCharacterSkeletalMeshComponent GetShapeMesh() const override
	{
		return SnowMonkeyActor.Mesh;
	}

	FVector2D GetShapeCollisionSize() const override
	{
		return TundraShapeshiftingStatics::SnowMonkeyCollisionSize;
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

	float GetToShapeGravityBlendTime() const override
	{
		return Settings.GravityBlendTime;
	}

	float GetFromShapeToPlayerGravityBlendTime() const override
	{
		return Settings.MonkeyToPlayerGravityBlendTime;
	}

	bool ShouldSnapGravity() const override
	{
		if(MoveComp.HasGroundContact())
			return true;

		if(PoleClimbComp.IsClimbing())
			return true;

		if(CurrentCeilingComponent != nullptr)
			return true;

		if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive)
			return true;

		if(WallRunComp.HasActiveWallRun())
			return true;

		if(SwimmingComp.IsSwimming())
			return true;

		if(SwingComp.HasActivateSwingPoint())
			return true;

		if(FrameToForceClearGravity.IsSet() && FrameToForceClearGravity.Value >= Time::FrameNumber - 1)
			return true;

		return false;
	}

	float GetShapePoleClimbMaxHeightOffset() const override
	{
		return PoleClimbSettings.MaxHeightOffset;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetCeilingMovementWasConstrained(bool bNewState)
	{
		bCeilingMovementWasConstrained = bNewState;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTrySetCurrentCeilingComponent(UTundraPlayerSnowMonkeyCeilingClimbComponent NewCeilingComponent)
	{
		TrySetCurrentCeilingComponent(NewCeilingComponent);
	}

	// Will try to set the current ceiling component, if it isn't already set
	void TrySetCurrentCeilingComponent(UTundraPlayerSnowMonkeyCeilingClimbComponent NewCeilingComponent)
	{
		if(CurrentCeilingComponent == NewCeilingComponent)
			return;

		if(CurrentCeilingComponent != nullptr)
		{
			CurrentCeilingComponent.OnDeatch.Broadcast();
		}

		CurrentCeilingComponent = NewCeilingComponent;
		
		if(CurrentCeilingComponent != nullptr)
			TeleportedToCeilings.AddUnique(CurrentCeilingComponent);

		if(CurrentCeilingComponent != nullptr)
		{
			CurrentCeilingComponent.OnAttach.Broadcast();
		}
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	void GroundSlamZoe()
	{
		AHazePlayerCharacter Zoe = Game::GetZoe();

		if(UTundraPlayerSwingComponent::Get(Zoe) != nullptr)
		{
			if(UTundraPlayerSwingComponent::Get(Zoe).bIsActive)
				return;
		}

		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Zoe);
		if(ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big)
			return;
	

		if(Overlap::QueryShapeOverlap(
			Zoe.CapsuleComponent.GetCollisionShape(), 
			Zoe.CapsuleComponent.WorldTransform, 
			FCollisionShape::MakeSphere(50), 
			GetShapeMesh().GetSocketTransform(n"LeftHand"))
			)
			{
				Zoe.KillPlayer();
				return;
			}

		if(Overlap::QueryShapeOverlap(
			Zoe.CapsuleComponent.GetCollisionShape(), 
			Zoe.CapsuleComponent.WorldTransform, 
			FCollisionShape::MakeSphere(50), 
			GetShapeMesh().GetSocketTransform(n"RightHand"))
			)
			{
				Zoe.KillPlayer();
				return;
			}
	}

	void NotifyPunchTargetableComponent()
	{
		if(!HasControl())
			return;

		if(CurrentPunchInteractTargetable == nullptr)
			return;

		CrumbCallOnPunchEvent(CurrentPunchInteractTargetable);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCallOnPunchEvent(UTundraPlayerSnowMonkeyPunchInteractTargetableComponent Targetable)
	{
		Targetable.OnPunch.Broadcast(Player.ActorLocation);
		if(Targetable.NextPunchWillComplete())
		{
			Targetable.OnCompletedPunch.Broadcast(Player.ActorLocation);
			Targetable.Disable(this);
		}

		Targetable.AmountOfPunchesPerformed++;
		bHasPunched = true;
	}

	void NotifyGroundSlamResponseComponent(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, TArray<UTundraPlayerSnowMonkeyGroundSlamResponseComponent>&out ResponseComponents)
	{
		bCanTriggerGroundedGroundSlam = false;

		if(!HasControl())
			return;
		
		if(MoveComp.GroundContact.Actor != nullptr)
		{
			auto Response = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(MoveComp.GroundContact.Actor);
			if(IsGroundSlamResponseComponentValid(Response, nullptr))
			{
				ResponseComponents.AddUnique(Response);
			}
		}

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		Trace.UseSphereShape(Settings.GroundSlamRadius);
		Trace.IgnoreActor(Owner);
		FOverlapResultArray OverlapResult = Trace.QueryOverlaps(Cast<AHazePlayerCharacter>(Owner).ActorCenterLocation);
		for(auto Overlap : OverlapResult.OverlapResults)
		{
			auto Response = UTundraPlayerSnowMonkeyGroundSlamResponseComponent::Get(Overlap.Actor);

			if(IsGroundSlamResponseComponentValid(Response, Overlap.Component))
				ResponseComponents.AddUnique(Response);
		}

		FTundraSnowMonkeyOnGroundSlamParams Params;
		Params.ResponseComponents = ResponseComponents;
		Params.GroundSlamType = GroundSlamType;
		Params.PlayerLocation = Player.ActorLocation;

		CrumbCallOnGroundSlamEvent(Params);
	}
	
	bool IsGroundSlamResponseComponentValid(UTundraPlayerSnowMonkeyGroundSlamResponseComponent Response, UPrimitiveComponent Component)
	{
		bool bIsGroundImpact = Component == nullptr;
		
		if(Response == nullptr)
			return false;

		if(!Response.IsResponseComponentEnabled())
			return false;

		if(Response.ComponentsToTriggerOn.Num() > 0)
		{
			UPrimitiveComponent Comp = bIsGroundImpact ? Cast<UPrimitiveComponent>(MoveComp.GroundContact.Component) : Component;
			for(UPrimitiveComponent Current : Response.ComponentsToTriggerOn)
			{
				if(Current == Comp)
				{
					ECollisionResponse CollisionResponse = Current.GetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter);
					bool bTriggerOnlyOnGroundImpact = CollisionResponse == ECollisionResponse::ECR_Block;
					if(bTriggerOnlyOnGroundImpact)
					{
						if(bIsGroundImpact)
							return true;

						return false;
					}
					else
					{
						return true;
					}
				}
			}

			return false;
		}

		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbCallOnGroundSlamEvent(FTundraSnowMonkeyOnGroundSlamParams Params)
	{
		for(auto Comp : Params.ResponseComponents)
		{
			// This can happen on the remote side if the world is tearing down
			if(Comp == nullptr)
				continue;

			// Same thing here if the world is tearing down, the cast will fail
			if(Comp.Owner != nullptr)
			{
				FTundraPlayerSnowMonkeyGroundSlamResponseEffectParams EffectParams;
				EffectParams.GroundSlamType = Params.GroundSlamType;
				UTundraPlayerSnowMonkeyGroundSlamResponseEffectHandler::Trigger_OnGroundSlam(Cast<AHazeActor>(Comp.Owner), EffectParams);
			}

			if(!HasControl() && !Comp.bCallOnGroundSlamOnRemote)
				continue;

			Comp.OnGroundSlam.Broadcast(Params.GroundSlamType, Params.PlayerLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bJustCeilingClimbed)
		{
			if(MoveComp.HasGroundContact() || SwimmingComp.IsSwimming())
				bJustCeilingClimbed = false;
		}

		if(bJustSuckedUp)
		{
			if(MoveComp.HasGroundContact() || SwimmingComp.IsSwimming())
				bJustSuckedUp = false;
		}
	}

	UFUNCTION()
	void ForceClearGravity()
	{
		FrameToForceClearGravity.Set(Time::FrameNumber);
	}

	bool IsFarAwayInView()
	{
		if (Owner.ActorLocation.IsWithinDist(Player.ViewLocation, Settings.FXIsFarAwayDistance))
			return false;
		return true;
	}
}
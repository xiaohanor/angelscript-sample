struct FHoverPerchGrindSplineActivatedParams
{
	UHazeSplineComponent SplineComp;
	AHazePlayerCharacter PlayerEnteringGrind;
	AHoverPerchGrindSpline GrindSpline;
	FSplinePosition SplinePos;
	float EndZ;
	bool bBackwards;
}

class UHoverPerchGrindSplineCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	AHoverPerchActor PerchActor;
	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UHazeSplineComponent SplineComp;
	UPlayerMovementComponent PlayerMoveComp; 

	FVector GrindOffset;

	const float OffsetInterpSpeed = 2.0;
	const float UpwardsOffset = 40.0;
	const float SecondsActiveWhenCollisionIsDangerous = 2.0;
	const float GrindConnectionArrowAngle = 45.0;

	float CurrentSpeed = 0.0;
	float EndZ;

	bool bHasReachedEnd = false;

	FHazeAcceleratedRotator AccPerchCompRotation;
	TArray<USceneComponent> ConnectionArrowComponents;
	bool bIsConnectionArrowVisible = true;
	AHoverPerchConnectionGrindSpline ActiveMaterialConnectionGrind;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		PerchActor.GrindSwitcherArrowRoot.GetChildrenComponents(true, ConnectionArrowComponents);
		SetConnectionArrowVisible(false);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchGrindSplineActivatedParams& Params) const
	{
		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;

		if(PerchActor.ForcedGrind != nullptr)
		{
			AHoverPerchGrindSpline GrindSpline = PerchActor.ForcedGrind;
			auto GrindSplineComp = UHazeSplineComponent::Get(GrindSpline);
			FSplinePosition ClosestSplinePos = GrindSplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.BaseLocation);
			Params.SplineComp = GrindSplineComp;
			Params.PlayerEnteringGrind = PerchActor.HoverPerchComp.PerchingPlayer;
			Params.SplinePos = ClosestSplinePos;
			Params.EndZ = GrindSpline.EndZ;
			Params.GrindSpline = GrindSpline;
			Params.bBackwards = PerchActor.bForcedGrindBackward;
			return true;
		}

		if(DeactiveDuration < 1.0)
			return false;

		for(auto GrindSpline : PerchActor.GrindsCloseEnoughToCheck)
		{
			if(GrindSpline.bUseBoxForStart)
			{
				if(GrindSpline.IsInsideStartBox(PerchActor))
				{
					auto GrindSplineComp = UHazeSplineComponent::Get(GrindSpline);
					FSplinePosition ClosestSplinePos = GrindSplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.BaseLocation);
					Params.SplineComp = GrindSplineComp;
					Params.PlayerEnteringGrind = PerchActor.HoverPerchComp.PerchingPlayer;
					Params.SplinePos = ClosestSplinePos;
					Params.EndZ = GrindSpline.EndZ;
					Params.GrindSpline = GrindSpline;
					Params.bBackwards = GrindSpline.bGrindBackwards;
					return true;
				}
			}
			else
			{
				const float DistToPerchSqrd = PerchActor.BaseLocation.DistSquared(GrindSpline.GrindStart.WorldLocation);
				if(DistToPerchSqrd < Math::Square(GrindSpline.GrindEnterDistance))
				{
					auto GrindSplineComp = UHazeSplineComponent::Get(GrindSpline);
					FSplinePosition ClosestSplinePos = GrindSplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.BaseLocation);
					Params.SplineComp = GrindSplineComp;
					Params.PlayerEnteringGrind = PerchActor.HoverPerchComp.PerchingPlayer;
					Params.SplinePos = ClosestSplinePos;
					Params.EndZ = GrindSpline.EndZ;
					Params.GrindSpline = GrindSpline;
					Params.bBackwards = GrindSpline.bGrindBackwards;
					return true;
				}
			}
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(PerchActor.ForcedGrind != nullptr)
			return true;

		if(bHasReachedEnd)
		{
			if(!CurrentGrind.bConnectsToOtherSplines
			|| !CurrentGrind.bEndConnects
			|| CurrentGrind.EndConnectingGrind == nullptr)
			{
				return true;
			}
		}

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchGrindSplineActivatedParams Params)
	{
		TListedActors<AHoverPerchActor> ListedPerches;
		for(AHoverPerchActor Perch : ListedPerches.Array)
		{
			if(Perch == PerchActor)
				continue;

			MoveComp.AddMovementIgnoresActor(this, Perch);
		}

		PerchActor.BlockCapabilities(HoverPerchBlockedWhileIn::Grind, this);
		PerchActor.GrindSplinePos = Params.SplinePos;
		if(Params.bBackwards)
			PerchActor.GrindSplinePos.ReverseFacing();

		RecalculateGrindOffset();
		CurrentSpeed = PerchActor.ActorVelocity.Size();
		EndZ = Params.EndZ;
		CurrentGrind = Params.GrindSpline;
		Player = Params.PlayerEnteringGrind;
		SplineComp = Params.SplineComp;
		PerchActor.ForcedGrind = nullptr;

		SetNextConnectionIndex();
		
		PlayerMoveComp = UPlayerMovementComponent::Get(Params.PlayerEnteringGrind);

		//PlayerMoveComp.FollowComponentMovement(PerchActor.Root, this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::High);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::StickInput, CameraTags::CameraControl, this);
		Player.ApplyCameraSettings(PerchActor.GrindCameraSettings, 0.5, this, EHazeCameraPriority::High);
		Player.ApplyBlendToCurrentView(1.0);
		Player.PlayCameraShake(PerchActor.GrindCameraShake, this);

		AccPerchCompRotation.SnapTo(PerchActor.PerchComp.WorldRotation);
		
		FHoverPerchOnStartGrindingEffectParams GrindEffectParams;
		GrindEffectParams.GrindAttachComponent = PerchActor.AttachmentRoot;
		UHoverPerchEffectHandler::Trigger_OnStartGrinding(PerchActor, GrindEffectParams);

		if(HasConnections())
			CurrentGrind.GrindConnections.Sort();

		bHasReachedEnd = false;
		PerchActor.HoverPerchComp.bIsGrinding = true;

		PerchActor.OnGrindSwitchDirectionOnHitOtherPerch.AddUFunction(this, n"CrumbOnSwitchDirection");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
		PerchActor.UnblockCapabilities(HoverPerchBlockedWhileIn::Grind, this);
		if(HasControl())
		{
			if(bHasReachedEnd)
				PerchActor.CrumbSetBaseZValue(EndZ);
		}

		PerchActor.SwayTimer = PerchActor.SwayDuration * 0.75;

		CurrentGrind = nullptr;

		//PlayerMoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
		PlayerMoveComp.ClearMovementInput(this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(CapabilityTags::StickInput, this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ApplyBlendToCurrentView(1.0);
		Player.StopCameraShakeByInstigator(this);

		UHoverPerchEffectHandler::Trigger_OnStoppedGrinding(PerchActor);

		PerchActor.HoverPerchComp.bIsGrinding = false;
		PerchActor.HoverPerchComp.TimeLastStoppedGrinding = Time::GameTimeSeconds;

		PerchActor.OnGrindSwitchDirectionOnHitOtherPerch.Unbind(this, n"CrumbOnSwitchDirection");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				PerchActor.PreviousGrindSplinePos = PerchActor.GrindSplinePos;

				CurrentSpeed = Math::FInterpTo(CurrentSpeed, CurrentGrind.GrindMaxSpeed * PerchActor.InstigatedGrindSpeedMultiplier.Value, DeltaTime, CurrentGrind.GrindAcceleration);
				float RemainingDelta = CurrentSpeed * DeltaTime;
				auto TemporalLog = TEMPORAL_LOG(Player, "Hover Perch Grinding");
				if(HasConnections())
				{
#if EDITOR
					FSplinePosition NextConnectionSplinePos = PerchActor.GrindSplinePos.CurrentSpline.GetSplinePositionAtSplineDistance(CurrentGrind.GrindConnections[PerchActor.NextGrindConnectionIndex].SplineDistance);
					TemporalLog
						.Sphere("Next Connection Location", NextConnectionSplinePos.WorldLocation, 50, FLinearColor::Purple, 10)
						.Value("Next Connection Index", PerchActor.NextGrindConnectionIndex)
					;

					if(PerchActor.bDebugDrawConnections)
					{
						if(IsSteeringTowardsConnection(PerchActor.NextGrindConnectionIndex))
						{
							Debug::DrawDebugSphere(NextConnectionSplinePos.WorldLocation, 100, 12, FLinearColor::Green, 20, 0.0);
							Debug::DrawDebugString(NextConnectionSplinePos.WorldLocation, "Steering towards Connection", FLinearColor::Green);
						}
						else
						{
							Debug::DrawDebugSphere(NextConnectionSplinePos.WorldLocation, 100, 12, FLinearColor::Red, 20, 0.0);
							Debug::DrawDebugString(NextConnectionSplinePos.WorldLocation, "Steering away from Connection", FLinearColor::Red);
						}

						if(!IsGoingTowardsConnectionStartDirection(PerchActor.NextGrindConnectionIndex))
						{
							Debug::DrawDebugString(NextConnectionSplinePos.WorldLocation + FVector::UpVector * 100, "Is Going the wrong way from connection!", FLinearColor::Red);
						}
					}
#endif

					if(WillPassNextConnectionThisFrame(RemainingDelta))
					{
						auto Connection = CurrentGrind.GrindConnections[PerchActor.NextGrindConnectionIndex];
						if(!Connection.bRequireSteering
						|| (IsSteeringTowardsConnection(PerchActor.NextGrindConnectionIndex) && IsGoingTowardsConnectionStartDirection(PerchActor.NextGrindConnectionIndex)))
						{
							float DeltaToConnection = Math::Abs(Connection.SplineDistance - PerchActor.GrindSplinePos.CurrentSplineDistance);
							RemainingDelta -= DeltaToConnection;
							TemporalLog
								.Value("Remaining Delta to Connection", DeltaToConnection)
							;
							StartGrindingOnNextConnection();
						}
						else
							IncrementNextConnectionIndex();		
					}
				}

				float RemainingDistance = 0.0;
				bHasReachedEnd = !PerchActor.GrindSplinePos.Move(RemainingDelta, RemainingDistance);

				GrindOffset = Math::VInterpTo(GrindOffset, FVector::ZeroVector, DeltaTime, OffsetInterpSpeed);
				if(bHasReachedEnd)
				{
					if(PerchActor.GrindSplinePos.CurrentSpline.IsClosedLoop())
					{
						LoopSplinePosition();
						PerchActor.GrindSplinePos.Move(RemainingDistance);
						Movement.AddDelta(TargetLocation - PerchActor.BaseLocation);
					}
					else
					{
						if(TryConnectingToEndGrind())
						{
							PerchActor.GrindSplinePos.Move(RemainingDistance);
							Movement.AddDelta(TargetLocation - PerchActor.BaseLocation);
						}
						else
							Movement.AddDelta(PerchActor.GrindSplinePos.WorldForwardVector * (CurrentSpeed + RemainingDistance) * DeltaTime);
					}
				}
				else
					Movement.AddDelta(TargetLocation - PerchActor.BaseLocation);

				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, PerchActor.GrindSplinePos.WorldForwardVector), 5.0, false);

				PerchActor.SwayRoot.RelativeLocation = Math::VInterpTo(PerchActor.SwayRoot.RelativeLocation, FVector::DownVector * PerchActor.IdleSwayHeightOffset, DeltaTime, 5.0);
				PerchActor.MeshComp.AddLocalRotation(FRotator(0, (PerchActor.ActorVelocity.Size() / 2) * DeltaTime, 0));
				PerchActor.SyncedMeshRelativeRotation.Value = PerchActor.MeshComp.RelativeRotation;

				TemporalLog
					.Sphere("Spline Pos", PerchActor.GrindSplinePos.WorldLocation, 20, FLinearColor::Green, 5)
					.DirectionalArrow("Grind Offset", PerchActor.GrindSplinePos.WorldLocation, GrindOffset, 5, 2, FLinearColor::DPink)
					.Value("Current Speed", CurrentSpeed)
					.Value("Is Forward On Spline", PerchActor.GrindSplinePos.IsForwardOnSpline())
					.Value("Current Distance on Spline", PerchActor.GrindSplinePos.CurrentSplineDistance)
					.Value("Spline Length", PerchActor.GrindSplinePos.CurrentSpline.SplineLength)
					.Value("Remaining Distance", RemainingDistance);
				;

				if(MoveComp.HasWallContact()
				&& ActiveDuration >= SecondsActiveWhenCollisionIsDangerous)
				{
					auto OtherPerchActor = Cast<AHoverPerchActor>(MoveComp.WallContact.Actor);
					if(OtherPerchActor == nullptr
					|| PerchesAreGoingTowardsEachOther(OtherPerchActor))
					{
						if(OtherPerchActor != nullptr && CurrentGrind.bSwitchDirectionWhenHittingOtherHoverPerch)
						{
							PerchActor.OnGrindSwitchDirectionOnHitOtherPerch.Broadcast();
							OtherPerchActor.OnGrindSwitchDirectionOnHitOtherPerch.Broadcast();
						}
						else
						{
							// CrumbDestroyHoverPerch sets the velocity so we have to apply move before doing that.
							MoveComp.ApplyMove(Movement);
							PerchActor.DestroyHoverPerch();
							if(OtherPerchActor != nullptr)
								OtherPerchActor.DestroyHoverPerch();
							return;
						}
					}
				}

				ApplyGrindHaptic();
				PlayerMoveComp.ApplyMovementInput(PerchActor.GrindSplinePos.WorldForwardVector, this);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
				PerchActor.MeshComp.RelativeRotation = PerchActor.SyncedMeshRelativeRotation.Value;
			}
			MoveComp.ApplyMove(Movement);
		}

		if(HasControl())
		{
			PerchActor.BodyMeshComp.WorldRotation = Player.ActorRotation;
			PerchActor.SyncedBodyMeshWorldRotation.Value = PerchActor.BodyMeshComp.WorldRotation;
		}
		else
		{
			PerchActor.BodyMeshComp.WorldRotation = PerchActor.SyncedBodyMeshWorldRotation.Value;
		}

		//HandleConnectionSwitchArrow();
		HandleConnectionGrindMaterial();
	}

	private void HandleConnectionSwitchArrow()
	{
		if(!ShouldShowArrow())
		{
			SetConnectionArrowVisible(false);
			return;
		}

		SetConnectionArrowVisible(true);
		FVector MovementInput = MoveComp.MovementInput;
		FVector GrindForward = PerchActor.GrindSplinePos.WorldForwardVector;
		FVector ArrowForward = GrindForward.RotateAngleAxis(GrindConnectionArrowAngle * Math::Sign(MovementInput.DotProduct(PerchActor.ActorRightVector)), FVector::UpVector);
		PerchActor.GrindSwitcherArrowRoot.SetWorldRotation(FRotator::MakeFromXZ(ArrowForward, FVector::UpVector));
	}

	private void HandleConnectionGrindMaterial()
	{
		// Keep the material on the grind if we are currently grinding on it!
		if(CurrentGrind == ActiveMaterialConnectionGrind)
			return;
		
		int Index = -1;
		bool bResult = ShouldShowConnectionGrindMaterial(Index);
		SetConnectionGrindMaterialVisible(bResult, Index);
	}

	private bool ShouldShowConnectionGrindMaterial(int&out Index)
	{
		if(!HasConnections())
			return false;

		Index = GetSteeringTowardsConnectionIndex();
		if(Index < 0)
			return false;

		return true;
	}

	private void SetConnectionGrindMaterialVisible(bool bVisible, int ConnectionIndex)
	{
		if((!bVisible || CurrentGrind.GrindConnections[ConnectionIndex].ConnectingGrind == ActiveMaterialConnectionGrind) && bVisible == (ActiveMaterialConnectionGrind != nullptr))
			return;

		if(bVisible)
		{
			FHoverPerchGrindConnection Connection = CurrentGrind.GrindConnections[ConnectionIndex];
			auto NewGrind = Cast<AHoverPerchConnectionGrindSpline>(Connection.ConnectingGrind);
			devCheck(NewGrind != nullptr, "Tried to steer towards a connection that isn't of type AHoverPerchConnectionGrindSpline");

			// If we already have an active material grind, reset the materials on that grind
			if(ActiveMaterialConnectionGrind != nullptr)
				ActiveMaterialConnectionGrind.ResetMaterials(Player);
			ActiveMaterialConnectionGrind = NewGrind;

			FSplinePosition SplinePositionOfConnection = FSplinePosition(PerchActor.GrindSplinePos.CurrentSpline, Connection.SplineDistance, PerchActor.GrindSplinePos.IsForwardOnSpline());
			FSplinePosition InitialSplinePosOfConnection = FSplinePosition(Connection.ConnectingGrind.Spline, Connection.bStartBackwards ? Connection.ConnectingGrind.Spline.SplineLength : 0.0, !Connection.bStartBackwards);

			EHoverPerchConnectionGrindMaterialType MaterialType;
			EHoverPerchConnectionGrindMeshSide Side;
			if(SplinePositionOfConnection.WorldRightVector.DotProduct(InitialSplinePosOfConnection.WorldForwardVector) > 0.0) // Connection spline extends to the right of our current spline
			{
				MaterialType = EHoverPerchConnectionGrindMaterialType::RightArrow;
				Side = EHoverPerchConnectionGrindMeshSide::Right;
			}
			else // Connection spline extends to the left of our current spline
			{
				MaterialType = EHoverPerchConnectionGrindMaterialType::LeftArrow;
				Side = EHoverPerchConnectionGrindMeshSide::Left;
			}

			// Swap side if entering from back of spline
			if(!InitialSplinePosOfConnection.IsForwardOnSpline())
				Side = SwapSide(Side);

			ActiveMaterialConnectionGrind.SetMaterial(MaterialType, Side, Player);
		}
		else
		{
			ActiveMaterialConnectionGrind.ResetMaterials(Player);
			ActiveMaterialConnectionGrind = nullptr;
		}
	}

	private EHoverPerchConnectionGrindMeshSide SwapSide(EHoverPerchConnectionGrindMeshSide Side)
	{
		if(Side == EHoverPerchConnectionGrindMeshSide::Left)
			return EHoverPerchConnectionGrindMeshSide::Right;
		
		return EHoverPerchConnectionGrindMeshSide::Left;
	}

	private int GetSteeringTowardsConnectionIndex() const
	{
		int Index = PerchActor.NextGrindConnectionIndex;
		for(int i = 0; i < 8; i++)
		{
			if(IsGoingTowardsConnectionStartDirection(Index) && IsSteeringTowardsConnection(Index))
				return Index;

			if(PerchActor.GrindSplinePos.IsForwardOnSpline())
				Index++;
			else
				Index--;

			Index = Math::WrapIndex(Index, 0, CurrentGrind.GrindConnections.Num());
		}

		return -1;
	}

	private bool ShouldShowArrow()
	{
		if(!HasConnections())
			return false;

		if(!IsGoingTowardsConnectionStartDirection(PerchActor.NextGrindConnectionIndex))
			return false;

		if(!IsSteeringTowardsConnection(PerchActor.NextGrindConnectionIndex))
			return false;

		return true;
	}

	private void SetConnectionArrowVisible(bool bVisible)
	{
		if(bVisible == bIsConnectionArrowVisible)
			return;

		for(USceneComponent Comp : ConnectionArrowComponents)
		{
			if(bVisible)
				Comp.RemoveComponentVisualsBlocker(this);
			else
				Comp.AddComponentVisualsBlocker(this);
		}

		bIsConnectionArrowVisible = bVisible;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSwitchDirection()
	{
		PerchActor.GrindSplinePos.ReverseFacing();
		PerchActor.PreviousGrindSplinePos = PerchActor.GrindSplinePos;
		PerchActor.PlayerLocker.DamagePlayerHealth(CurrentGrind.PlayerDamageToApplyWhenSwitchingDirectionOnHit);
		PerchActor.FrameOfSwitchGrindDirection.Set(Time::FrameNumber);
		SetNextConnectionIndex();
		FHoverPerchSwitchDirectionParams Params;
		Params.OtherPerchActor = HoverPerch::GetCurrentPerchForPlayer(Player.OtherPlayer);
		Params.PerchLocation = PerchActor.ActorLocation;
		UHoverPerchEffectHandler::Trigger_OnSwitchDirection(PerchActor, Params);
	}

	private void ApplyGrindHaptic()
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float BaseValue = 0.2;
		float NoiseBased = 0.1 * ((Math::PerlinNoise1D(Time::GameTimeSeconds * 2.5) + 1.0) * 0.5);
		
		float MotorStrength = (BaseValue + NoiseBased) * PerchActor.ForceFeedbackMultiplier;

		ForceFeedBack.LeftMotor = MotorStrength;
		Player.SetFrameForceFeedback(ForceFeedBack);
	}

	FVector GetTargetLocation() const property
	{
		return PerchActor.GrindSplinePos.WorldLocation + GrindOffset + FVector::UpVector * UpwardsOffset;
	}

	void RecalculateGrindOffset()
	{
		GrindOffset = PerchActor.BaseLocation - (PerchActor.GrindSplinePos.WorldLocation + FVector::UpVector * UpwardsOffset); 
	}

	void LoopSplinePosition()
	{
		if(PerchActor.GrindSplinePos.CurrentSplineDistance <= 0)
			PerchActor.GrindSplinePos = SplineComp.GetSplinePositionAtSplineDistance(SplineComp.SplineLength, PerchActor.GrindSplinePos.IsForwardOnSpline());
		else
			PerchActor.GrindSplinePos = SplineComp.GetSplinePositionAtSplineDistance(0, PerchActor.GrindSplinePos.IsForwardOnSpline());

		bHasReachedEnd = false;
	}

	bool PerchesAreGoingTowardsEachOther(AHoverPerchActor OtherHoverPerch) const
	{
		if(OtherHoverPerch.GrindSplinePos.CurrentSpline != PerchActor.GrindSplinePos.CurrentSpline)
			return false;

		if(OtherHoverPerch.GrindSplinePos.IsForwardOnSpline() == PerchActor.GrindSplinePos.IsForwardOnSpline())
			return false;

		const float SplineLength = PerchActor.GrindSplinePos.CurrentSpline.SplineLength;
		const float OurDist = PerchActor.GrindSplinePos.CurrentSplineDistance;
		const float OtherDist = OtherHoverPerch.GrindSplinePos.CurrentSplineDistance;
		const bool bOurForward = PerchActor.GrindSplinePos.IsForwardOnSpline();

		const float ForwardDist = bOurForward ? OurDist : OtherDist;
		const float BackDist = !bOurForward ? OurDist : OtherDist;

		if(!OtherHoverPerch.GrindSplinePos.CurrentSpline.IsClosedLoop())
		{
			float Diff = BackDist - ForwardDist;
			if(Math::Abs(Diff) > SplineLength * 0.5)
				Diff = (SplineLength - Math::Abs(Diff)) * -Math::Sign(Diff);

			if(Diff <= 0.0)
				return false;
		}
		else
		{
			if(ForwardDist > BackDist)
				return false;
		}

		return true;
	}

	bool TryConnectingToEndGrind()
	{
		if(!CurrentGrind.bConnectsToOtherSplines
		|| !CurrentGrind.bEndConnects
		|| CurrentGrind.EndConnectingGrind == nullptr)
			return false;

		FHoverPerchGrindSplineActivatedParams NewParams;
		if(PerchActor.GrindSplinePos.IsForwardOnSpline())
		{
			auto ConnectingGrind = CurrentGrind.EndConnectingGrind;
			NewParams.bBackwards = CurrentGrind.bEndConnectsBackwards; 
			NewParams.EndZ = ConnectingGrind.EndZ;
			NewParams.GrindSpline = ConnectingGrind;
			NewParams.PlayerEnteringGrind = Player;
			NewParams.SplineComp = UHazeSplineComponent::Get(ConnectingGrind);
			NewParams.SplinePos = NewParams.SplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.GrindSplinePos.WorldLocation);
		}
		else
		{
			auto ConnectingGrind = CurrentGrind.StartConnectingGrind;
			NewParams.bBackwards = CurrentGrind.bStartConnectsBackwards; 
			NewParams.EndZ = ConnectingGrind.EndZ;
			NewParams.GrindSpline = ConnectingGrind;
			NewParams.PlayerEnteringGrind = Player;
			NewParams.SplineComp = UHazeSplineComponent::Get(ConnectingGrind);
			NewParams.SplinePos = NewParams.SplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.GrindSplinePos.WorldLocation);
		}
		

		bHasReachedEnd = false;
		CrumbStartOnGrind(NewParams);
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartOnGrind(FHoverPerchGrindSplineActivatedParams Params)
	{
		PerchActor.GrindSplinePos = Params.SplinePos;
		if(PerchActor.GrindSplinePos.IsForwardOnSpline())
		{
			if(Params.bBackwards)
				PerchActor.GrindSplinePos.ReverseFacing();
		}
		else
		{
			if(!Params.bBackwards)
				PerchActor.GrindSplinePos.ReverseFacing();
		}

		PerchActor.PreviousGrindSplinePos = PerchActor.GrindSplinePos;
		RecalculateGrindOffset(); 
		CurrentSpeed = PerchActor.ActorVelocity.Size();
		EndZ = Params.EndZ;
		CurrentGrind = Params.GrindSpline;
		SplineComp = Params.SplineComp;
		CurrentGrind.GrindConnections.Sort();
		SetNextConnectionIndex();

		auto ConnectionGrind = Cast<AHoverPerchConnectionGrindSpline>(Params.GrindSpline);
		if(ConnectionGrind != nullptr)
		{
			FHoverPerchEnterGrindEffectParams EffectParams;
			EffectParams.GrindSpline = ConnectionGrind;
			EffectParams.PerchLocation = PerchActor.ActorLocation;
			UHoverPerchEffectHandler::Trigger_OnEnterConnectionGrindSpline(PerchActor, EffectParams);
		}
	}

	void SetNextConnectionIndex()
	{
		auto GrindSpline = CurrentGrind;
		if(PerchActor.GrindSplinePos.IsForwardOnSpline())
		{
			for(int i = 0; i < GrindSpline.GrindConnections.Num(); ++i)
			{
				auto GrindConnection = GrindSpline.GrindConnections[i];
				if(GrindConnection.SplineDistance > PerchActor.GrindSplinePos.CurrentSplineDistance)
				{
					PerchActor.NextGrindConnectionIndex = i;
					return;
				}
			}
			// None was found
			if(PerchActor.GrindSplinePos.CurrentSpline.IsClosedLoop())
			{
				PerchActor.NextGrindConnectionIndex = 0;
			}
		}
		else
		{
			for(int i = GrindSpline.GrindConnections.Num() - 1; i >= 0; --i)
			{
				auto GrindConnection = GrindSpline.GrindConnections[i];
				if(GrindConnection.SplineDistance < PerchActor.GrindSplinePos.CurrentSplineDistance)
				{
					PerchActor.NextGrindConnectionIndex = i;
					return;
				}
			}
			// None was found
			if(PerchActor.GrindSplinePos.CurrentSpline.IsClosedLoop())
			{
				PerchActor.NextGrindConnectionIndex = GrindSpline.GrindConnections.Num() - 1;
			}
		}
	}

	void IncrementNextConnectionIndex()
	{
		for(int i = 0; i < 4; i++)
		{
			if(PerchActor.GrindSplinePos.IsForwardOnSpline())
				PerchActor.NextGrindConnectionIndex++;
			else
				PerchActor.NextGrindConnectionIndex--;

			PerchActor.NextGrindConnectionIndex = Math::WrapIndex(PerchActor.NextGrindConnectionIndex, 0, CurrentGrind.GrindConnections.Num());

			if(IsGoingTowardsConnectionStartDirection(PerchActor.NextGrindConnectionIndex))
				break;
		}
	}

	bool HasConnections() const
	{
		return CurrentGrind.GrindConnections.Num() > 0;
	}

	bool WillPassNextConnectionThisFrame(float RemainingDelta) const
	{
		auto GrindSpline = CurrentGrind;
		auto GrindConnection = GrindSpline.GrindConnections[PerchActor.NextGrindConnectionIndex];

		TEMPORAL_LOG(Player, "Hover Perch Grind Swapping")
			.Value("Current Spline Distance", PerchActor.GrindSplinePos.CurrentSplineDistance)
			.Value("Next Connection Spline Distance", GrindConnection.SplineDistance)
			.Value("Remaining Delta", RemainingDelta)
		;

		if(PerchActor.GrindSplinePos.IsForwardOnSpline())
		{	
			if(PerchActor.GrindSplinePos.CurrentSplineDistance < GrindConnection.SplineDistance
			&& PerchActor.GrindSplinePos.CurrentSplineDistance + RemainingDelta > GrindConnection.SplineDistance)
			{
				return true;
			}
		}
		else
		{
			if(PerchActor.GrindSplinePos.CurrentSplineDistance > GrindConnection.SplineDistance
			&& PerchActor.GrindSplinePos.CurrentSplineDistance - RemainingDelta < GrindConnection.SplineDistance)
			{
				return true;
			}
		}

		return false;
	}

	bool IsSteeringTowardsConnection(int ConnectionIndex) const
	{
		FVector MovementInput = MoveComp.MovementInput;
		if(MovementInput.IsNearlyZero(0.1))
			return false;

		auto Connection = CurrentGrind.GrindConnections[ConnectionIndex];
		FSplinePosition SplinePositionOfConnection = FSplinePosition(CurrentGrind.Spline, Connection.SplineDistance, PerchActor.GrindSplinePos.IsForwardOnSpline());
		FSplinePosition InitialSplinePosOfConnection = FSplinePosition(Connection.ConnectingGrind.Spline, Connection.bStartBackwards ? Connection.ConnectingGrind.Spline.SplineLength : 0.0, !Connection.bStartBackwards);
		
		auto TemporalLog = TEMPORAL_LOG(Player, "Hover Perch Grind Swapping");
		TemporalLog
			.Transform("Spline Position Of Connection", SplinePositionOfConnection.WorldTransform, 200, 5.0)
			.Transform("Initial Spline Pos Of Connection", InitialSplinePosOfConnection.WorldTransform, 200, 5.0)
		;

		bool bConnectionIsToTheRight = SplinePositionOfConnection.WorldRightVector.DotProduct(InitialSplinePosOfConnection.WorldForwardVector) > 0;
		TemporalLog.Value("Connection is to the Right", bConnectionIsToTheRight);
		if(bConnectionIsToTheRight)
		{
			if(MovementInput.DotProduct(PerchActor.ActorRightVector) > 0.3)
				return true;
		}
		else
		{
			if(MovementInput.DotProduct(PerchActor.ActorRightVector) < -0.3)
				return true;
		}

		return false;
	}

	bool IsGoingTowardsConnectionStartDirection(int ConnectionIndex) const
	{
		auto Connection = CurrentGrind.GrindConnections[ConnectionIndex];
		if(PerchActor.GrindSplinePos.IsForwardOnSpline())
		{
			if(Connection.bRequireComeFromBackwards)
				return false;
			else
				return true;
		}
		else
		{
			if(Connection.bRequireComeFromBackwards)
				return true;
			else
				return false;
		}
		// auto ConnectionSplineComp = UHazeSplineComponent::Get(Connection.ConnectingGrind);
		// FSplinePosition ClosestSplinePos = ConnectionSplineComp.GetClosestSplinePositionToWorldLocation(SplinePos.WorldLocation);
		// if(ClosestSplinePos.CurrentSplineDistance > ConnectionSplineComp.SplineLength * 0.5)
		// 	ClosestSplinePos.ReverseFacing();

		// if(PerchActor.ActorVelocity.DotProduct(ClosestSplinePos.WorldForwardVector) > 0)
		// 	return true;

		// return false;
	}

	void StartGrindingOnNextConnection()
	{
		auto Connection = CurrentGrind.GrindConnections[PerchActor.NextGrindConnectionIndex];
		auto ConnectingGrind = Connection.ConnectingGrind;
		FHoverPerchGrindSplineActivatedParams NewParams;

		NewParams.bBackwards = Connection.bStartBackwards; 
		NewParams.EndZ = ConnectingGrind.EndZ;
		NewParams.GrindSpline = ConnectingGrind;
		NewParams.PlayerEnteringGrind = Player;
		NewParams.SplineComp = UHazeSplineComponent::Get(ConnectingGrind);
		NewParams.SplinePos = NewParams.SplineComp.GetClosestSplinePositionToWorldLocation(PerchActor.GrindSplinePos.WorldLocation);

		CrumbStartOnGrind(NewParams);
	}

	AHoverPerchGrindSpline GetCurrentGrind() const property
	{ 
		return PerchActor.CurrentGrind;
	}

	void SetCurrentGrind(AHoverPerchGrindSpline Grind) property
	{
		if(PerchActor.CurrentGrind == Grind)
			return;

		if(PerchActor.CurrentGrind != nullptr)
			PerchActor.CurrentGrind.StopGrinding(PerchActor);

		if(Grind != nullptr)
			Grind.StartGrinding(PerchActor);
		
		PerchActor.CurrentGrind = Grind;
	}
}
enum EIslandTravelerType
{
	/* Traveler type None can enter any portal */
	None,
	/* Traveler type Red can enter portals with type Red or Both */
	Red,
	/* Traveler type Blue can enter portals with type Blue or Both */
	Blue
}

struct FIslandPortalTravelerDebugIgnoredActors
{
	FIslandPortalTravelerDebugIgnoredActors(TArray<AActor> In_IgnoredActors)
	{
		IgnoredActors = In_IgnoredActors;
	}

	TArray<AActor> IgnoredActors;
}

class UIslandPortalTravelerComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(EditAnywhere)
	EIslandTravelerType TravelerType = EIslandTravelerType::None;

	/* If true, the component wont do any automatic teleporting */
	UPROPERTY(EditDefaultsOnly)
	bool bIsProjectile = false;

	UPROPERTY(EditAnywhere)
	bool bKillWhenEnteringWrongPortal = false;

	AIslandPortalManager Manager;
	UHazeMovementComponent MoveComp;
	FVector PreviousLocation;
	TArray<AIslandPortal> TrackedPortals;
	uint FrameOfLastTeleport;

	UPROPERTY()
	FIslandPortalOnEnterSignature OnEnterPortal;

	UPROPERTY()
	FIslandPortalOnPlayerEnterSignature OnPlayerEnterPortal;

	// AIslandPortal SuperPositionPortal;
	// AIslandPortalPlayerCopy PlayerCopy;
	TMap<AIslandPortal, FIslandPortalTravelerDebugIgnoredActors> IgnoredActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AIslandPortalManager> ListedManagers;
		Manager = ListedManagers.Single;
		if(Manager == nullptr)
		{
			// There is no manager in this level! Don't activate!
			SetComponentTickEnabled(false);
			return;
		}

		MoveComp = UHazeMovementComponent::Get(Owner);
		SetComponentTickEnabled(!bIsProjectile);
		PreviousLocation = OwnerLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!CanTick())
			return;

		FVector CurrentLocation = OwnerLocation;
		GetTrackedPortals(TrackedPortals, true);

		// if (Owner.IsA(AHazePlayerCharacter))
		// {
		// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		// 	AIslandPortal NewSuperPositionPortal;

		// 	// Find which portal to be in superposition for
		// 	for (AIslandPortal Portal : Manager.Portals)
		// 	{
		// 		if(Portal.IsActorDisabled())
		// 			continue;
		// 		if(!bKillWhenEnteringWrongPortal && !CanEnterPortal(Portal))
		// 			continue;

		// 		FVector LocalPosition = Portal.ActorTransform.InverseTransformPosition(OwnerLocation);
		// 		FBox LocalBounds = Portal.LocalBoundingBox;

		// 		FVector ClosestLocalPoint = LocalBounds.GetClosestPointTo(LocalPosition);
		// 		float ClosestDistance = LocalPosition.Distance(ClosestLocalPoint);
		// 		if (ClosestDistance < Player.CapsuleComponent.ScaledCapsuleHalfHeight)
		// 		{
		// 			NewSuperPositionPortal = Portal;
		// 			break;
		// 		}
		// 	}

		// 	// Update the visibility of the player copy
		// 	if (NewSuperPositionPortal != SuperPositionPortal)
		// 	{
		// 		if (NewSuperPositionPortal != nullptr)
		// 		{
		// 			if (PlayerCopy == nullptr)
		// 			{
		// 				PlayerCopy = SpawnActor(AIslandPortalPlayerCopy);
		// 				PlayerCopy.Init(Player);
		// 			}

		// 			PlayerCopy.RemoveActorDisable(this);
		// 		}
		// 		else if (SuperPositionPortal != nullptr)
		// 		{
		// 			PlayerCopy.AddActorDisable(this);
		// 		}

		// 		SuperPositionPortal = NewSuperPositionPortal;
		// 	}

		// 	// Update location of player copy
		// 	if (SuperPositionPortal != nullptr)
		// 	{
		// 		FVector NewLocation = IslandPortal::TransformPositionToPortalSpace(SuperPositionPortal, SuperPositionPortal.DestinationPortal, OwnerLocation);
		// 		FRotator NewRotation = IslandPortal::TransformRotationToPortalSpace(SuperPositionPortal, SuperPositionPortal.DestinationPortal, Owner.ActorRotation);

		// 		PlayerCopy.SetActorLocationAndRotation(NewLocation, NewRotation);
		// 	}
		// }

		for(int i = 0; i < TrackedPortals.Num(); i++)
		{
			AIslandPortal Portal = TrackedPortals[i];
			if(HasControl() && HasEnteredPortal(Portal, PreviousLocation, CurrentLocation))
			{
				TryTeleport(Portal, Portal.DestinationPortal);
				break;
			}
		}

#if !RELEASE
		TemporalLogTrackedPortals(PreviousLocation, CurrentLocation);
#endif

		if(Time::FrameNumber != FrameOfLastTeleport)
			RemoveUntrackedPortals(TrackedPortals);

		PreviousLocation = OwnerLocation;
	}

	bool HasEnteredPortal(AIslandPortal Portal, FVector PreviousLoc, FVector CurrentLoc) const
	{
		if(!PortalShouldBeTracked(Portal, false))
			return false;

		// Check if traveler has entered portal
		FTransform RelevantTransform = Portal.bAllowPortalEnteringTraveler ? Portal.PreviousPortalTransform : Portal.ActorTransform;
		FVector RelativePreviousLocation = RelevantTransform.InverseTransformPositionNoScale(PreviousLoc);
		FVector RelativeCurrentLocation = Portal.ActorTransform.InverseTransformPositionNoScale(CurrentLoc);
		
		if(Math::Sign(RelativeCurrentLocation.X) == Math::Sign(RelativePreviousLocation.X))
			return false;

		return true;
	}

	void GetTrackedPortals(TArray<AIslandPortal>& OutPortals, bool bIgnoreActors = false)
	{
		for(AIslandPortal Portal : Manager.Portals)
		{
			if(!PortalShouldBeTracked(Portal))
				continue;

			if(bIgnoreActors)
				TryIgnoreActors(Portal);

			if(OutPortals.Contains(Portal))
				continue;
			
			OutPortals.Add(Portal);
		}
	}

	void RemoveUntrackedPortals(TArray<AIslandPortal>& OutPortals, bool bClearIgnoredActors = true)
	{
		for(int i = OutPortals.Num() - 1; i >= 0; i--)
		{
			AIslandPortal Portal = OutPortals[i];
			if(PortalShouldBeTracked(Portal))
				continue;

			if(bClearIgnoredActors)
				ClearIgnoredActors(Portal);

			OutPortals.RemoveAt(i);
		}
	}

#if !RELEASE
	private void TemporalLogTrackedPortals(FVector PreviousLoc, FVector CurrentLoc)
	{
		TArray<AIslandPortal> FutureTrackedPortals = TrackedPortals;
		RemoveUntrackedPortals(FutureTrackedPortals, false);

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		const FString GeneralCategory = "1#General";
		TemporalLog.Point(f"{GeneralCategory};Previous World Location", PreviousLoc, 1.0, FLinearColor::Red);
		TemporalLog.Point(f"{GeneralCategory};Current World Location", CurrentLoc, 1.0, FLinearColor::Green);
		TemporalLog.Value(f"{GeneralCategory};Frame Of Last Teleport", FrameOfLastTeleport);

		for(int i = 0; i < TrackedPortals.Num(); i++)
		{
			AIslandPortal Portal = TrackedPortals[i];
			FTransform PortalTransform = Portal.ActorTransform;
			bool bPortalRemovedThisFrame = !FutureTrackedPortals.Contains(Portal);
			FLinearColor Color = bPortalRemovedThisFrame ? FLinearColor::Yellow : FLinearColor::Green;

			FVector RelativePreviousLocation = Portal.PreviousPortalTransform.InverseTransformPositionNoScale(PreviousLoc);
			FVector RelativeCurrentLocation = Portal.ActorTransform.InverseTransformPositionNoScale(CurrentLoc);

			FVector BoxWorldOrigin = PortalTransform.TransformPosition(Portal.LocalBoundingBox.Center);
			FVector WorldScaledExtents = Portal.LocalBoundingBox.Extent * Portal.ActorScale3D;
			WorldScaledExtents.X = 0.0;

			FString Category = f"Tracked Portal {i}";
			TemporalLog.Value(f"{Category};Name", Portal.ActorNameOrLabel);
			TemporalLog.Box(f"{Category};Bounds", BoxWorldOrigin, WorldScaledExtents, PortalTransform.Rotator(), Color);
			TemporalLog.DirectionalArrow(f"{Category};Forward", Portal.ActorCenterLocation, Portal.ActorForwardVector * 100.0);
			TemporalLog.Value(f"{Category};Relative Previous Location", RelativePreviousLocation);
			TemporalLog.Value(f"{Category};Relative Current Location", RelativeCurrentLocation);

			if(IgnoredActors.Contains(Portal))
			{
				TArray<AActor>& Actors = IgnoredActors[Portal].IgnoredActors;
				for(int j = 0; j < Actors.Num(); j++)
				{
					AActor IgnoredActor = Actors[j];
					TemporalLog.Value(f"{Category};IgnoredActors[{j}]", IgnoredActor);
				}

				if(Actors.Num() == 0)
					TemporalLog.Value(f"{Category};IgnoredActors.Num() == 0", "");
			}
			else
			{
				TemporalLog.Value(f"{Category};Actors Weren't Ignored!", "");
			}
		}
	}
#endif

	bool CanProjectileEnterPortal(AIslandPortal Portal, FVector PrevLoc, FVector NewLoc)
	{
		if(Portal.PortalNormal.DotProduct(NewLoc - PrevLoc) >= 0.0)
			return false;

		return CanEnterPortal(Portal);
	}

	void GetProjectileLocationOnOtherSide(AIslandPortal Portal, FVector ProjectileImpactLocation, FVector ProjectileDeltaFinalLocation, FVector&out StartTrace, FVector&out EndTrace)
	{
		StartTrace = IslandPortal::TransformPositionToPortalSpace(Portal, Portal.DestinationPortal, ProjectileImpactLocation);
		EndTrace = IslandPortal::TransformPositionToPortalSpace(Portal, Portal.DestinationPortal, ProjectileDeltaFinalLocation);
	}

	FVector GetDirectionOnOtherSide(AIslandPortal Portal, FVector Direction)
	{
		return IslandPortal::TransformVectorToPortalSpace(Portal, Portal.DestinationPortal, Direction);
	}

	FVector GetPointOnOtherSide(AIslandPortal Portal, FVector Point)
	{
		return IslandPortal::TransformPositionToPortalSpace(Portal, Portal.DestinationPortal, Point);
	}

	bool CanEnterPortal(AIslandPortal Portal) const
	{
		if(TravelerType == EIslandTravelerType::None)
			return true;

		if(Portal.PortalType == EIslandPortalType::Both)
			return true;

		if(Portal.PortalType == EIslandPortalType::Red && TravelerType == EIslandTravelerType::Red)
			return true;

		if(Portal.PortalType == EIslandPortalType::Blue && TravelerType == EIslandTravelerType::Blue)
			return true;

		return false;
	}

	bool PortalShouldBeTracked(AIslandPortal Portal, bool bCheckIfBehind = true) const
	{
		if(Portal.IsActorDisabled())
			return false;

		if(!bKillWhenEnteringWrongPortal && !CanEnterPortal(Portal))
			return false;

		FVector Location = OwnerLocation;
		FVector CurrentRelativeLocation = Portal.ActorTransform.InverseTransformPosition(Location);

		if(bCheckIfBehind && CurrentRelativeLocation.X < 0.0)
			return false;

		if(!IsInsideBoxYZ(Portal.LocalBoundingBox, CurrentRelativeLocation))
			return false;

		return true;
	}

	bool IsInsideBoxYZ(FBox Box, FVector In) const
	{
		return ((In.Y >= Box.Min.Y) && (In.Y <= Box.Max.Y) && (In.Z >= Box.Min.Z) && (In.Z <= Box.Max.Z));
	}

	/* Will attempt to teleport if we can enter this portal, otherwise we will kill the traveler */
	void TryTeleport(AIslandPortal OriginPortal, AIslandPortal DestinationPortal)
	{
		if(ShouldKillTraveler(OriginPortal))
		{
			KillTraveler();
			return;
		}

		Teleport(OriginPortal, DestinationPortal);
	}

	void Teleport(AIslandPortal OriginPortal, AIslandPortal DestinationPortal)
	{
		if(!HasControl())
			return;

		auto HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner == nullptr)
		{
			FVector NewLocation = IslandPortal::TransformPositionToPortalSpace(OriginPortal, DestinationPortal, Owner.ActorLocation);
			FRotator NewRotation = IslandPortal::TransformRotationToPortalSpace(OriginPortal, DestinationPortal, Owner.ActorRotation);
			CrumbTeleport(OriginPortal, DestinationPortal, NewLocation, NewRotation, FVector::ZeroVector);
		}
		else
		{
			auto Player = Cast<AHazePlayerCharacter>(HazeOwner);

			FVector PreTeleportVelocity = HazeOwner.ActorVelocity;
			FVector NewVelocity;

			if(Player != nullptr && DestinationPortal.bFixedPlayerVelocityWhenExitingPortal)
			{
				NewVelocity = DestinationPortal.ActorTransform.TransformVectorNoScale(DestinationPortal.LocalPlayerVelocityWhenExitingPortal);
			}
			else
			{
				NewVelocity = IslandPortal::TransformVectorToPortalSpace(OriginPortal, DestinationPortal, PreTeleportVelocity);
			}

			if(DestinationPortal.bConstrainOutgoingVelocityToPortalNormal)
			{
				NewVelocity = DestinationPortal.PortalNormal * DestinationPortal.PortalNormal.DotProduct(NewVelocity);
			}

			if(DestinationPortal.MinVelocityOutOfPortal > 0.0)
			{
				float Speed = DestinationPortal.PortalNormal.DotProduct(NewVelocity);
				if(Speed < DestinationPortal.MinVelocityOutOfPortal)
				{
					float SpeedToAdd = DestinationPortal.MinVelocityOutOfPortal - Speed;
					NewVelocity = DestinationPortal.PortalNormal * SpeedToAdd;
				}
			}

			FVector NewLocation = IslandPortal::TransformPositionToPortalSpace(OriginPortal, DestinationPortal, HazeOwner.ActorCenterLocation);
			FRotator NewRotation = IslandPortal::TransformRotationToPortalSpace(OriginPortal, DestinationPortal, HazeOwner.ActorRotation);

			FVector OldLocation = HazeOwner.ActorLocation;
			FVector OldCenterLocation = HazeOwner.ActorCenterLocation;
			FVector CenterOffset = HazeOwner.ActorLocation - HazeOwner.ActorCenterLocation;
			NewLocation += CenterOffset;

			CrumbTeleport(OriginPortal, DestinationPortal, NewLocation, NewRotation, NewVelocity);

#if !RELEASE
			TEMPORAL_LOG(this)
			.Value(f"Teleport;Origin Portal", OriginPortal.ActorNameOrLabel)
			.Value(f"Teleport;Destination Portal", DestinationPortal.ActorNameOrLabel)
			.DirectionalArrow(f"Teleport;Pre Teleport Velocity", OldCenterLocation, PreTeleportVelocity)
			.DirectionalArrow(f"Teleport;Post Teleport Velocity", NewLocation - CenterOffset, NewVelocity, Color = FLinearColor::Green)
			.Point(f"Teleport;Pre Teleport Location", OldLocation, 20.f)
			.Point(f"Teleport;Post Teleport Location", NewLocation, 20.f, FLinearColor::Green)
			.Value(f"Teleport;Distance Into Origin Portal", -OriginPortal.ActorForwardVector.DotProduct(OldLocation - OriginPortal.ActorLocation))
			;
#endif
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTeleport(AIslandPortal OriginPortal, AIslandPortal DestinationPortal, FVector Location, FRotator Rotation, FVector Velocity)
	{
		auto HazeOwner = Cast<AHazeActor>(Owner);
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if(HazeOwner == nullptr)
		{
			Owner.SetActorLocationAndRotation(Location, Rotation.Quaternion(), true);
		}
		else
		{
			FRotator NewRotation = FRotator::MakeFromXZ(Rotation.ForwardVector, HazeOwner.MovementWorldUp);

			HazeOwner.TeleportActor(Location, NewRotation, this, false);

			// Force any stored movement directions to reset since velocity is different now.
			HazeOwner.BlockCapabilities(CapabilityTags::Movement, this);
			HazeOwner.UnblockCapabilities(CapabilityTags::Movement, this);
			HazeOwner.ActorVelocity = Velocity;
		}

		OriginPortal.OnEnterPortal.Broadcast(Owner, OriginPortal, DestinationPortal);
		OnEnterPortal.Broadcast(Owner, OriginPortal, DestinationPortal);
		if(Player != nullptr)
		{
			UIslandPortalPlayerComponent::GetOrCreate(Player).bRotatePlayerTowardsWorldUp = true;

			if(OriginPortal.ConsumeAirJumpDashType == EIslandPortalConsumeAirJumpDashType::Reset)
			{
				Player.ResetAirJumpUsage();
				Player.ResetAirDashUsage();
			}
			else if(OriginPortal.ConsumeAirJumpDashType == EIslandPortalConsumeAirJumpDashType::Consume)
			{
				Player.ConsumeAirJumpUsage();
				Player.ConsumeAirDashUsage();
			}

			OriginPortal.OnPlayerEnterPortal.Broadcast(Player, OriginPortal, DestinationPortal);
			OnPlayerEnterPortal.Broadcast(Player, OriginPortal, DestinationPortal);

			Player.PlayForceFeedback(OriginPortal.BoostFeedback, false, false, this);

			FIslandPortalPlayerEnterEffectParams Params;
			Params.OriginPortal = OriginPortal;
			Params.DestinationPortal = DestinationPortal;
			Params.Player = Player;
			UIslandPortalEffectHandler::Trigger_OnPlayerEnter(OriginPortal, Params);

			if(OriginPortal.ShouldClosePortalWhenPlayerEntering())
				OriginPortal.ClosePortal();
		}

		GetTrackedPortals(TrackedPortals, true);
		FrameOfLastTeleport = Time::FrameNumber;
	}

	bool ShouldKillTraveler(AIslandPortal Portal) const
	{
		return bKillWhenEnteringWrongPortal && !CanEnterPortal(Portal);
	}

	void KillTraveler()
	{
		if(Owner.IsA(AHazePlayerCharacter))
			Cast<AHazePlayerCharacter>(Owner).KillPlayer();
		else if(Owner.IsA(AIslandRedBlueWeaponBullet))
			Cast<AIslandRedBlueWeaponBullet>(Owner).Kill();
		else if(Owner.IsA(AIslandRedBlueStickyGrenade))
			Cast<AIslandRedBlueStickyGrenade>(Owner).ResetGrenade(true);
		else
			devError("Tried to kill traveler but a kill method hasn't been defined!");
	}

	bool CanTick()
	{
		if(Owner.IsA(AHazePlayerCharacter))
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			if(Player.IsPlayerDead())
				return false;
		}

		return true;
	}

	void TryIgnoreActors(AIslandPortal Portal)
	{
		if(MoveComp != nullptr)
		{
			if(IgnoredActors.Contains(Portal))
			{
				if(IgnoredActors[Portal].IgnoredActors == Portal.ActorsToIgnoreWhenEnteringPortal)
					return;

				ClearIgnoredActors(Portal);
			}

			MoveComp.AddMovementIgnoresActors(Portal, Portal.ActorsToIgnoreWhenEnteringPortal);
			IgnoredActors.Add(Portal, FIslandPortalTravelerDebugIgnoredActors(Portal.ActorsToIgnoreWhenEnteringPortal));

			if(Portal.bIgnoreDeathVolumesBehindPortal)
			{
				auto Player = Cast<AHazePlayerCharacter>(Owner);
				if(Player != nullptr)
				{
					for(AActor Actor : Portal.ActorsToIgnoreWhenEnteringPortal)
					{
						auto Volume = Cast<ADeathVolume>(Actor);
						if(Volume != nullptr)
							Volume.DisableForPlayer(Player, Portal);
					}
				}
			}
		}
		else
			devError("Tried to ignore actors on traveler but no ignore method has been defined!");
	}

	void ClearIgnoredActors(AIslandPortal Portal)
	{
		if(MoveComp != nullptr)
		{
			MoveComp.RemoveMovementIgnoresActor(Portal);
			IgnoredActors.Remove(Portal);

			if(Portal.bIgnoreDeathVolumesBehindPortal)
			{
				auto Player = Cast<AHazePlayerCharacter>(Owner);
				if(Player != nullptr)
				{
					for(AActor Actor : Portal.ActorsToIgnoreWhenEnteringPortal)
					{
						auto Volume = Cast<ADeathVolume>(Actor);
						if(Volume != nullptr)
							Volume.EnableForPlayer(Player, Portal);
					}
				}
			}
		}
		else
			devError("Tried to clear ignore actors on traveler but no clear ignore method has been defined!");
	}

	FVector GetOwnerLocation() const property
	{
		auto HazeActor = Cast<AHazeActor>(Owner);
		if(HazeActor != nullptr)
			return HazeActor.ActorCenterLocation;

		return Owner.ActorLocation;
	}
}
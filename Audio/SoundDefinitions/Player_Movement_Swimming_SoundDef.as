
UCLASS(Abstract)
class UPlayer_Movement_Swimming_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Underwater_DashStarted(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Underwater_Stopped(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Underwater_Started(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_DashStarted(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_JumpedOut(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_Breached(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_Impacted(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_SkydiveImpacted(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_Stopped(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_Started(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Surface_Dive(FSwimmingEffectEventData Data){}

	UFUNCTION(BlueprintEvent)
	void Underwater_ExitBypassedSurface(FSwimmingEffectEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerAirMotionComponent AirMotionComp;
	UPlayerSwimmingComponent SwimComp;
	UPlayerMovementAudioComponent MoveAudioComp;

	const float MAX_FALL_TRACKING_DISTANCE = 1000;
	float StartFallDistance = MAX_FALL_TRACKING_DISTANCE; 

	bool GetbIsFalling() const property
	{
		return MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Falling);
	}

	const float CAMERA_BELOW_SURFACE_VERTICAL_BUFFER_DISTANCE = 60.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AirMotionComp = UPlayerAirMotionComponent::Get(PlayerOwner);
		SwimComp = UPlayerSwimmingComponent::Get(PlayerOwner);
		MoveAudioComp = UPlayerMovementAudioComponent::Get(PlayerOwner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveAudioComp.IsDefaultMovementBlocked())
			return false;

		//if(!AirMotionComp.AirMotionData.bDiveDetected)
		//	return false;

		if(!AirMotionComp.AirMotionData.bDiveDetected && !IsSwimming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsSwimming() && !bIsFalling && !AirMotionComp.AirMotionData.bDiveDetected)
			return true;

		if(MoveAudioComp.IsDefaultMovementBlocked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(SwimComp.GetState() == EPlayerSwimmingState::Underwater && !PlayerOwner.IsPlayerDead())
			Underwater_ExitBypassedSurface(FSwimmingEffectEventData());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bIsFalling)
		{
			FHazeTraceSettings Trace;
			Trace.TraceWithPlayer(PlayerOwner);
			Trace.IgnoreActors(Game::GetPlayers());
			Trace.UseCapsuleShape(PlayerOwner.CapsuleComponent.CapsuleRadius, PlayerOwner.CapsuleComponent.CapsuleHalfHeight);
			if(IsDebugging())
				Trace.DebugDrawOneFrame();

			auto TraceEnd = PlayerOwner.ActorCenterLocation + ((PlayerOwner.MovementWorldUp * -1) * MAX_FALL_TRACKING_DISTANCE);			
			auto Overlaps = Trace.QueryTraceMultiUntilBlock(PlayerOwner.ActorCenterLocation, TraceEnd);
			for(auto& Overlap : Overlaps)
			{
				auto SurfaceVolume = Cast<ASwimmingVolume>(Overlap.Actor);
				if(SurfaceVolume == nullptr)
					continue;				

				StartFallDistance = Math::Max(Overlap.Distance, StartFallDistance);
				break;				
			}	
		}
		else if(!AirMotionComp.AirMotionData.bDiveDetected)
		{
			StartFallDistance = -1;
		}
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Swimming"))
	bool IsSwimming() const
	{
		return SwimComp.IsSwimming();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Surface Fall Distance"))
	float GetSurfaceFallDistanceNormalized()
	{
		return Math::Saturate(StartFallDistance / MAX_FALL_TRACKING_DISTANCE);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Camera is below surface"))
	bool GetCameraIsBelowSurface()
	{
		FPlayerSwimmingSurfaceData Data;
		if (!SwimComp.CheckForSurface(PlayerOwner, Data))
			return false;

		// Compare camera and surface world location on z axis, to see if camera is under surface of swimming volume		
		ASwimmingVolume Volume = Data.SwimmingVolume;
		const FVector VolumeTop = Volume.BrushComponent.BoundsOrigin + (FVector::UpVector * Volume.BrushComponent.BoundsExtent.Z);

#if TEST
		if (IsDebugging())
		{
			auto VolumeTopAtPlayer = PlayerOwner.GetViewLocation();
			VolumeTopAtPlayer.Z = VolumeTop.Z;

			Debug::DrawDebugLine(VolumeTopAtPlayer, PlayerOwner.GetViewLocation(), FLinearColor::Red);
			Debug::DrawDebugString(VolumeTopAtPlayer, f"Camera Distance to water: {PlayerOwner.GetViewLocation().Z-VolumeTopAtPlayer.Z}");
		}
#endif

		// Camera in water!
		if(VolumeTop.Z > (PlayerOwner.GetViewLocation().Z + CAMERA_BELOW_SURFACE_VERTICAL_BUFFER_DISTANCE))
			return true;
	
		return false;
	}
}
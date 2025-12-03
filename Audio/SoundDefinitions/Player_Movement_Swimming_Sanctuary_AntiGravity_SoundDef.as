
UCLASS(Abstract)
class UPlayer_Movement_Swimming_Sanctuary_AntiGravity_SoundDef : USoundDefBase
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

	UHazeAudioEmitter AntiGravitySurfaceEmitter = nullptr;

	UPlayerAirMotionComponent AirMotionComp;
	UPlayerSwimmingComponent SwimComp;
	UPlayerMovementAudioComponent MoveAudioComp;
	// This might not exist when the SD is attached!
	USanctuaryAntiGravityPlayerComponent AntiGravityComponent = nullptr;

	const float MAX_FALL_TRACKING_DISTANCE = 1000;
	float StartFallDistance = MAX_FALL_TRACKING_DISTANCE; 

	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter GetSurfaceEmitter() property
	{
		return AntiGravitySurfaceEmitter;
	}

	bool GetbIsFalling() const property
	{
		// Don't care about falling.
		return false; //MoveAudioComp.CanPerformMovement(EMovementAudioFlags::Falling);
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
		if(!IsSwimming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveAudioComp.RequestBlockDefaultPlayerMovement(this);
		AntiGravityComponent = USanctuaryAntiGravityPlayerComponent::Get(PlayerOwner);

		FHazeAudioEmitterAttachmentParams Params;
		Params.bCanAttach = false;
		Params.Transform = FTransform(PlayerOwner.ActorCenterLocation);
		Params.Owner = PlayerOwner;
		Params.bSetOverrideTransform = true;
		Params.Instigator = this;
		Params.EmitterName = n"AntiGravity_Surface";

		AntiGravitySurfaceEmitter = Audio::GetPooledEmitter(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(SwimComp.GetState() == EPlayerSwimmingState::Underwater && !PlayerOwner.IsPlayerDead())
			Underwater_ExitBypassedSurface(FSwimmingEffectEventData());

		MoveAudioComp.UnRequestBlockDefaultPlayerMovement(this);
		AntiGravityComponent = nullptr;

		Audio::ReturnPooledEmitter(this, AntiGravitySurfaceEmitter);
		AntiGravitySurfaceEmitter = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Find the edge of the sphere and project the emitter position to it.
		if (AntiGravityComponent != nullptr && AntiGravitySurfaceEmitter != nullptr)
		{
			for (auto AntiGravityField : AntiGravityComponent.OverlappingFields)
			{
				if (AntiGravityField == nullptr)
					continue;
				
				auto CurrentRadius = AntiGravityField.AccRadius.Value;
				auto Direction = PlayerOwner.ActorCenterLocation - AntiGravityField.ActorCenterLocation;
				Direction.Normalize();

				auto NewLocation = AntiGravitySurfaceEmitter.AudioComponent.WorldLocation.MoveTowards(AntiGravityField.ActorCenterLocation + Direction * CurrentRadius, 1000 * DeltaSeconds);
				AntiGravitySurfaceEmitter.AudioComponent.SetWorldLocation(NewLocation);
			}
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
		// Find the edge of the sphere and project the emitter position to it.
		if (AntiGravityComponent != nullptr)
		{
			for (auto AntiGravityField : AntiGravityComponent.OverlappingFields)
			{
				if (AntiGravityField == nullptr)
					continue;
				
				auto CurrentRadius = AntiGravityField.AccRadius.Value;
				if (PlayerOwner.ViewLocation.DistSquared(AntiGravityField.ActorCenterLocation) < CurrentRadius* CurrentRadius)
					return true;
			}
		}
	
		return false;
	}
}
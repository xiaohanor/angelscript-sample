struct FFantasyOtterFootstepSurfaceEvents
{
	UPROPERTY()
	UHazeAudioEvent Plant = nullptr;

	UPROPERTY()
	UHazeAudioEvent Release = nullptr;
}



UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Tundra_FantasyOtter_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Plant(FTundraPlayerOtterFootstepParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnExitFloatingPoleCableInteract(){}

	UFUNCTION(BlueprintEvent)
	void OnEnterFloatingPoleCableInteract(){}

	UFUNCTION(BlueprintEvent)
	void OnLaunchSphereLaunch(FTundraPlayerOtterOnLaunchSphereLaunchEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnEnterLaunchSphere(FTundraPlayerOtterOnEnterLaunchSphereEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedOutOf(FTundraPlayerOtterTransformParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedInto(FTundraPlayerOtterTransformParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnBreakWaterSurface(){}

	UFUNCTION(BlueprintEvent)
	void OnUnderwaterSonarBlast(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	TMap<EHazeAudioPhysicalMaterialHardnessType, FFantasyOtterFootstepSurfaceEvents> SurfaceEvents;

	UPROPERTY(BlueprintReadOnly)
	TMap<FName, UHazeAudioEvent> AddEvents;

	UTundraPlayerOtterSwimmingComponent SwimComp;
	UHazeMovementComponent MoveComp;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	UPlayerSlideComponent SlideComp;

	private FRotator LastOtterHeadRotation;

	private FVector LastOtterLocation;
	private FVector CachedOtterVelo;

	private FVector LastOtterTailLocation;

	private FRotator LastRotation;
	private float RotationVerticalDelta;
	private float RotationHorizontalDelta;
	private float LastTailSpeed;

	private bool bWasSliding = false;

	USkeletalMeshComponent OtterMesh;
	UPlayerMovementAudioComponent PlayerMoveAudioComp;

	const float MAX_TAIL_RELATIVE_VELO = 40.0;
	const float MAX_HEAD_PITCH_DELTA = 50.0;
	const float MAX_HEAD_YAW_DELTA = 50.0;

	// Keep speed range to normalize over in sync with whatever is set in Otter Swim Anim-feature
	const float MAX_SURFACE_SWIM_SPEED = 1100;

	// Keep speed range to normalize over in sync with whatever is set in Otter Swim Anim-feature
	const float MAX_UNDERWATER_SWIM_SPEED = 1200;

	UFUNCTION(BlueprintEvent)
	void OnSurfaceBreach() {}

	private bool bWasSwimming = false;

	bool GetbIsInOtterForm() const property
	{
		return ShapeShiftComp.IsSmallShape();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bIsInOtterForm;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !bIsInOtterForm;
	}

	bool IsSwimming()  
	{
		if(SwimComp == nullptr)
		{
			SwimComp = UTundraPlayerOtterSwimmingComponent::Get(Player);
			if(SwimComp == nullptr)
				return false;
		}

		return SwimComp.IsSwimming();
	}

	UFUNCTION(BlueprintEvent)
	void OnActivatedUnderwater(bool bPostEvent = false) {};	
	
	UFUNCTION(BlueprintEvent)
	void OnResetDiveGate() {};	

	UFUNCTION(BlueprintEvent)
	void OnDeactivatedUnderwater() {};	

	UFUNCTION(BlueprintEvent)
	void OnSlidingStart(bool bIsIceSlide) {};

	UFUNCTION(BlueprintEvent)
	void OnSlidingStop() {};

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementAudio::RequestBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Falling);

		ProxyEmitterSoundDef::LinkToActor(this, Player);

		if(bWasSwimming)
		{
			if (IsSwimming())
				OnActivatedUnderwater(true);
			else
			{
				// OnDeactivatedUnderwater will block the OnBreakWaterSurface Gate, so open it again.
				// But only if we're not still in water, otherwise we will get a surface breach sound.
				OnResetDiveGate();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementAudio::RequestUnBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestUnBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestUnBlock(this, PlayerMoveAudioComp, EMovementAudioFlags::Falling);

		if(bWasSwimming && SwimComp.PreviousState == ETundraPlayerOtterSwimmingState::Underwater)
		{
			OnDeactivatedUnderwater();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Player = Game::GetMio();

		OtterMesh = USkeletalMeshComponent::Get(HazeOwner);		
		MoveComp = UHazeMovementComponent::Get(Player);
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IsSwimming())
		{
			TickSwimming(DeltaSeconds);		

			// Used to block normal player swimming SoundDef
			if(!bWasSwimming)
			{
				PlayerMoveAudioComp.RequestBlockDefaultPlayerMovement(this);
				OnActivatedUnderwater();
			}
		}
		else if(bWasSwimming)
		{
			PlayerMoveAudioComp.UnRequestBlockDefaultPlayerMovement(this);
			OnResetDiveGate();
		}

		FRotator OtterHeadRotation = OtterMesh.GetSocketRotation(MovementAudio::FantasyOtter::HeadSocketName);

		const FVector OtterLocation = HazeOwner.GetActorLocation();
		CachedOtterVelo = OtterLocation - LastOtterLocation;		

		LastOtterLocation = OtterLocation;
		LastOtterTailLocation = OtterMesh.GetSocketLocation(MovementAudio::FantasyOtter::TailSocketName); 

		RotationVerticalDelta = Math::Abs(OtterHeadRotation.Pitch - LastOtterHeadRotation.Pitch);	
		RotationHorizontalDelta = Math::Abs(OtterHeadRotation.Yaw - LastOtterHeadRotation.Yaw);
		LastOtterHeadRotation = OtterHeadRotation;

		bWasSwimming = IsSwimming();

		QuerySliding();
	}

	private void QuerySliding()
	{
		const bool bIsSliding = MoveComp.IsOnAnyGround() && SlideComp.IsSlideActive();
		if(bIsSliding && !bWasSliding)
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			TraceSettings.IgnoreActor(HazeOwner);
			TraceSettings.IgnoreActor(Player);
			auto PhysMat = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.ConvertToHitResult(), TraceSettings);		
			
			bool bIsIceSlide = false;
			if(PhysMat != nullptr)
			{
				bIsIceSlide = PhysMat.Name.ToString().Contains("Ice");
			}
			
			OnSlidingStart(bIsIceSlide);
			
		}
		else if(!bIsSliding && bWasSliding)
		{
			OnSlidingStop();
		}

		bWasSliding = bIsSliding;
	}

	UFUNCTION(BlueprintPure)
	float GetRelativeHeadRotationDelta()
	{
		const FRotator HeadRotation = OtterMesh.GetSocketRotation(MovementAudio::FantasyOtter::HeadSocketName);
		const float AngularDistance = HeadRotation.Quaternion().AngularDistance(LastOtterHeadRotation.Quaternion());
		const float AngularDistanceNormalized = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(0.0, 1.0), AngularDistance);
		
		return AngularDistanceNormalized;
	}

	UFUNCTION(BlueprintPure)
	float GetSwimmingDirectionPitchDelta()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HEAD_PITCH_DELTA), FVector2D(0.0, 1.0), RotationVerticalDelta);
	}

	UFUNCTION(BlueprintPure)
	float GetSwimmingDirectionYawDelta()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HEAD_PITCH_DELTA), FVector2D(0.0, 1.0), RotationVerticalDelta);
	}

	UFUNCTION(BlueprintPure)
	void GetRelativeTailVelocity(float&out Speed, float&out Delta)
	{
		const FVector TailVelo = (OtterMesh.GetSocketLocation(MovementAudio::FantasyOtter::TailSocketName) - LastOtterTailLocation) - CachedOtterVelo;
		const float VeloSpeed = TailVelo.Size();

		Speed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_TAIL_RELATIVE_VELO), FVector2D(0.0, 1.0), VeloSpeed);
		Delta = Speed - LastTailSpeed;

		LastTailSpeed = Speed;
	}

	UFUNCTION(BlueprintPure)
	float GetNormalizedSwimmingSpeed()
	{
		if(!IsSwimming())
			return 0.0;
		
		const float MaxSpeed = SwimComp.CurrentState == ETundraPlayerOtterSwimmingState::Surface ? MAX_SURFACE_SWIM_SPEED : MAX_UNDERWATER_SWIM_SPEED;
		return Math::Min(1, Player.GetActorLocalVelocity().Size() / MaxSpeed);
	}

	UFUNCTION(BlueprintPure)
	float GetCameraInWaterValue()
	{
		FTundraPlayerOtterSwimmingSurfaceData Data;
		if (SwimComp == nullptr || !SwimComp.CheckForSurface(Player, Data))
			return 0;

		// Compare camera and surface world location on z axis, to see if camera is under surface of swimming volume
		
		ASwimmingVolume Volume = Data.SwimmingVolume;
		const FVector VolumeTop = Volume.GetActorLocation() + (FVector::UpVector * Volume.BrushComponent.BoundsExtent.Z);

		// Camera in water!
		if(VolumeTop.Z > Player.GetViewLocation().Z)
			return 1.0;
	
		return 0;
	}

	UFUNCTION(BlueprintPure)
	float GetVerticalVeloSpeed()
	{
		return Math::Abs(MoveComp.VerticalSpeed);
	}

	UFUNCTION(BlueprintEvent)
	void TickSwimming(float DeltaSeconds) {}

}
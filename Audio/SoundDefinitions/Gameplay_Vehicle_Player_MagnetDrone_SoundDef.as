
UCLASS(Abstract)
class UGameplay_Vehicle_Player_MagnetDrone_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void JumpStop(){}

	UFUNCTION(BlueprintEvent)
	void JumpStart(){}

	UFUNCTION(BlueprintEvent)
	void Detached(){}

	UFUNCTION(BlueprintEvent)
	void Attached(FMagnetDroneAttachmentParams AttachmentData){}

	UFUNCTION(BlueprintEvent)
	void AttractionCanceled(){}

	UFUNCTION(BlueprintEvent)
	void AttractionStarted(FMagnetDroneAttractionStartedParams AttractionData){}

	UFUNCTION(BlueprintEvent)
	void MagnetDroneDash(){}

	UFUNCTION(BlueprintEvent)
	void StartPreviewAttractionPath(FMagnetDronePreviewAttractionPathEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void StopPreviewAttractionPath(){}

	UFUNCTION(BlueprintEvent)
	void TickPreviewAttractionPath(FMagnetDronePreviewAttractionPathEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void NoMagneticSurfaceFound(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnShellMoveOut() {};

	UFUNCTION(BlueprintEvent)
	void OnContactMaterialChanged(const UPhysicalMaterialAudioAsset NewPhysMat) {};

	UFUNCTION()
	private void SetupMagnetShells()
	{
		CachedShells = ProcAnimComp.Shells;
	}

	FRotator CurrentRotation;
	FRotator LastRotation;	
	private float RotationSpeed;
	private float LastRotationSpeed;

	private float Acceleration = 0;
	private float LastAcceleration = 0;

	private UPhysicalMaterialAudioAsset FramePhysMat = nullptr;
	private UPhysicalMaterialAudioAsset LastPhysMat = nullptr;

	private TArray<FMagnetDroneProcAnimShell> CachedShells;
	private bool bWasGrounded = true;
	private bool bShouldQueryJumpApex = false;

	private FVector LastAirborneLocation;
	private FVector JumpApexLocation;

	UPROPERTY()
	UMagnetDroneComponent DroneComp;	
	UPROPERTY()
	UMagnetDroneProcAnimComponent ProcAnimComp;
	UHazeMovementComponent MoveComp;
	
	/*
	The range over which the speed of rotation is normalized to
	Small value = hit max speed faster
	Large value = hit max speed slower
	*/ 
	UPROPERTY(Category = "Rotation")
	float RotationNormalizationRange = 25.0;

	/*
	The range over which change in acceleration is normalized to
	Small value = reacting to change faster
	Large value = reacting to change slower 
	*/ 
	UPROPERTY(Category = "Rotation", Meta = (UIMin = 0.0, UIMax = 1.0))
	float AccelerationNormalizationRange = 0.3;

	UPROPERTY(Category = "AudioPhysMat")
	TMap<UPhysicalMaterialAudioAsset, UHazeAudioEvent> AudioPhysMatEvents;

	UPROPERTY(Category = "Collision")
	private float GroundedCollisionTimerDuration = 0.2;

	private float LastCollisionTime = 0;
	private bool bHadWallImpact = false;

	bool CanCallGroundedEvent()
	{
		if (Time::GetAudioTimeSince(LastCollisionTime) >= GroundedCollisionTimerDuration)
		{
			LastCollisionTime = Time::AudioTimeSeconds;
			return true;
		} 

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldPlayShellsInAndOut() const
	{
		return Math::IsNearlyZero(LastRotationSpeed, 0.2) == true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DroneComp = UMagnetDroneComponent::Get(HazeOwner);
		ProcAnimComp = UMagnetDroneProcAnimComponent::Get(HazeOwner);
		MoveComp = UHazeMovementComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Gotta delay this that capabilities have time to tick once
		Timer::SetTimer(this, n"SetupMagnetShells", 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Mesh doesn't exist the first frame.
		if (DroneComp.DroneMesh == nullptr)
			return;

		const FRotator CurrRotation = DroneComp.DroneMesh.GetWorldRotation();
		RotationSpeed = CurrRotation.Quaternion().AngularDistance(LastRotation.Quaternion()) / DeltaSeconds;
		RotationSpeed = Math::GetMappedRangeValueClamped(FVector2D(0, RotationNormalizationRange), FVector2D(0, 1), RotationSpeed);
		
		Acceleration = RotationSpeed - LastRotationSpeed;

		const int AccelSign = int(Math::Sign(Acceleration));
		Acceleration = Math::GetMappedRangeValueClamped(FVector2D(0, AccelerationNormalizationRange), FVector2D(0, 1), Math::Abs(Acceleration));
		Acceleration = Acceleration * AccelSign;

		LastRotation = CurrRotation;
		LastRotationSpeed = RotationSpeed;

		FramePhysMat = nullptr;
		QueryContactMaterial();
		LastPhysMat = FramePhysMat;

		// No point in checking any wallhit if we just collided with the ground (its the same sound).
		bool bGroundedEventCalled = false;

		bool bIsGrounded = MoveComp.HasImpactedGround();

		// Stay grounded while dead, prevents a landing on respawn
		if(PlayerOwner.IsPlayerDead())
			bIsGrounded = true;

		QueryOnGrounded(bIsGrounded, bGroundedEventCalled);
		bWasGrounded = bIsGrounded;

		if(!bIsGrounded)
			LastAirborneLocation = DroneComp.DroneCenterLocation;	

		const bool bHasWallImpact = MoveComp.HasImpactedWall();
		if(bHasWallImpact && !bHadWallImpact && !bGroundedEventCalled)
		{
			auto Speed = MoveComp.PreviousVelocity.Size();
			if(!Math::IsNearlyZero(Speed, 5) && CanCallGroundedEvent())
			{
				const float Velo = Math::Clamp(Speed / 850, 0.0, 1.0);
				OnGrounded(Velo);
			}
		}		

		bHadWallImpact = bHasWallImpact;
	}

	UFUNCTION(BlueprintEvent)
	void OnGrounded(float ImpactSpeed) {};

	private void QueryOnGrounded(const bool bInIsGrounded, bool& bEventCalled)
	{
		if(bWasGrounded && !bInIsGrounded)
		{
			bShouldQueryJumpApex = true;
		}
		else if(!bWasGrounded && bInIsGrounded && CanCallGroundedEvent())
		{
			const float VerticalDelta = JumpApexLocation.Z - DroneComp.DroneCenterLocation.Z;
			const float ImpactSpeed = Math::Clamp(VerticalDelta / 150.0, 0.0, 1.0);
			OnGrounded(ImpactSpeed);
			bEventCalled = true;
		}

		if(bShouldQueryJumpApex)
		{
			const bool bHasStartedFalling = DroneComp.DroneCenterLocation.Z < LastAirborneLocation.Z;
			if(bHasStartedFalling)
			{
				bShouldQueryJumpApex = false;
				JumpApexLocation = DroneComp.DroneCenterLocation;
			}
		}		
	}

	private void QueryContactMaterial()
	{
		FramePhysMat = GetPhysMat();

		if(LastPhysMat != nullptr && FramePhysMat != LastPhysMat)
		{
			OnContactMaterialChanged(FramePhysMat);
		}
	}

	UFUNCTION(BlueprintPure)
	void GetMagnetShellAlphas(float&out One,
						float&out Two,
						float&out Three,
						float&out Four,
						float&out Five)
	{
		if (ProcAnimComp.Shells.Num() == 0)
		{
			One = 	0;
			Two = 	0;
			Three = 0;
			Four = 	0;
			Five = 	0;
			return;
		}

		// Values can get a bit jittery at low velocities
		if (!Math::IsNearlyEqual(ProcAnimComp.Shells[0].AccMoveOut.Value, One, 0.1))
			One = ProcAnimComp.Shells[0].AccMoveOut.Value;
		if (!Math::IsNearlyEqual(ProcAnimComp.Shells[1].AccMoveOut.Value, Two, 0.1))
			Two = ProcAnimComp.Shells[1].AccMoveOut.Value;
		if (!Math::IsNearlyEqual(ProcAnimComp.Shells[2].AccMoveOut.Value, Three, 0.1))
			Three = ProcAnimComp.Shells[2].AccMoveOut.Value;
		if (!Math::IsNearlyEqual(ProcAnimComp.Shells[3].AccMoveOut.Value, Four, 0.1))
			Four = ProcAnimComp.Shells[3].AccMoveOut.Value;
		if (!Math::IsNearlyEqual(ProcAnimComp.Shells[4].AccMoveOut.Value, Five, 0.1))
			Five = ProcAnimComp.Shells[4].AccMoveOut.Value;
	}

	UFUNCTION(BlueprintPure)
	float GetShellMovementTreshold() const
	{
		return 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsGrounded()
	{
		return MoveComp.IsOnWalkableGround();
	}

	UFUNCTION(BlueprintPure)
	float GetHasStickInputMultiplier()
	{
		const FVector StickInput = DroneComp.MoveComp.GetSyncedMovementInputForAnimationOnly();
		return StickInput.IsNearlyZero() ? 0.0 : 1.0;
	}

	// The Audio-phys mat that the drone is rolling on
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Audio Phys Mat"))
	UPhysicalMaterialAudioAsset GetPhysMat()
	{
		if(FramePhysMat == nullptr)
			FramePhysMat = Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromHit(DroneComp.MoveComp.GroundContact.ConvertToHitResult(), FHazeTraceSettings()).AudioAsset);

		return FramePhysMat; 
	}

	// Get rotation speed normalized to 0 - 1 by range of RotationNormalizationRange
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Rotation Speed"))
	float GetRotationSpeed()
	{
		return RotationSpeed;
	}

	/* 
	Get acceleration normalized to -1 - 1 by range of AccelerationNormalizationRange
	1 = Accelerating at maximum range
	-1 = Deaccelerating at maximum range
	0 = No change in acceleration
	*/
	UFUNCTION(BlueprintPure, Meta = (DisplayName = "Acceleration"))
	float GetAcceleration()
	{
		return Acceleration;
	}
}
UCLASS(Abstract)
class ACutsceneMagnetDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent CollisionComp;
	default CollisionComp.SetSphereRadius(MagnetDrone::Radius * 0.5);
	default CollisionComp.SetCollisionProfileName(n"PlayerCharacter");

	UPROPERTY(DefaultComponent)
	UPoseableMeshComponent DroneMesh;
	default DroneMesh.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = DroneMesh)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent)
	private UMagnetDroneProcAnimComponent ProcAnimComp;

	UPROPERTY(EditDefaultsOnly)
	UDroneMovementSettings MovementSettings;

	UPROPERTY(EditDefaultsOnly)
	UMagnetDroneSettings MagnetDroneSettings;

#if EDITOR
	UPROPERTY(EditInstanceOnly)
	bool bLogRecording = true;
#endif

	UPROPERTY(EditInstanceOnly)
	bool bLogPlayback = false;

	UPROPERTY(BlueprintReadWrite, EditInstanceOnly, Interp)
	bool bJump = false;

	UPROPERTY(BlueprintReadWrite, EditInstanceOnly, Interp)
	bool bGrounded = true;

	UPROPERTY(EditInstanceOnly)
	UCutsceneMagnetDroneDataAsset RecordDataAsset;

#if EDITOR
	UPROPERTY(VisibleInstanceOnly, Transient)
	FMagnetDroneProcAnimFrame DebugCurrentFrame;
#endif

	bool bPreviousJump = false;
	FVector PreviousLocation;
	FHazeAcceleratedVector AccDroneMeshRelativeRight;
	float StartJumpCutsceneTime;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnSequencerRecordStart()
	{
		if(RecordDataAsset == nullptr)
			return;

		ResetRecording();
	}

	UFUNCTION(BlueprintOverride)
	void OnSequencerRecord(FHazeSequencerRecordParams RecordParams)
	{
		if(RecordDataAsset == nullptr)
			return;

		RecordFrame(RecordParams.TimeFromSectionStart, RecordParams.DeltaTime);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnSequencerEvaluation(FHazeSequencerEvalParams EvalParams)
	{
		if(RecordDataAsset == nullptr)
			return;

		PlaybackFrame(EvalParams.TimeFromSectionStart);
	}

#if EDITOR
	private void ResetRecording()
	{
		ProcAnimComp.Reset(DroneMesh);
		RecordDataAsset.Reset(ProcAnimComp);

		bJump = false;
		bPreviousJump = false;
		StartJumpCutsceneTime = -1;
		PreviousLocation = ActorLocation;
		
		DroneMesh.SetWorldRotation(ActorRotation);
		DroneMesh.RefreshBoneTransforms();
		AccDroneMeshRelativeRight.SnapTo(FVector::ZeroVector);

		if(bLogRecording)
			Log(n"CutsceneMagnetDrone", "===============\nReset Recording\n===============");
	}

	private void RecordFrame(float CutsceneTime, float DeltaTime)
	{
		if(bJump && !bPreviousJump)
			StartJumpCutsceneTime = CutsceneTime;

		FVector Velocity = FVector::ZeroVector;
		if(DeltaTime > KINDA_SMALL_NUMBER)
			Velocity = (ActorLocation - PreviousLocation) / DeltaTime;

		FQuat MeshRotation = DroneMesh.ComponentQuat;

		UpdateMeshRotation(MeshRotation, Velocity, DeltaTime);
		UpdateRollStraighten(MeshRotation, Velocity, DeltaTime);
		UpdateProcAnim(Velocity, CutsceneTime, DeltaTime);

		DroneMesh.SetWorldRotation(MeshRotation);

		FMagnetDroneProcAnimFrame RecordedFrame;
		RecordedFrame.Record(this, CutsceneTime);
		RecordDataAsset.RecordedFrames.Add(RecordedFrame);
		RecordDataAsset.FrameCount++;
		RecordDataAsset.MarkPackageDirty();

		bPreviousJump = bJump;
		PreviousLocation = ActorLocation;

		if(bLogRecording)
		{
			Log(
				n"CutsceneMagnetDrone",
				f"Recorded frame {RecordDataAsset.RecordedFrames.Num()}\n" +
				f"	Time {CutsceneTime}\n" +
				f"	DeltaTime {DeltaTime}\n" +
				f"	Velocity {Velocity}\n"
			);

			if(DeltaTime > KINDA_SMALL_NUMBER && !Math::IsNearlyEqual(DeltaTime, 1.0 / 30.0, 0.01))
				Warning(n"CutsceneMagnetDrone", f"Delta time is deviating from the expected frame rate of 30fps! Current FPS: {Math::RoundToFloat(1.0 / DeltaTime)}");
		}
	}
#endif

	private void PlaybackFrame(float TimeFromSectionStart)
	{
		FMagnetDroneProcAnimFrame CurrentFrame;
		if(RecordDataAsset.GetFrameAtTime(float32(TimeFromSectionStart), CurrentFrame, bLogPlayback))
		{
#if EDITOR
			DebugCurrentFrame = CurrentFrame;
#endif

			CurrentFrame.ApplyPlayback(this);
			return;
		}

#if EDITOR
		if(bLogPlayback)
			Error(n"CutsceneMagnetDrone", f"{this} failed to find a valid recorded frame to apply for time {TimeFromSectionStart}!");
#endif
	}

	private void UpdateMeshRotation(FQuat& MeshRotation, FVector Velocity, float DeltaTime)
	{
		MagnetDrone::UpdateMeshRotation(
			DeltaTime,
			FHitResult(),
			FVector::UpVector,
			Velocity,
			MovementSettings.RollMaxSpeed,
			CollisionComp.SphereRadius,
			MeshRotation
		);
	}

	private void UpdateRollStraighten(FQuat& MeshRotation, FVector Velocity, float DeltaTime)
	{
		MagnetDrone::UpdateRollStraighten(
			DeltaTime,
			Velocity,
			MagnetDroneSettings.StartStraighteningSpeed,
			MagnetDroneSettings.RollStraightenDuration,
			false,
			MagnetDroneSettings.DashRollStraightenDuration,
			FVector::UpVector,
			MeshRotation,
			AccDroneMeshRelativeRight
		);
	}

	private void UpdateProcAnim(FVector Velocity, float CutsceneTime, float DeltaTime)
	{
		const FVector HorizontalVelocity = Velocity.VectorPlaneProject(FVector::UpVector);
		const float SpeedFactor = Math::Clamp(HorizontalVelocity.Size() / MagnetDrone::ShellSettings::SpeedMultiplier, 0.0, 1.0);

		ProcAnimComp.TickProceduralAnimation(
			DroneMesh,
			DeltaTime,
			bJump,
			CutsceneTime - StartJumpCutsceneTime,
			FVector::UpVector,
			bGrounded,
			false,
			FVector::ZeroVector,
			CutsceneTime,
			SpeedFactor,
			false,
		);

		// Force a refresh so that we can get the correct values
		DroneMesh.RefreshBoneTransforms();
	}
};
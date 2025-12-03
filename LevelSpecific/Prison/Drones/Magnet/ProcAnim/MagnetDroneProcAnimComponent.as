struct FMagnetDroneProcAnimShell
{
	FName SocketName = NAME_None;
	FHazeAcceleratedFloat AccMoveOut;

	float Sigmoid(float X) const
	{
		const float e = 2.71828;
		return 1 / (1 + Math::Pow(e, -X));
	}

	void TickJump(float MoveOutAmount, float DeltaTime)
	{
		AccMoveOut.AccelerateTo(MoveOutAmount * MagnetDrone::ShellSettings::MoveOutDist, MagnetDrone::ShellSettings::AccDuration, DeltaTime);
	}

	void Tick(UPoseableMeshComponent MeshComp, FVector WorldUp, float SpeedFactor, float DeltaTime, bool bGrounded, float TimeSinceStart, int Index)
	{
		const float SinNegativeOneToOne = Math::Sin((TimeSinceStart + Index * MagnetDrone::ShellSettings::SinOffset) * MagnetDrone::ShellSettings::SinFrequency);
		const float SinZeroToOne = Sigmoid(SinNegativeOneToOne  * MagnetDrone::ShellSettings::SinSharpness);
		const float MoveFromSine = SinZeroToOne * MagnetDrone::ShellSettings::SinIntensity;
		const float MoveOut = MagnetDrone::ShellSettings::bUseSine ? Math::Lerp(MoveFromSine, MagnetDrone::ShellSettings::MoveOutDist, SpeedFactor) : MagnetDrone::ShellSettings::MoveOutDist * SpeedFactor;

		if(bGrounded)
		{
			const FRotator Rotation = GetWorldRotation(MeshComp);

			FVector Up = Rotation.UpVector;
			Up.Z += MagnetDrone::ShellSettings::UpMultiplier;
			Up.Normalize();
			const float VerticalDot = Math::Clamp(Up.DotProduct(WorldUp), 0.0, 1.0);
			AccMoveOut.AccelerateTo(VerticalDot * MoveOut, MagnetDrone::ShellSettings::AccDuration, DeltaTime);
		}
		else
		{
			// Move all out while airborne
			AccMoveOut.AccelerateTo(MoveOut, MagnetDrone::ShellSettings::AccDuration, DeltaTime);
		}
	}

	void ApplyOnMesh(UPoseableMeshComponent MeshComp) const
	{
		const FRotator LocalRotation = MeshComp.GetBoneRotationByName(SocketName, EBoneSpaces::ComponentSpace);
		const FVector MoveToLocation = (LocalRotation.UpVector * AccMoveOut.Value);
		MeshComp.SetBoneLocationByName(SocketName, MoveToLocation, EBoneSpaces::ComponentSpace);
	}

	FRotator GetWorldRotation(UPoseableMeshComponent MeshComp) const
	{
		return MeshComp.GetBoneRotationByName(SocketName, EBoneSpaces::WorldSpace);
	}
};

struct FMagnetDroneProcAnimCap
{
	FName SocketName;
	FVector StartLocation;
	FVector StartUpVector;
	FHazeAcceleratedFloat AccMoveOut;

	void TickMoveOut(float DeltaTime)
	{
		AccMoveOut.AccelerateTo(MagnetDrone::CapSettings::MoveOutAmount, MagnetDrone::CapSettings::MoveOutDuration, DeltaTime);
	}

	void TickMoveIn(float DeltaTime)
	{
		AccMoveOut.AccelerateTo(0.0, MagnetDrone::CapSettings::MoveInDuration, DeltaTime);
	}

	void ApplyOnMesh(UPoseableMeshComponent MeshComp)
	{
		const FVector MoveToLocation = StartLocation + (StartUpVector * AccMoveOut.Value);
		MeshComp.SetBoneLocationByName(SocketName, MoveToLocation, EBoneSpaces::ComponentSpace);
	}
};

class UMagnetDroneProcAnimComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "ProcAnim")
	UCurveFloat JumpAnimCurve;

	TArray<FMagnetDroneProcAnimShell> Shells;
	TArray<FMagnetDroneProcAnimCap> Caps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneProcAnim");
#endif
	}

	void Reset(UPoseableMeshComponent DroneMesh)
	{
		DroneMesh.AllocateTransformData();

		Shells.SetNum(MagnetDrone::ShellSettings::ShellCount);
		for(int i = 0; i < MagnetDrone::ShellSettings::ShellCount; i++)
		{
			FMagnetDroneProcAnimShell Shell;
			Shell.SocketName = FName(f"DroneShell{i + 1}");
			DroneMesh.ResetBoneTransformByName(Shell.SocketName);

			Shells[i] = Shell;
		}

		Caps.SetNum(MagnetDrone::CapSettings::CapCount);
		for(int i = 0; i < MagnetDrone::CapSettings::CapCount; i++)
		{
			FMagnetDroneProcAnimCap Cap;
			Cap.SocketName = FName(i == 0 ? n"LeftCap" : n"RightCap");
			DroneMesh.ResetBoneTransformByName(Cap.SocketName);

			Cap.StartLocation = DroneMesh.GetBoneLocationByName(Cap.SocketName, EBoneSpaces::ComponentSpace);
			Cap.StartUpVector = DroneMesh.GetBoneRotationByName(Cap.SocketName, EBoneSpaces::ComponentSpace).RightVector * (i == 0 ? -1.0 : 1.0);
			Caps[i] = Cap;
		}
		
		DroneMesh.RefreshBoneTransforms();
	}

	void TickProceduralAnimation(
		UPoseableMeshComponent MeshComp,
		float DeltaTime,
		bool bIsJumping,
		float JumpDuration,
		FVector InWorldUp,
		bool bInIsGrounded,
		bool bIsAttachedToSocket,
		FVector SocketNormal,
		float TimeSinceStart,
		float SpeedFactor,
		bool bIsMagnetic
	)
	{
		for(int i = 0; i < Shells.Num(); i++)
		{
			if(bIsJumping)
			{
				// When jumping, move the shells out quickly at the start, and then spring them to an outer location
				const float MoveOutAmount = JumpAnimCurve.GetFloatValue(JumpDuration * MagnetDrone::ShellSettings::JumpAnimSpeed);
				Shells[i].TickJump(MoveOutAmount, DeltaTime);
			}
			else
			{
				FVector WorldUp = InWorldUp;
				bool bIsGrounded = bInIsGrounded;

				// If in a socket, always count as ground and use normal as world up
				if(bIsAttachedToSocket)
				{
					WorldUp = SocketNormal;
					bIsGrounded = true;
				}

				// Tick the regular procedural animation
				Shells[i].Tick(MeshComp, WorldUp, SpeedFactor, DeltaTime, bIsGrounded, TimeSinceStart, i);
			}

			// Apply the locations
			Shells[i].ApplyOnMesh(MeshComp);
		}

		for(int i = 0; i < Caps.Num(); i++)
		{
			if(bIsMagnetic)
				Caps[i].TickMoveOut(DeltaTime);
			else
				Caps[i].TickMoveIn(DeltaTime);

			Caps[i].ApplyOnMesh(MeshComp);
		}
	}
};
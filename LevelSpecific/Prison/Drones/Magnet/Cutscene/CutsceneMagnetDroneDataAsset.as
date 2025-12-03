struct FCutsceneMagnetDroneProcAnimShell
{
	UPROPERTY()
	FName SocketName = NAME_None;

	FCutsceneMagnetDroneProcAnimShell(FMagnetDroneProcAnimShell InShell)
	{
		SocketName = InShell.SocketName;
	}
};

struct FCutsceneMagnetDroneProcAnimCap
{
	UPROPERTY()
	FName SocketName;

	FCutsceneMagnetDroneProcAnimCap(FMagnetDroneProcAnimCap InCap)
	{
		SocketName = InCap.SocketName;
	}
};

struct FMagnetDroneProcAnimFrame
{
	UPROPERTY()
	float32 Time;

	UPROPERTY()
	FQuat4f MeshRotation;

	UPROPERTY()
	TArray<FVector3f> ShellLocations;

	// UPROPERTY()
	// TArray<FVector3f> CapLocations;

	FMagnetDroneProcAnimFrame()
	{
		ShellLocations.SetNum(MagnetDrone::ShellSettings::ShellCount);
		// CapLocations.SetNum(MagnetDrone::CapSettings::CapCount);
	}

	void Record(const ACutsceneMagnetDrone InCutsceneMagnetDrone, float InTime)
	{
		Time = float32(InTime);
		MeshRotation = FQuat4f(InCutsceneMagnetDrone.DroneMesh.ComponentQuat);

		for(int i = 0; i < ShellLocations.Num(); i++)
		{
			const FName ShellSocketName = InCutsceneMagnetDrone.RecordDataAsset.Shells[i].SocketName;
			const FVector ShellLocation = InCutsceneMagnetDrone.DroneMesh.GetBoneLocationByName(ShellSocketName, EBoneSpaces::ComponentSpace);
			ShellLocations[i] = FVector3f(ShellLocation);
		}

		// for(int i = 0; i < CapLocations.Num(); i++)
		// {
		// 	const FName CapSocketName = InCutsceneMagnetDrone.RecordDataAsset.Caps[i].SocketName;
		// 	const FVector CapLocation = InCutsceneMagnetDrone.DroneMesh.GetBoneLocationByName(CapSocketName, EBoneSpaces::ComponentSpace);
		// 	CapLocations[i] = FVector3f(CapLocation);
		// }
	}

	void ApplyPlayback(ACutsceneMagnetDrone InCutsceneMagnetDrone) const
	{
		InCutsceneMagnetDrone.DroneMesh.SetComponentQuat(FQuat(MeshRotation));

		for(int i = 0; i < ShellLocations.Num(); i++)
		{
			const FName ShellSocketName = InCutsceneMagnetDrone.RecordDataAsset.Shells[i].SocketName;
			const FVector3f ShellLocation = ShellLocations[i];
			InCutsceneMagnetDrone.DroneMesh.SetBoneLocationByName(ShellSocketName, FVector(ShellLocation), EBoneSpaces::ComponentSpace);
		}

		// for(int i = 0; i < CapLocations.Num(); i++)
		// {
		// 	const FName CapSocketName = InCutsceneMagnetDrone.RecordDataAsset.Caps[i].SocketName;
		// 	const FVector3f CapLocation = CapLocations[i];
		// 	InCutsceneMagnetDrone.DroneMesh.SetBoneLocationByName(CapSocketName, FVector(CapLocation), EBoneSpaces::ComponentSpace);
		// }

		InCutsceneMagnetDrone.DroneMesh.RefreshBoneTransforms();
	}
};

class UCutsceneMagnetDroneDataAsset : UDataAsset
{
	UPROPERTY(VisibleInstanceOnly)
	int32 FrameCount = 0;

	UPROPERTY(NotVisible)
	TArray<FCutsceneMagnetDroneProcAnimShell> Shells;

	UPROPERTY(NotVisible)
	TArray<FCutsceneMagnetDroneProcAnimCap> Caps;

	UPROPERTY(NotVisible)
	TArray<FMagnetDroneProcAnimFrame> RecordedFrames;

	void Reset(UMagnetDroneProcAnimComponent ProcAnimComp)
	{
		Shells.SetNum(MagnetDrone::ShellSettings::ShellCount);
		Caps.SetNum(MagnetDrone::CapSettings::CapCount);
		RecordedFrames.Reset();
		FrameCount = 0;

		for(int i = 0; i < ProcAnimComp.Shells.Num(); i++)
		{
			Shells[i] = FCutsceneMagnetDroneProcAnimShell(ProcAnimComp.Shells[i]);
		}

		for(int i = 0; i < ProcAnimComp.Caps.Num(); i++)
		{
			Caps[i] = FCutsceneMagnetDroneProcAnimCap(ProcAnimComp.Caps[i]);
		}
		
		MarkPackageDirty();
	}

	bool GetFrameAtTime(float32 TimeFromSectionStart, FMagnetDroneProcAnimFrame&out OutFrame, bool bLogPlayback) const
	{
		if(RecordedFrames.IsEmpty())
			return false;

		if(TimeFromSectionStart < RecordedFrames[0].Time)
		{
			OutFrame = RecordedFrames[0];

#if EDITOR
			if(bLogPlayback)
				Warning(n"CutsceneMagnetDroneDataAsset", "Getting first frame!");
#endif
			return true;
		}


		if(TimeFromSectionStart > RecordedFrames.Last().Time)
		{
			OutFrame = RecordedFrames.Last();
#if EDITOR
			if(bLogPlayback)
				Warning(n"CutsceneMagnetDroneDataAsset", "Getting last frame!");
#endif
			return true;
		}

		FMagnetDroneProcAnimFrame Previous;
		FMagnetDroneProcAnimFrame Next;
		if(BinarySearchFrames(TimeFromSectionStart, Previous, Next))
		{
			OutFrame = InterpolateFrames(Previous, Next, TimeFromSectionStart);

#if EDITOR
			if(bLogPlayback)
				Log(n"CutsceneMagnetDroneDataAsset", f"Interpolating frame at time {TimeFromSectionStart}");
#endif

			return true;
		}

		return false;
	}

	private bool BinarySearchFrames(float32 TimeFromSectionStart, FMagnetDroneProcAnimFrame&out Previous, FMagnetDroneProcAnimFrame&out Next) const
	{
		if(RecordedFrames.Num() < 2)
			return false;

		int Low = 0;
		int High = RecordedFrames.Num() - 1;
		int Middle = 0;

		while(Low < High)
		{
			Middle = Math::IntegerDivisionTrunc(Low + High, 2);

			if(TimeFromSectionStart < RecordedFrames[Middle].Time)
			{
				if(Middle > 0 && TimeFromSectionStart > RecordedFrames[Middle - 1].Time)
				{
					Previous = RecordedFrames[Middle - 1];
					Next = RecordedFrames[Middle];
					return true;
				}

				High = Middle;
			}
			else
			{
				if(Middle < RecordedFrames.Num() - 1 && TimeFromSectionStart < RecordedFrames[Middle + 1].Time)
				{
					Previous = RecordedFrames[Middle];
					Next = RecordedFrames[Middle + 1];
					return true;
				}

				Low = Middle + 1;
			}
		}

		return false;
	}

	FMagnetDroneProcAnimFrame InterpolateFrames(FMagnetDroneProcAnimFrame A, FMagnetDroneProcAnimFrame B, float32 InTime) const
	{
		const float Alpha = Math::GetPercentageBetweenClamped(A.Time, B.Time, InTime);

		FMagnetDroneProcAnimFrame Out;
		Out.Time = InTime;

		Out.MeshRotation = FQuat4f::Slerp(
			A.MeshRotation,
			B.MeshRotation,
			Alpha
		);

		for(int i = 0; i < A.ShellLocations.Num(); i++)
		{
			Out.ShellLocations[i] = Math::Lerp(
				A.ShellLocations[i],
				B.ShellLocations[i],
				Alpha
			);
		}

		// for(int i = 0; i < A.CapLocations.Num(); i++)
		// {
		// 	Out.CapLocations[i] = Math::Lerp(
		// 		A.CapLocations[i],
		// 		B.CapLocations[i],
		// 		Alpha
		// 	);
		// }

		return Out;
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void ClearAllFrames()
	{
		RecordedFrames.Empty();
		FrameCount = 0;
		MarkPackageDirty();
	}
#endif
};
struct FTundraWalkingStickWallImpactData
{
	FHitResult LatestHitResult;
	float TimeOfStartContacting;

	FTundraWalkingStickWallImpactData(AActor InActor)
	{
		LatestHitResult.Actor = InActor;
	}

	AActor GetActor() const property
	{
		return LatestHitResult.Actor;
	}

	bool opEquals(FTundraWalkingStickWallImpactData Other) const
	{
		return Actor == Other.Actor;
	}
}

class UTundraWalkingStickDeathCapability : UTundraWalkingStickBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraWalkingStickMovementComponent MoveComp;

	const float LegTraceLength = 1500.0;
	const float CenterTraceLength = 3500.0;
	TArray<FTundraWalkingStickWallImpactData> WallImpactsData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		MoveComp = WalkingStick.MoveComp;
		WalkingStick::WalkingStickInvulnerable.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TArray<FHitResult> WallImpacts;
		WallImpacts = MoveComp.GetAllWallImpacts();
		TArray<AActor> ImpactedActors;
		for(FHitResult WallImpact : WallImpacts)
		{
			int Index = WallImpactsData.FindIndex(FTundraWalkingStickWallImpactData(WallImpact.Actor));
			if(Index < 0)
			{
				FTundraWalkingStickWallImpactData Data;
				Data.TimeOfStartContacting = Time::GetGameTimeSeconds();
				Data.LatestHitResult = WallImpact;
				WallImpactsData.Add(Data);
			}
			else
			{
				FTundraWalkingStickWallImpactData& Data = WallImpactsData[Index];
				Data.LatestHitResult = WallImpact;
			}

			ImpactedActors.Add(WallImpact.Actor);
		}

		for(int i = WallImpactsData.Num() - 1; i >= 0; i--)
		{
			if(!ImpactedActors.Contains(WallImpactsData[i].Actor))
				WallImpactsData.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraWalkingStickDeathActivatedParams& Params) const
	{
		if(WalkingStick::WalkingStickInvulnerable.IsEnabled())
			return false;

		if(WalkingStick.bIsDead)
			return false;

		if(WalkingStick.bGameplaySpider)
		{
			ETundraWalkingStickCrashWithLegsType CrashType = GetCurrentCrashWithLegsType();
			if(CrashType != ETundraWalkingStickCrashWithLegsType::None)
			{
				Params.CrashType = CrashType;
				return true;
			}
		}

		if(!MoveComp.HasWallContact())
			return false;

		float Angle = MoveComp.WallContact.ImpactNormal.GetSafeNormal2D().GetAngleDegreesTo(-WalkingStick.ActorForwardVector);
		if(Angle > WalkingStick.DeathAngleThreshold)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraWalkingStickDeathActivatedParams Params)
	{
		WalkingStick.OnWalkingStickDeath(WalkingStick.bGameplaySpider);
		WalkingStick.bIsDead = true;

		if(WalkingStick.bGameplaySpider)
		{
			if(Params.CrashType != ETundraWalkingStickCrashWithLegsType::None)
			{
				WalkingStick.CurrentCrashWithLegsType = Params.CrashType;
				WalkingStick.ChangeState(ETundraWalkingStickState::CrashWithLegs);
			}
			else
			{
				WalkingStick.ChangeState(ETundraWalkingStickState::CrashInWall);
			}
		}
	}

	// Add this distance * center forward to the center location to get a location in-line with the front-most leg.
	// l = left leg, r = right leg, c = center point, x = c.location + c.forward * thisDistance;
	//
	//	  x r
	//	l╭─╮
	//	 │c│
	//	 │ │
	//	 ╰─╯
	//
	float GetCenterTraceForwardOffset(FTransform LeftTf, FTransform RightTf, FTransform CenterTf) const
	{
		FVector LeftOffset = LeftTf.Location - CenterTf.Location;
		FVector RightOffset = RightTf.Location - CenterTf.Location;
		float LeftDot = CenterTf.Rotation.ForwardVector.DotProduct(LeftOffset);
		float RightDot = CenterTf.Rotation.ForwardVector.DotProduct(RightOffset);
		if(LeftDot > RightDot)
			return LeftDot;

		return RightDot;
	}

	ETundraWalkingStickCrashWithLegsType GetCurrentCrashWithLegsType() const
	{
		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		Trace.UseLine();
		if(IsDebugActive())
			Trace.DebugDraw(0.0);

		TArray<FTransform> LeftTfs;
		LeftTfs.Add(WalkingStick.LeftFrontLegCrashWithLegsTraceLocation.WorldTransform);
		LeftTfs.Add(WalkingStick.LeftSecondLegCrashWithLegsTraceLocation.WorldTransform);

		TArray<FTransform> RightTfs;
		RightTfs.Add(WalkingStick.RightFrontLegCrashWithLegsTraceLocation.WorldTransform);
		RightTfs.Add(WalkingStick.RightSecondLegCrashWithLegsTraceLocation.WorldTransform);

		FTransform CenterTf = WalkingStick.CenterHitTraceLocation.WorldTransform;
		float CenterOffset = GetCenterTraceForwardOffset(LeftTfs[0], RightTfs[0], CenterTf);
		FVector TraceDirection = CenterTf.Rotation.ForwardVector.GetSafeNormal2D();
		
		FHitResult CenterHit = Trace.QueryTraceSingle(CenterTf.Location, CenterTf.Location + TraceDirection * (CenterOffset + CenterTraceLength));
#if !RELEASE
		TEMPORAL_LOG(this).HitResults("Center Crash With Legs Trace", CenterHit, Trace.Shape, Trace.ShapeWorldOffset);
#endif
		// If center hit we are probably moving straight towards a wall so we should trigger crash into wall instead of crash with legs!
		if(CenterHit.bBlockingHit)
			return ETundraWalkingStickCrashWithLegsType::None;

		FHitResult LeftHit = GetFirstBlockingHitFromLegTrace(Trace, LeftTfs, TraceDirection, "Left");
		if(LeftHit.bBlockingHit)
			return ETundraWalkingStickCrashWithLegsType::Left;

		FHitResult RightHit = GetFirstBlockingHitFromLegTrace(Trace, RightTfs, TraceDirection, "Right");
		if(RightHit.bBlockingHit)
			return ETundraWalkingStickCrashWithLegsType::Right;

		ETundraWalkingStickCrashWithLegsType Type;
		if(HasImpactedWallForFailDuration(Type))
		{
			return Type;
		}

		return ETundraWalkingStickCrashWithLegsType::None;
	}

	bool HasImpactedWallForFailDuration(ETundraWalkingStickCrashWithLegsType&out OutType) const
	{
		for(FTundraWalkingStickWallImpactData Data : WallImpactsData)
		{
			if(Time::GetGameTimeSince(Data.TimeOfStartContacting) >= WalkingStick.WallImpactDelayUntilFail)
			{
				FVector WalkingStickToImpact = Data.LatestHitResult.ImpactPoint - WalkingStick.ActorLocation;
				float Dot = WalkingStickToImpact.DotProduct(WalkingStick.ActorRightVector);
				OutType = Dot > 0.0 ? ETundraWalkingStickCrashWithLegsType::Right : ETundraWalkingStickCrashWithLegsType::Left;
				return true;
			}
		}

		return false;
	}

	FHitResult GetFirstBlockingHitFromLegTrace(FHazeTraceSettings Trace, const TArray<FTransform>& LegTfs, FVector TraceDirection, FString DebugLegNameString) const
	{
		for(int i = 0; i < LegTfs.Num(); i++)
		{
			FTransform Tf = LegTfs[i];
			FHitResult LegHit = Trace.QueryTraceSingle(Tf.Location, Tf.Location + TraceDirection * LegTraceLength);
#if !RELEASE
			FString Category = f"{DebugLegNameString} Crash With Legs Traces";
			TEMPORAL_LOG(this).HitResults(f"{Category};Trace [{i}]", LegHit, Trace.Shape, Trace.ShapeWorldOffset);
#endif
			if(!LegHit.bBlockingHit)
				continue;

			if(LegHit.bStartPenetrating)
				continue;

			float Angle = LegHit.ImpactNormal.GetSafeNormal2D().GetAngleDegreesTo(-TraceDirection);
#if !RELEASE
			TEMPORAL_LOG(this).Value(f"{Category};Angle [{i}]", Angle);
#endif
			if(Angle > WalkingStick.DeathCrashWithLegsAngleThreshold)
				continue;

			return LegHit;
		}

		return FHitResult();
	}
}

enum ETundraWalkingStickCrashWithLegsType
{
	None,
	Left,
	Right
}

struct FTundraWalkingStickDeathActivatedParams
{
	ETundraWalkingStickCrashWithLegsType CrashType;
}
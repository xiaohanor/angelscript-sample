
UCLASS(Abstract)
class UTreeGuardianTakedownEffectEventHandler : UTreeGuardianBaseEffectEventHandler
{
	// the helix vine grabber
	UPROPERTY(EditAnywhere)
	UNiagaraSystem VinesAsset;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DissolveAsset;

	TArray<FHelixTakedownBoneTargetData> HelixTakedownTargets;

	UFUNCTION(BlueprintOverride)
	void OnStartGrowingOutRangedInteractionRoots(
	FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params)
	{
		Super::OnStartGrowingOutRangedInteractionRoots(Params);

		// not the interaction type we are after
		if(Params.InteractionType != ETundraTreeGuardianRangedInteractionType::IceKingHoldDown)
			return;

		StartTakedown(Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateTakedown(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void OnStartGrowingInRangedInteractionRoots(
	FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params)
	{
		Super::OnStartGrowingInRangedInteractionRoots(Params);

		if(Params.InteractionType != ETundraTreeGuardianRangedInteractionType::IceKingHoldDown)
			return;

		StopTakedown(Params);
	}

	void StartTakedown(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params)
	{
		HelixTakedownTargets.Empty();

		auto TargetSkelly = UHazeSkeletalMeshComponentBase::Get(Params.RootsTargetPoint.GetOwner());
		auto TargetMesh = UStaticMeshComponent::Get(Params.RootsTargetPoint.GetOwner());

		if(TargetSkelly != nullptr)
		{
			AddHelixTargetData(TargetSkelly, n"RightHand");
			AddHelixTargetData(TargetSkelly, n"LeftHand");
			AddHelixTargetData(TargetSkelly, n"Head");
			// AddHelixTargetData(TargetSkelly, n"Neck");
			// AddHelixTargetData(TargetSkelly, n"InteractPod");
			// AddHelixTargetData(TargetSkelly, n"RightForeArm");
			// AddHelixTargetData(TargetSkelly, n"LeftForeArm");
		}
		else if(TargetMesh != nullptr)
		{
			AddHelixTargetData(TargetMesh);
		}
		else
		{
			devError("not valid target for takedown. Let sydney know");
		}

	}

	void AddHelixTargetData( UPrimitiveComponent TargetComp, FName BoneName = NAME_None)
	{
		FHelixTakedownBoneTargetData NewTarget;

		NewTarget.TreeGuardianActor = TreeGuardianActor;
		NewTarget.TreeGuardianComp = TreeGuardianComp;
		NewTarget.NiagaraComp = Niagara::SpawnLoopingNiagaraSystemAttached(VinesAsset, TargetComp);
		NewTarget.TargetBoneName = BoneName;
		NewTarget.TargetComp = TargetComp;

		NewTarget.Start();

		HelixTakedownTargets.Add(NewTarget);
	}

	void UpdateTakedown(const float Dt)
	{
		for(auto& IterTakedown : HelixTakedownTargets)
			IterTakedown.Update(Dt);
	}

	void StopTakedown(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params)
	{
		// stops the current the niagara vine effect
		for(auto& IterTakedown : HelixTakedownTargets)
			IterTakedown.Stop();

		// spawn a new one-shot dissolve vfx and send the data to it once 
		for(auto& IterTakedown : HelixTakedownTargets)
		{
			IterTakedown.NiagaraComp = Niagara::SpawnOneShotNiagaraSystemAttached(DissolveAsset, IterTakedown.TargetComp);
			IterTakedown.Update(1.0 / 60.0);
		}

		// prevent any future updates by clearing all targets.
		HelixTakedownTargets.Empty();
	}

}

struct FHelixTakedownBoneTargetData
{
	ATundraPlayerTreeGuardianActor TreeGuardianActor;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPrimitiveComponent TargetComp;
	UNiagaraComponent NiagaraComp;
	FName TargetBoneName;

	FHazeRuntimeSpline Spline;
	TArray<FVector> RelativePoints;
	FHazeAcceleratedFloat AccTensionAlpha;
	float TimestampStartTakedown = -1.0;

	float FurthestDistance = 0.0;

	float Turns = 2;
	float PointsPerTurn = 16;

	const float GrabDuration = 0.65;

	void Start()
	{
		TimestampStartTakedown = Time::GetGameTimeSeconds();
		Spline = FHazeRuntimeSpline();
		AccTensionAlpha.SnapTo(0.0);

		int TotalIterations = int(Turns * PointsPerTurn);

		RelativePoints.Reserve(int(PointsPerTurn));

		FTransform TargetTM = TargetComp.GetSocketTransform(TargetBoneName);

		float InvTurns = 1.0 / Turns;

		bool bCounterClockwise = false;

		float MaxRadius = 100.0;
		// float MaxRadius = Math::RandRange(100, 300);
		// float MaxRadius = TargetComp.BoundsRadius;

		float Radius = MaxRadius * 1.0;
		float Height = MaxRadius * 1.0;
		float Pitch = Height / Turns;
		float StepSize_Angular = 360.0 / float(PointsPerTurn);
		StepSize_Angular *= bCounterClockwise ? -1 : 1;
		// float StepSize_Pitch = (Pitch / (PointsPerTurn)) * InvTurns;
		float StepSize_Pitch = (Pitch / (PointsPerTurn));

		// StepSize_Pitch = 0.0;

		// if(PointsPerTurn * Turns == 1)
		// {
		// 	StepSize_Pitch = 0.0;
		// }

		// Debug::DrawDebugCoordinateSystem(
		// 	TargetTM.GetLocation(),
		// 	TargetTM.GetRotation().Rotator(),
		// 	1000.0,
		// 	5.0,
		// 	10.0
		// );

		float InvTotalIterations = 1.0 / float(TotalIterations);	

		FVector HelixDirection = TargetTM.GetRotation().GetUpVector();
		// FQuat HelixQuat = FQuat(HelixDirection, PI * 2.0);
		// HelixQuat.Normalize();
		FQuat HelixQuat = FQuat::MakeFromZ(HelixDirection);
		FVector CenterOffset = HelixQuat.UpVector*Height*(InvTotalIterations + 0.5);
		FVector Center = TargetTM.GetLocation() - CenterOffset;
		// FVector Center = TargetTM.GetLocation();

		// for(int i = TotalIterations; i > 0; --i)
		for (auto i = 0; i < TotalIterations; ++i)
		{
			// FVector QueryPoint = Center;
			// QueryPoint += (Math::GetRandomPointOnCircle_YZ() * Radius);

			// const float RandomOffset = Math::RandRange(0.8, 1.2);
			float ProgressAlpha = float(i) / float(TotalIterations);
			// ProgressAlpha = 1.0 - ProgressAlpha;
			float RandomOffsetScale = 1.0 + (ProgressAlpha * Math::RandRange(0.5, 1.5));

			float StartIndexOffset = PointsPerTurn / 0.7;  // points per turn / 4 ish
			float StepIndex = (StartIndexOffset+i);
			const float RadStepSize = Math::DegreesToRadians(StepIndex*StepSize_Angular);
			const FVector Offset = FVector(
				Math::Sin(RadStepSize) * Radius * RandomOffsetScale,
				Math::Cos(RadStepSize) * Radius * RandomOffsetScale,
				StepIndex*StepSize_Pitch 
			);

			const FVector Offset_Rotated = HelixQuat.RotateVector(Offset);
			FVector QueryPoint = Center + Offset_Rotated;

			// Debug::DrawDebugPoint(QueryPoint, 10, FLinearColor::Red, 5);

			FVector OutP = FVector::ZeroVector;
			// Mesh.GetClosestPointOnCollision(QueryPoint, OutP);
			OutP = QueryPoint;

			FVector RelativeP = TargetTM.InverseTransformPositionNoScale(OutP);
			RelativePoints.Add(RelativeP);
		}
	}

	void Stop()
	{
		NiagaraComp.DeactivateImmediate();
		if(NiagaraComp != nullptr)
		{
			NiagaraComp.DestroyComponent(NiagaraComp);
			NiagaraComp = nullptr;
		}
	}

	void Update(const float Dt)
	{
		UpdateRuntimeSpline(Dt);
		SendDataToNiagara();
	}

	void UpdateRuntimeSpline(const float Dt) 
	{
		float TimeSinceTakedownStarted = Time::GetGameTimeSince(TimestampStartTakedown);
		float AlphaSinceStarted = Math::Saturate(TimeSinceTakedownStarted / GrabDuration);
		float TensionAlpha = Math::Pow(AlphaSinceStarted, 2.5);

		FTransform TargetTM = TargetComp.GetSocketTransform(TargetBoneName);

		TArray<FVector> WorldSpacePoints;
		WorldSpacePoints.Reserve(RelativePoints.Num());
		for(auto IterP : RelativePoints)
		{
			FVector P = TargetTM.TransformPositionNoScale(IterP);

			FVector OutP;
			TargetComp.GetClosestPointOnCollision(P, OutP, TargetBoneName);
			P = Math::Lerp(P, OutP, TensionAlpha);

			FVector Normal = P-TargetTM.GetLocation();
			Normal.Normalize();
			P += (Normal * Math::Lerp(100.0, 30.0, TensionAlpha));
			// P += (Normal * 40.0);

			WorldSpacePoints.Add(P);
		}

		Spline = FHazeRuntimeSpline();

		auto NeckTM = TreeGuardianActor.Mesh.GetSocketTransform(n"Neck1");
		auto RightHand = TreeGuardianActor.Mesh.GetSocketLocation(n"RightHand");
		auto LeftHand = TreeGuardianActor.Mesh.GetSocketLocation(n"LeftHand");

		if(TimeSinceTakedownStarted % 2.0 < 1.0)
		{
			FurthestDistance = 0.0;
		}

		float Tension = 0.0;
		const float CurrentDist = TargetTM.GetLocation().Distance(LeftHand);
		if(CurrentDist > FurthestDistance)
		{
			FurthestDistance = CurrentDist;
			Tension = 1.0;
		}
		else
		{
			const float Delta = FurthestDistance-CurrentDist;
			Tension = 1.0 - Math::Saturate(Delta / 500.0);
		}

		AccTensionAlpha.AccelerateTo(Tension, 0.4, Dt);

		Tension = AccTensionAlpha.Value;

		// PrintToScreen("Tension: " + Tension);

		Spline.Tension = Tension;
		Spline.CustomCurvature = Math::Lerp(0.65, 0.35, Tension);

		Spline.Points = WorldSpacePoints;

		// fix ribbon clipping the body by adding a virutal shoulder pos
		auto ButtonMashAlpha = TreeGuardianComp.HoldDownIceKingAnimData.ButtonMashProgress;
		ButtonMashAlpha = Math::Pow(ButtonMashAlpha, 0.1);
		float InterpAlpha = (ButtonMashAlpha + Tension) * 0.5;
		const FVector ShoulderPos = NeckTM.TransformPosition(FVector(-50.0, -10.0, -5.0));
		const FVector InterpolatedShoulderPos = Math::Lerp(RightHand, ShoulderPos, InterpAlpha);

		PrintToScreen("InterpAlpha: "+ InterpAlpha);
		if(InterpAlpha >= 0.0)
		{
			Spline.AddPoint(InterpolatedShoulderPos);
			// Debug::DrawDebugPoint(InterpolatedShoulderPos, 15, FLinearColor::Purple);
		}
		// else
		// {
		// 	Debug::DrawDebugPoint(InterpolatedShoulderPos, 40, FLinearColor::Red);
		// }

		Spline.AddPoint(RightHand);
		Spline.AddPoint(LeftHand);

		// Spline.DrawDebugSplineWithLines();
	}
	
	void SendDataToNiagara()
	{
		TArray<FVector> NiagaraPoints;
		// Spline.GetLocations_NonUniform(NiagaraPoints, 100);
		Spline.GetLocations(NiagaraPoints, 100);

		auto RightHand = TreeGuardianActor.Mesh.GetSocketLocation(n"RightHand");
		NiagaraComp.SetNiagaraVariableVec3("HandPosition", RightHand);
		FTransform TargetTM = TargetComp.GetSocketTransform(TargetBoneName);
		NiagaraComp.SetNiagaraVariableVec3("ObjectPosition", TargetTM.GetLocation());

		NiagaraComp.SetNiagaraVariableFloat("FullDuration", GrabDuration);
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(NiagaraComp, n"RuntimeSplineLocations", NiagaraPoints);

		// for(auto IterPoint : NiagaraPoints)
		// 	Debug::DrawDebugPoint(IterPoint, 10, FLinearColor::Yellow, 0.0);

		// Debug::DrawDebugSphere(TargetTM.GetLocation(), TargetComp.BoundsRadius, 16, FLinearColor::Red, 10, 0.0);
	}

}
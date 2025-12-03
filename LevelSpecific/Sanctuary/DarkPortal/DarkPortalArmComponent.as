
class UDarkPortalArmComponent : UNiagaraComponent
{
	private float UniformValue;
	private float RandomValue;
	private float SpawnTime;
	private float ActionTime = -1;
	private EDarkPortalArmState PreviousState;
	private EDarkPortalArmState CurrentState;
	private FDarkPortalGrabData GrabData;
	private FDarkPortalCurve CurrentCurve;
	private FDarkPortalCurve PreviousCurve;

	default TranslucencySortPriority = 10;

	private bool bIsExtended = false;

	const FDarkPortalCurve& GetCurrentPortalCurve() const property
	{
		return CurrentCurve;
	}

	void Initialize(int Index)
	{
		SpawnTime = Time::GameTimeSeconds;
		UniformValue = (Index / float(Math::Max(DarkPortal::Grab::MaxGrabs - 1, 1)));

		SetNiagaraVariableFloat("NormalizedArmIndex", UniformValue);

		RandomValue = Math::RandRange(0.0, 1.0);

		CurrentState = PreviousState = EDarkPortalArmState::Spawn;
		CurrentCurve = PreviousCurve = FDarkPortalCurve(
			WorldLocation,
			WorldLocation,
			WorldLocation,
			WorldLocation
		);

		// whether arms should come up automatically when we throw out the portal or not. 
		bIsExtended = DarkPortal::Timings::StartExtended;

		ApplyCurve(PreviousCurve);

	}

	void Extend()
	{
		if (bIsExtended)
			return;

		bIsExtended = true;

		/**
		 * Ugly bug fix. This makes sure that the arms come out immediately 
		 * when we spawn a portal and have a target, and portal has been out
		 * already. 
		 * 
		 * The reason why we are doing this is because niagara spawns the arms
		 * based on time loop. We want to reset that loop the first time 
		 * we try to grab anything. 
		 */
		if(ActionTime == -1 && DarkPortal::Timings::StartExtended == false)
		{
			DeactivateImmediate();
			Activate(true);
		}

		if (CurrentState != EDarkPortalArmState::Grab)
		{
			ActionTime = Time::GameTimeSeconds;
			PreviousCurve = CurrentCurve;
		}
	}

	void Contract()
	{
		if (!bIsExtended)
			return;

		bIsExtended = false;

		if (CurrentState != EDarkPortalArmState::Grab)
		{
			ActionTime = Time::GameTimeSeconds;
			PreviousCurve = CurrentCurve;
		}
	}

	void Update(int ArmIndex, float DeltaTime)
	{
		UpdateNiagaraState();
		UpdateTransform(DeltaTime);
		UpdateCurrentState();

		TEMPORAL_LOG(Owner, f"Arm{ArmIndex}")
			.Value("bIsExtended", bIsExtended)
			.Value("CurrentState", CurrentState)
			.Value("TargetComponent", GrabData.TargetComponent)
			.Value("ResponseComponent", GrabData.ResponseComponent)
		;
	}

	/* 
		We want to deactivate the arms when they aren't visible.
		This ALSO ensures that the niagara arms come out immediately when we press the button,
		because the logic in niagara is dependent on a loop, which is reset upon deactivation/activation.
	*/
	void UpdateNiagaraState()
	{
		// PrintToScreen("State: " + CurrentState);
		if (CurrentState != EDarkPortalArmState::Grab)
		{
			if(!bIsExtended)
			{
				// @TODO: Perhaps distance check is safer
				const float TimeSinceStartedRetracting = Time::GetGameTimeSince(ActionTime);
				if(TimeSinceStartedRetracting > 2.0)
				{
					// PrintToScreen("Deactivaet Immediate. Time Since started Retracting: " + TimeSinceStartedRetracting);
					DeactivateImmediate();
				}
			}
			else 
			{
				// PrintToScreen("Activate. Not grabbing but Extending", 0);
				Activate();
			}
		}
		else
		{
			// PrintToScreen("Activate. Grabbing Stuff!", 0);
			Activate();
		}
	}

	void UpdateTransform(float DeltaTime)
	{
		switch (CurrentState)
		{
			case EDarkPortalArmState::Spawn:
			{
				float DelayRoll = DarkPortal::Timings::SpawnMaxRoll * WeightedRandom;
				float Duration = DarkPortal::Timings::SpawnDuration;
				
				float Alpha = Math::Saturate(Time::GetGameTimeSince(SpawnTime + DelayRoll) / (Duration + DelayRoll));
				Alpha = Math::ExpoOut(0.0, 1.0, Alpha);
				
				auto SpawnCurve = CalculateIdleCurve();
				auto LerpedCurve = PreviousCurve.Lerp(SpawnCurve, Alpha);
				LerpedCurve.StateIndex = 0;
				ApplyCurve(LerpedCurve);

				break;
			}
			case EDarkPortalArmState::Idle:
			{
				float DelayRoll = DarkPortal::Timings::GrabMaxRoll * WeightedRandom;
				float Duration = DarkPortal::Timings::GrabDuration;

				float Alpha = Math::Saturate(Time::GetGameTimeSince(ActionTime + DelayRoll) / (Duration + DelayRoll));
				// Alpha = Math::ExpoOut(0.0, 1.0, Alpha);
				Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 3.0);

				auto IdleCurve = CalculateIdleCurve();
				auto LerpedCurve = PreviousCurve.Lerp(IdleCurve, Alpha);
				LerpedCurve.StateIndex = 1;
				ApplyCurve(LerpedCurve);

				break;
			}
			case EDarkPortalArmState::Grab:
			{

				float DelayRoll = DarkPortal::Timings::GrabMaxRoll * WeightedRandom;
				float Duration = DarkPortal::Timings::GrabDuration;

				float TimeSinceAction = Time::GetGameTimeSince(ActionTime + DelayRoll);
				float DesiredActionTime = (Duration - DelayRoll); 
				float Alpha = Math::Saturate(TimeSinceAction / DesiredActionTime);
				Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);

				// change tangent directions after the tentacles have reached their target
				const float OverTime = Math::Max(0, TimeSinceAction-DesiredActionTime);
				float OverTimeAlpha = Math::Saturate(OverTime / 2);
				OverTimeAlpha = Math::Pow(OverTimeAlpha, 1);

				auto GrabCurve = CalculateGrabCurve(Alpha, OverTimeAlpha);
				auto LerpedCurve = PreviousCurve.Lerp(GrabCurve, Alpha);
				LerpedCurve.StateIndex = 2;

				ApplyCurve(LerpedCurve);

				// if(Alpha < 1)
				// {
				// 	Debug::DrawDebugPoint(LerpedCurve.End, 3, Duration = 1);
				// }

				// FHazeRuntimeSpline TestSpline;
				// TestSpline.AddPoint(LerpedCurve.Start);
				// const FVector Halfway = (LerpedCurve.End - LerpedCurve.Start) * 0.5;
				// const FVector HalfWayPoint = LerpedCurve.Start + FVector(0,0, Halfway.Z);
				// TestSpline.AddPoint(HalfWayPoint);
				// TestSpline.AddPoint(LerpedCurve.End);
				// LerpedCurve.StartTangent = TestSpline.GetLocation(0.2);
				// LerpedCurve.EndTangent = TestSpline.GetLocation(0.7);
				// LerpedCurve.End = TestSpline.GetLocation(Alpha);
				// DrawDebugSpline(TestSpline);

				break;
			}
		}
		// CurrentCurve.DrawDebug();
	}

	void SetTarget(const FDarkPortalGrabData& TargetData)
	{
		if (GrabData.TargetComponent == TargetData.TargetComponent)
			return;


		GrabData = TargetData;
		ActionTime = Time::GameTimeSeconds;
		PreviousCurve = CurrentCurve;

		// Send over relative target locations once and then 
		// have niagara do the world transform calculation when needed
		NiagaraDataInterfaceArray::SetNiagaraArrayVector(
			this,
			n"RelativeTargetLocations",
			GrabData.RelativeTargetLocations
		);
		
		// this perhaps not needed here
		SetNiagaraVariableBool("bExtended", true);

		UpdateCurrentState();
	}

	void UpdateCurrentState()
	{
		PreviousState = CurrentState;
		CurrentState = GetTargetState();
		if (PreviousState != CurrentState)
		{
			PreviousCurve = CurrentCurve;
		}
	}

	const UDarkPortalTargetComponent GetTargetComp() const
	{
		return GrabData.TargetComponent;
	}

	float MegaCompanionScale = 1.0;

	void ApplyCurve(const FDarkPortalCurve& Curve)
	{
		CurrentCurve = Curve;

		SetNiagaraVariableVec3("User.P0", Curve.Start);
		SetNiagaraVariableVec3("User.P1", Curve.StartTangent);
		SetNiagaraVariableVec3("User.P2", Curve.EndTangent);
		SetNiagaraVariableVec3("User.P3", Curve.End);
		SetNiagaraVariableInt("StateIndex", Curve.StateIndex);
		SetNiagaraVariableVec3("PortalOrigin", Owner.GetActorLocation());

		// PrintToScreen("Extended", 0.0, bIsExtended ? FLinearColor::Green : FLinearColor::Red);
		SetNiagaraVariableBool("bExtended", bIsExtended);

		// can be moved to init
		SetNiagaraVariableInt("NumArms", DarkPortal::Grab::MaxGrabs);

		SetNiagaraVariableBool("bHasValidTarget", false);
		SetNiagaraVariableFloat("ReachedTargetSpawnProbability", 0.0);
		if(GetTargetComp() != nullptr)
		{
			SetNiagaraVariableBool("bHasValidTarget", true);
			const float DistSQ = GrabData.WorldLocation.DistSquared(Curve.End);
			if(DistSQ < 50.0)
			{
				SetNiagaraVariableFloat("ReachedTargetSpawnProbability", 1.0);
			}
		}

		// SetNiagaraVariableBool("bExtended", false);

		/**
		 * We'll do a random spawn offset every time a new tentacle comes out in
		 * niagara as well. So we are applying two random offsets; one down here in 
		 * code when we spawn the component and then another offset every time 
		 * we spawn a new tentacle in niagara...
		 * 
		 * Ideally we would apply both offset down here in code instead, but 
		 * it's a big rewrite to get that working on both on the code side 
		 * and in niagara. 
		 * 
		 * This setup allows us to iterate faster. 
		 * 
		 * .Sydney
		 * 
		 */
		SetNiagaraVariableFloat("SpawnRadius", DarkPortal::Arms::OffsetRadius * MegaCompanionScale);

		// send over the target data transform allowing us to 
		// transform relative target locations in niagara when needed.
		if(GrabData.TargetComponent != nullptr)
		{
			LastKnownTargetComp = GrabData.TargetComponent;
		}
		FMatrix TargetTransformMatrix = FMatrix();
		FMatrix InverseTargetTransformMatrix = FMatrix();
		if(LastKnownTargetComp != nullptr)
		{
			TargetTransformMatrix = LastKnownTargetComp.GetWorldTransform().ToMatrixWithScale();
			InverseTargetTransformMatrix = LastKnownTargetComp.GetWorldTransform().ToInverseMatrixWithScale();
			SetNiagaraVariableMatrix("TargetTransformMatrix", TargetTransformMatrix);
			SetNiagaraVariableMatrix("InverseTargetTransformMatrix", InverseTargetTransformMatrix);
		}

		/////////////////////////
		// DEBUG

		//Debug::DrawDebugPoint(Curve.End, 10*Math::RandRange(0.9, 1.0), FLinearColor::Red, 0.0);
		// Debug::DrawDebugPoint(Curve.Start, 10*Math::RandRange(0.9, 1.0), FLinearColor::Green, 0.0);
		// Debug::DrawDebugPoint(Curve.EndTangent, 10*Math::RandRange(0.9, 1.0), FLinearColor::Red, 0.0);
		// Debug::DrawDebugPoint(Curve.StartTangent, 10*Math::RandRange(0.9, 1.0), FLinearColor::Green, 0.0);
		// Debug::DrawDebugLine(Curve.Start, Curve.StartTangent, FLinearColor::Green, 3, 0.1);
		// Debug::DrawDebugLine(Curve.End, Curve.EndTangent, FLinearColor::Red, 3, 0.1);
		// Debug::DrawDebugLine(Curve.StartTangent, Curve.EndTangent, FLinearColor::Yellow, 3, 0.1);
		// Debug::DrawDebugCoordinateSystem( GetWorldLocation(), GetWorldRotation(), 100,);

		// FVector PrevLoc = Curve.Start;
		// float Interval = 0.1;
		// for (float Alpha = Interval; Alpha < (1.0 + Interval); Alpha += Interval)
		// {
		// 	FVector Loc = BezierCurve::GetLocation_2CP_ConstantSpeed(
		// 		Curve.Start,
		// 		Curve.StartTangent,
		// 		Curve.EndTangent,
		// 		Curve.End,
		// 		Alpha
		// 	);
		// 	Debug::DrawDebugLine(PrevLoc, Loc, FLinearColor::Red, 3, 0);
		// 	PrevLoc = Loc;
		// }

		// for(auto Iter : GrabData.RelativeTargetLocations)
		// {
		// 	FVector DebugLoc = LastKnownTargetComp.GetWorldTransform().TransformPosition(Iter);
		// 	Debug::DrawDebugPoint(LastKnownTargetComp.GetWorldLocation(), 50, FLinearColor::Red, 0.0);
		// 	Debug::DrawDebugPoint(DebugLoc, 40, FLinearColor::Blue, 0.0);
		// }

	}

	// work around until we figure out how do send over objects to niagara
	USceneComponent LastKnownTargetComp = nullptr;

	EDarkPortalArmState GetTargetState() const
	{
		if (Time::GetGameTimeSince(SpawnTime) < DarkPortal::Timings::SpawnDuration)
			return EDarkPortalArmState::Spawn;

		if (GrabData.IsValid())
			return EDarkPortalArmState::Grab;

		return EDarkPortalArmState::Idle;
	}

	FDarkPortalCurve CalculateIdleCurve() const
	{
		const FVector PortalToBase = (WorldLocation - Owner.ActorLocation);
		const float TiltAlpha = Math::Saturate((PortalToBase.Size() / DarkPortal::Arms::OffsetRadius));
		
		FVector Tilt = PortalToBase.GetSafeNormal() * TiltAlpha;
		FVector Offset = GetLocationOffset(Time::GameTimeSeconds * (1.1 - (WeightedRandom * 0.25)));
		
		if (!bIsExtended)
		{
			Tilt *= 0.3;
			Offset *= 0.3;
		}

		const FVector StartLocation = WorldLocation;
		const FVector EndLocation = StartLocation + 
			ForwardVector * ArmLength +
			Tilt * DarkPortal::Arms::MaxTilt +
			Offset * 12.0;

		const FVector StartTangent = StartLocation +
			ForwardVector * 150.0 +
			Offset * -50.0 +
			Offset * WeightedRandom * -25.0;

		const FVector EndToBase = (EndLocation - WorldLocation);
		const FVector EndTangent = EndLocation -
			EndToBase.GetSafeNormal() * 100.0 +
			Tilt * -DarkPortal::Arms::MaxTilt * .5 +
			Offset * 50.0 +
			Offset * WeightedRandom * 25.0;

		// Hide the tentacles when they are not extended.
		if (!bIsExtended)
		{
			return FDarkPortalCurve(
				WorldLocation,
				WorldLocation,
				WorldLocation,
				WorldLocation
			);
		}

		return FDarkPortalCurve(
			StartLocation,
			StartTangent,
			EndTangent,
			EndLocation
		);
	}

	FDarkPortalCurve CalculateGrabCurve(const float ReachTargetAlpha = 1, const float OverTimeLerpAlpha = 1) const
	{
		const FVector FromPortal = (WorldLocation - Owner.ActorLocation);
		const FVector FromGrab = (WorldLocation - GrabData.WorldLocation);
		//Debug::DrawDebugSphere(GrabData.WorldLocation, 300, 12, FLinearColor::Green);
		float DistanceAlpha = Math::Saturate(FromGrab.Size() / 750.0);
		DistanceAlpha = Math::EaseInOut(0.0, 1.0, DistanceAlpha, 2.0);

		const float TangentScaler = FromGrab.Size() * 0.2;

		FVector GrabWorldNormal = GrabData.WorldNormal;

		// move the normals a bit with smooth noise
		const float DialatedTime = Time::GetGameTimeSeconds() * 5.0;
		FVector SmoothRandomDirection = FVector(
			Math::PerlinNoise1D(DialatedTime * 0.001),
			Math::PerlinNoise1D(DialatedTime * 0.01),
			Math::PerlinNoise1D(DialatedTime * 0.1)
		);
		SmoothRandomDirection *= 0.25;
		SmoothRandomDirection *= 1.0;
		GrabWorldNormal += SmoothRandomDirection;

		// Have the normals face the tentacle a bit
		GrabWorldNormal -= (FromGrab.GetSafeNormal() * 0.25);

		GrabWorldNormal.Normalize();

		FVector RelaxedStartTangent = WorldLocation +
			ForwardVector * 250.0 + 
			FromPortal.GetSafeNormal() * 100.0  * (1.0 - DistanceAlpha);

		const FVector FlexedStartTangent = WorldLocation +
			(ForwardVector + FromPortal.GetSafeNormal()).GetSafeNormal() * TangentScaler;

		FVector StartTangent = Math::Lerp(RelaxedStartTangent, FlexedStartTangent, OverTimeLerpAlpha);

		const FVector EndTangent = GrabData.WorldLocation - 
			(GrabWorldNormal * TangentScaler * 1.5);

		const FVector StartLocation = WorldLocation;
		FVector EndLocation = GrabData.WorldLocation;

		// EndLocation = Math::Lerp(EndTangent, GrabData.WorldLocation, ReachTargetAlpha);
		EndLocation = GrabData.WorldLocation;

		// Debug::DrawDebugPoint(EndLocation, 20.0, FLinearColor::Red);
		// Debug::DrawDebugArrow(
		// 	GrabData.WorldLocation,
		// 	GrabData.WorldLocation + GrabData.WorldNormal * 1000,
		// 	100,
		// 	FLinearColor::Red,
		// 	10,
		// 	0
		// );

		// Debug::DrawDebugArrow(
		// 	EndLocation,
		// 	EndTangent,
		// 	100,
		// 	FLinearColor::Red,
		// 	10,
		// 	0
		// );
		
		// Debug::DrawDebugArrow(
		// 	StartLocation,
		// 	StartTangent,
		// 	100,
		// 	FLinearColor::Yellow,
		// 	10,
		// 	0
		// );

		return FDarkPortalCurve(
			StartLocation,
			StartTangent,
			EndTangent,
			EndLocation
		);	
	}

	FVector GetLocationOffset(float Time = Time::GameTimeSeconds,
		float Frequency = 3.0) const
	{
		FVector Offset(
			Math::Sin((Time + (WeightedRandom)) * Frequency),
			Math::Sin((Time + (WeightedRandom * PI)) * Frequency),
			Math::Cos((Time + (WeightedRandom * PI * PI)) * Frequency),
		);

		return WorldTransform.TransformVector(Offset);
	}

	float GetWeightedRandom() const property
	{
		return ((UniformValue * DarkPortal::Arms::UniformWeight) + (RandomValue * (1.0 - DarkPortal::Arms::UniformWeight))) % 1.0;
	}

	float GetArmLength() const property
	{
		FHazeRange Range = (bIsExtended ? DarkPortal::Arms::ExtendedLength : DarkPortal::Arms::ContractedLength);
		return Range.Min + (Range.Max - Range.Min) * WeightedRandom;
	}

	void DrawDebugSpline(FHazeRuntimeSpline& InSpline)
	{
		float NumLines = 100;
		float DebugAlpha = 0;
		float StepSize = 1/NumLines;
		while(DebugAlpha < 1)
		{
			FVector P0 = InSpline.GetLocation(DebugAlpha);
			DebugAlpha += StepSize;
			FVector P1 = InSpline.GetLocation(DebugAlpha);
			Debug::DrawDebugLine(P0, P1, FLinearColor::Yellow, 5, 0);
		}

	}

	void BakeOscillationsIntoSpline(FHazeRuntimeSpline& Spline, float AntiOscillationAlpha = 0)
	{
		const float RampedChargeFraction = 1;

		float OscillationMagnitude = Math::Lerp(80.0, 200.0, RampedChargeFraction) * 1;
		float OscillationAlpha = 1 - AntiOscillationAlpha;
		OscillationMagnitude *= OscillationAlpha;

		const int NumSamplePoints = Math::FloorToInt(Math::Lerp(4, 20, RampedChargeFraction));

		// we offset the noise in order to increase the chance of
		// creating a unique noise pattern for every icicle launch
		// const FVector NoiseSampleLocationOffset = FVector(Time::GetGameTimeSeconds() * 10000.0 % 10000.0);

		TArray<FVector> Locations;
		Spline.GetLocations(Locations, NumSamplePoints);

		TArray<FVector> Directions;
		Spline.GetDirections(Directions, NumSamplePoints);

		for(int i = 1; i < NumSamplePoints; ++i)
		{
			FVector& L = Locations[i];
			FVector& D = Directions[i];

			const float Float_Iter = float(i);
			const float Float_NumSamples = float(NumSamplePoints);
			const float Alpha = Float_Iter / Float_NumSamples;
			// PrintToScreen("A: " + Alpha);

			const FVector Right = Math::Abs(D.Y) < (1.0 - KINDA_SMALL_NUMBER) ? FVector::RightVector : FVector::ForwardVector;
			// const FVector Right = FVector(Math::PerlinNoise3D(L)).ConstrainToPlane(D).GetSafeNormal();

			const FVector UpAxis = D.CrossProduct(Right).GetSafeNormal();
			// const FVector UpAxis = D.CrossProduct(D.CrossProduct(RightVector)).GetSafeNormal();

			// L += (UpAxis * Math::PerlinNoise3D(L + NoiseSampleLocationOffset) * OscillationMagnitude);
			// L += (UpAxis * Math::PerlinNoise3D(L) * OscillationMagnitude);
			L += (UpAxis * Math::Sin(20*Alpha) * OscillationMagnitude);

			// Debug::DrawDebugLine( L, L+UpAxis*1000.0,FLinearColor::LucBlue, 3.0, 1.0);
		}

		Spline.Points = Locations;
	}

}

struct FDarkPortalCurve
{
	FVector Start = FVector::ZeroVector;
	FVector StartTangent = FVector::ZeroVector;
	FVector EndTangent = FVector::ZeroVector;
	FVector End = FVector::ZeroVector;

	// communicate to niagara which state we are in
	int StateIndex = -1;

	FDarkPortalCurve(const FVector& InStart,
		const FVector& InStartTangent,
		const FVector& InEndTangent,
		const FVector& InEnd)
	{
		Start = InStart;
		StartTangent = InStartTangent;
		EndTangent = InEndTangent;
		End = InEnd;
	}
	
	FDarkPortalCurve Lerp(const FDarkPortalCurve& Other, float Alpha)
	{
		auto Curve = FDarkPortalCurve(
			Math::Lerp(Start, Other.Start, 1.0), 

			// Math::Lerp(StartTangent, Other.StartTangent, Alpha), 
			// Math::Lerp(EndTangent, Other.EndTangent, Alpha), 
			// @TODO: lerp the start tangent with a bezier instead in order to a non-linear transition //Sydney
			Other.StartTangent,
			Other.EndTangent,

			Math::Lerp(End, Other.End, Alpha), 
		);

		return Curve;
	}

	FHazeRuntimeSpline ToSpline() const
	{	
		auto Spline = FHazeRuntimeSpline();		

		Spline.SetCustomEnterTangentPoint(StartTangent);
		Spline.SetCustomExitTangentPoint(EndTangent);
		Spline.AddPoint(Start);
		Spline.AddPoint(End);

		return Spline;
	}

	void DrawDebug()
	{
		Debug::DrawDebugLine(Start, StartTangent, FLinearColor::DPink);
		Debug::DrawDebugLine(StartTangent, EndTangent, FLinearColor::DPink);
		Debug::DrawDebugLine(EndTangent, End, FLinearColor::DPink);

		Debug::DrawDebugPoint(Start, 5.0, FLinearColor::White);
		Debug::DrawDebugPoint(StartTangent, 5.0, FLinearColor::White);
		Debug::DrawDebugPoint(EndTangent, 5.0, FLinearColor::White);
		Debug::DrawDebugPoint(End, 5.0, FLinearColor::White);
	}
}

enum EDarkPortalArmState
{
	Spawn,
	Idle,
	Grab
}
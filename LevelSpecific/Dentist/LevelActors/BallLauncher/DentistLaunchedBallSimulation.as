enum EDentistLaunchedBallLoopState
{
	WaitingAtStart,
	Moving,
	WaitingAtEnd,
};

struct FDentistLaunchedBallImpact
{
	UPROPERTY()
	TSoftObjectPtr<USceneComponent> HitComponent;

	UPROPERTY()
	FVector RelativeImpactPoint;

	UPROPERTY()
	FVector RelativeImpactNormal;

	UPROPERTY()
	float Time;

	UPROPERTY()
	float Impulse;

	FDentistLaunchedBallImpact(FHitResult HitResult, float InTime, float InImpulse)
	{
		HitComponent = HitResult.Component;
		RelativeImpactPoint = HitComponent.Get().WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
		RelativeImpactNormal = HitComponent.Get().WorldTransform.InverseTransformVector(HitResult.ImpactNormal);
		Time = InTime;
		Impulse = InImpulse;
	}

	AActor GetActor() const
	{
		if(!HitComponent.IsValid())
			return nullptr;

		return HitComponent.Get().Owner;
	}

	FVector GetImpactPoint() const
	{
		if(HitComponent.IsPending())
			return RelativeImpactPoint;

		return HitComponent.Get().WorldTransform.TransformPosition(RelativeImpactPoint);
	}

	FVector GetImpactNormal() const
	{
		if(HitComponent.IsPending())
			return RelativeImpactNormal;

		return HitComponent.Get().WorldTransform.TransformVector(RelativeImpactNormal).GetSafeNormal();
	}

	UDentistLaunchedBallImpactResponseComponent GetImpactResponseComponent() const
	{
		if(HitComponent.IsPending())
			return nullptr;

		return UDentistLaunchedBallImpactResponseComponent::Get(HitComponent.Get().Owner);
	}
};

struct FDentistLaunchedBallSimulation
{
	/**
	 * The results from the simulation.
	 */
	UPROPERTY(VisibleInstanceOnly)
	private TArray<FDentistBallLauncherSimulationStep> Steps;

	UPROPERTY(VisibleInstanceOnly)
	TArray<FDentistLaunchedBallImpact> Impacts;

	/**
	 * How long we actually move for.
	 * Not editable, since that would mean editing the simulation directly.
	 */
	UPROPERTY(VisibleInstanceOnly)
	private float MoveEndTime = 0;

	UPROPERTY(VisibleInstanceOnly)
	int HitWaterIndex = -1;

	void AddStep(FDentistBallLauncherSimulationStep Step)
	{
		Steps.Add(Step);
		MoveEndTime = Step.Time;
	}

	void SerializeStepsRelativeTo(const ADentistSimulationLoop SimulationLoop)
	{
		for(auto& Step : Steps)
		{
			Step.SerializeRelativeTo(SimulationLoop);
		}
	}

	int GetStepCount() const
	{
		return Steps.Num();
	}

	const FDentistBallLauncherSimulationStep& GetStepAtIndex(int Index) const
	{
		return Steps[Index];
	}

	FDentistBallLauncherSimulationStep& GetStepAtIndex(int Index)
	{
		return Steps[Index];
	}

	int GetStepIndexAtTime(float Time) const
	{
		if(Steps.Num() == 0)
			return 0;

		if(Steps.Num() == 1)
			return 0;

		if(Time <= Steps[0].Time)
			return 0;

		if(Time >= Steps.Last().Time)
			return GetStepCount() - 1;

		int PreviousIndex;
		int NextIndex;
		if(!BinarySearchClosestPair(Time, PreviousIndex, NextIndex))
			return -1;

		return PreviousIndex;
	}

	FDentistBallLauncherSimulationStep GetFirstStep() const
	{
		return Steps[0];
	}
	
	FDentistBallLauncherSimulationStep GetLastStep() const
	{
		return Steps.Last();
	}

	FDentistBallLauncherSimulationStep& GetLastStepRef()
	{
		return Steps.Last();
	}

	FDentistBallLauncherSimulationStep GetStepAtTime(float Time, bool&out bOutIsRolling) const
	{
		bOutIsRolling = false;

		if(Steps.Num() == 0)
			return FDentistBallLauncherSimulationStep();

		if(Steps.Num() == 1)
		{
			bOutIsRolling = Steps[0].bIsGrounded;
			return Steps[0];
		}

		if(Time <= Steps[0].Time)
		{
			bOutIsRolling = Steps[0].bIsGrounded;
			return Steps[0];
		}

		if(Time >= Steps.Last().Time)
		{
			bOutIsRolling = Steps[0].bIsGrounded;
			return Steps.Last();
		}

		FDentistBallLauncherSimulationStep Previous;
		FDentistBallLauncherSimulationStep Next;
		if(!BinarySearchClosestPair(Time, Previous, Next))
			return FDentistBallLauncherSimulationStep();

		// If both this step and the previous are grounded, we are rolling
		bOutIsRolling = Previous.bIsGrounded && Next.bIsGrounded;
		return LerpTime(Previous, Next, Time);
	}

	// Time when we stop moving
	float GetMoveEndTime() const
	{
		return MoveEndTime;
	}

	float GetMoveTime(float LoopTime, EDentistLaunchedBallLoopState&out OutLoopState) const
	{
		if(LoopTime <= 0)
		{
			OutLoopState = EDentistLaunchedBallLoopState::WaitingAtStart;
			return 0;
		}

		if(LoopTime >= GetMoveEndTime())
		{
			OutLoopState = EDentistLaunchedBallLoopState::WaitingAtEnd;
			return GetMoveEndTime();
		}

		OutLoopState = EDentistLaunchedBallLoopState::Moving;

		return LoopTime;
	}

	bool HasHitWater() const
	{
		return HitWaterIndex >= 0;
	}

	private bool BinarySearchClosestPair(float Time, FDentistBallLauncherSimulationStep&out Previous, FDentistBallLauncherSimulationStep&out Next) const
	{
		int PreviousIndex;
		int NextIndex;
		if(!BinarySearchClosestPair(Time, PreviousIndex, NextIndex))
			return false;

		Previous = Steps[PreviousIndex];
		Next = Steps[NextIndex];
		return true;
	}

	private bool BinarySearchClosestPair(float Time, int&out PreviousIndex, int&out NextIndex) const
	{
		if(!ensure(Steps.Num() >= 2))
			return false;

		int Low = 0;
		int High = Steps.Num() - 1;
		int Middle = 0;

		while(Low < High)
		{
			Middle = Math::IntegerDivisionTrunc(Low + High, 2);

			if(Time < Steps[Middle].Time)
			{
				if(Middle > 0 && Time > Steps[Middle - 1].Time)
				{
					PreviousIndex = Middle - 1;
					NextIndex = Middle;
					return true;
				}

				High = Middle;
			}
			else
			{
				if(Middle < Steps.Num() - 1 && Time < Steps[Middle + 1].Time)
				{
					PreviousIndex = Middle;
					NextIndex = Middle + 1;
					return true;
				}

				Low = Middle + 1;
			}
		}

		devError("Failed to find a valid pair!");
		return false;
	}

	private FDentistBallLauncherSimulationStep LerpTime(FDentistBallLauncherSimulationStep Previous, FDentistBallLauncherSimulationStep Next, float Time) const
	{
		check(Previous.Time < Next.Time);
		check(Previous.Time <= Time && Time <= Next.Time);

		const float Alpha = Math::NormalizeToRange(Time, Previous.Time, Next.Time);
		return Previous.LerpTo(Next, Alpha);
	}
};

struct FDentistBallLauncherSimulationStep
{
	access Simulation = private, UDentistLaunchedBallSimulationComponent, FDentistLaunchedBallSimulation;
	/**
	 * During simulation, this is in world space.
	 * After simulation, it will be serialized to be an offset to the owning SimulationLoop actor.
	 */
	access:Simulation
	UPROPERTY(VisibleInstanceOnly)
	FVector SimulationLocation;

	UPROPERTY(VisibleInstanceOnly)
	float Time;

	UPROPERTY(VisibleInstanceOnly)
	FVector Velocity;

	UPROPERTY(VisibleInstanceOnly)
	bool bIsGrounded;

	UPROPERTY(Transient, NotVisible)
	FMovementHitResult GroundContact;

	UPROPERTY(Transient, NotVisible)
	USceneComponent AttachedTo;
	
	UPROPERTY(Transient)
	FTransform AttachmentTransformLastIteration;

	void SerializeRelativeTo(const ADentistSimulationLoop SimulationLoop)
	{
		SimulationLocation = SimulationLocation - SimulationLoop.ActorLocation;
	}

	FVector GetPlaybackLocation(const ADentistSimulationLoop SimulationLoop) const
	{
		return SimulationLoop.ActorLocation + SimulationLocation;
	}

	FDentistBallLauncherSimulationStep LerpTo(FDentistBallLauncherSimulationStep Next, float Alpha) const
	{
		FDentistBallLauncherSimulationStep Result;
		Result.SimulationLocation = Math::Lerp(SimulationLocation, Next.SimulationLocation, Alpha);
		Result.Velocity = Math::Lerp(Velocity, Next.Velocity, Alpha);
		// Why is hermite blending not working? :c
		//Result.Location = Math::CubicInterp(Previous.Location, Previous.Velocity / 3, Next.Location, Next.Velocity / 3, Alpha);
		Result.Time = Math::Lerp(Time, Next.Time, Alpha);
		return Result;
	}
};
enum EDentistDispensedCandyLoopState
{
	Moving,
	ReachedEnd,
};

struct FDentistDispensedCandySimulation
{
	UPROPERTY(VisibleInstanceOnly)
	private TArray<FDentistDispensedCandySimulationStep> Steps;

	UPROPERTY(VisibleInstanceOnly)
	private float SimulationDuration = 0;

	UPROPERTY(VisibleInstanceOnly)
	int HitWaterIndex = -1;

	void AddStep(FDentistDispensedCandySimulationStep Step)
	{
		Steps.Add(Step);
		SimulationDuration = Step.Time;
	}

	int GetStepCount() const
	{
		return Steps.Num();
	}

	FDentistDispensedCandySimulationStep GetStepAtIndex(int Index) const
	{
		if(!ensure(Steps.IsValidIndex(Index)))
			return FDentistDispensedCandySimulationStep();

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

	FDentistDispensedCandySimulationStep GetFirstStep() const
	{
		return Steps[0];
	}
	
	FDentistDispensedCandySimulationStep GetLastStep() const
	{
		return Steps.Last();
	}

	FDentistDispensedCandySimulationStep GetStepAtTime(float Time) const
	{
		if(Steps.Num() == 0)
			return FDentistDispensedCandySimulationStep();

		if(Steps.Num() == 1)
			return Steps[0];

		if(Time <= Steps[0].Time)
			return Steps[0];

		if(Time >= Steps.Last().Time)
			return Steps.Last();

		FDentistDispensedCandySimulationStep Previous;
		FDentistDispensedCandySimulationStep Next;
		if(!BinarySearchClosestPair(Time, Previous, Next))
			return FDentistDispensedCandySimulationStep();

		return LerpTime(Previous, Next, Time);
	}

	float GetSimulationDuration() const
	{
		return SimulationDuration;
	}

	float GetMoveTime(float TimeSinceStart, EDentistDispensedCandyLoopState&out OutLoopState) const
	{
		if(TimeSinceStart > GetSimulationDuration())
		{
			OutLoopState = EDentistDispensedCandyLoopState::ReachedEnd;
			return GetSimulationDuration();
		}
		
		OutLoopState = EDentistDispensedCandyLoopState::Moving;
		return TimeSinceStart;
	}

	bool HasHitWater() const
	{
		return HitWaterIndex >= 0;
	}

	private bool BinarySearchClosestPair(float Time, FDentistDispensedCandySimulationStep&out Previous, FDentistDispensedCandySimulationStep&out Next) const
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

	private FDentistDispensedCandySimulationStep LerpTime(FDentistDispensedCandySimulationStep Previous, FDentistDispensedCandySimulationStep Next, float Time) const
	{
		check(Previous.Time < Next.Time);
		check(Previous.Time <= Time && Time <= Next.Time);

		const float Alpha = Math::NormalizeToRange(Time, Previous.Time, Next.Time);
		return Lerp(Previous, Next, Alpha);
	}

	private FDentistDispensedCandySimulationStep Lerp(FDentistDispensedCandySimulationStep Previous, FDentistDispensedCandySimulationStep Next, float Alpha) const
	{
		FDentistDispensedCandySimulationStep Result;

		Result.Location = Math::Lerp(Previous.Location, Next.Location, Alpha);
		Result.Velocity = Math::Lerp(Previous.Velocity, Next.Velocity, Alpha);
		// Why is hermite blending not working? :c
		//Result.Location = Math::CubicInterp(Previous.Location, Previous.Velocity / 3, Next.Location, Next.Velocity / 3, Alpha);
		Result.Time = Math::Lerp(Previous.Time, Next.Time, Alpha);
		return Result;
	}
};

struct FDentistDispensedCandySimulationStep
{
	UPROPERTY(VisibleInstanceOnly)
	FVector Location;

	UPROPERTY(VisibleInstanceOnly)
	float Time;

	UPROPERTY(VisibleInstanceOnly)
	FVector Velocity;
	
	FMovementHitResult GroundContact;

	bool IsGrounded() const
	{
		return GroundContact.IsWalkableGroundContact();
	}
};

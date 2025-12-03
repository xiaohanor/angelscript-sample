
/**
 * 
 */
struct FMovementDelta
{
	FVector Delta = FVector::ZeroVector;
	FVector Velocity = FVector::ZeroVector;

	FMovementDelta()
	{}

	FMovementDelta(FVector InDelta, FVector InVelocity)
	{
		Delta = InDelta;
        Velocity = InVelocity;
	}

	void Clear()
	{
		Delta = FVector::ZeroVector;
		Velocity = FVector::ZeroVector;
	}

	bool IsNearlyZero(float Tolerance=KINDA_SMALL_NUMBER) const
	{
		if(!Delta.IsNearlyZero(Tolerance))
			return false;
		else if(!Velocity.IsNearlyZero(Tolerance))
			return false;
		else
			return true;
	}
	
	bool IsNormalized() const
	{
		return Delta.IsNormalized() && Velocity.IsNormalized();
	}

	void Normalize()
	{
		Delta.Normalize();
		Velocity.Normalize();
	}
	
	FMovementDelta GetNormalized() const
	{
		FMovementDelta Out = this;
		Out.Normalize();
		Out.Normalize();
		return Out;
	}
	
	bool opEquals(FMovementDelta Other) const
	{
		return Equals(Other);
	}

	bool Equals(FMovementDelta Other, float Tolerance=KINDA_SMALL_NUMBER) const
	{
		return Delta.Equals(Other.Delta, Tolerance) && Velocity.Equals(Other.Velocity, Tolerance);
	}
	
	void opAddAssign(FMovementDelta Other)
	{
		this = opAdd(Other);
	}

	void opAddAssign(FMovementDeltaWithWorldUp Other)
	{
		this = opAdd(Other);
	}
		
	FMovementDelta opAdd(FMovementDelta Other) const
	{
		FMovementDelta Out = this;
		Out.Delta += Other.Delta;
		Out.Velocity += Other.Velocity;
		return Out;
	}

	FMovementDelta opAdd(FMovementDeltaWithWorldUp Other) const
	{
		FMovementDelta Out = this;
		Out.Delta += Other.Delta;
		Out.Velocity += Other.Velocity;
		return Out;
	}

	void opSubAssign(FMovementDelta Other)
	{
		this = opSub(Other);
	}
	
	FMovementDelta opSub(FMovementDelta Other) const
	{
		FMovementDelta Out = this;
		Out.Delta -= Other.Delta;
		Out.Velocity -= Other.Velocity;
		return Out;
	}
	
	void opMulAssign(float Size)
    {
    	this = opMul(Size);
    }

	FMovementDelta opMul(float Size) const
	{
		FMovementDelta Out = this;
		Out.Delta *= Size;
		Out.Velocity *= Size;
		return Out;
	}

	void opDivAssign(float Size)
	{
		this = opDiv(Size);
	}

	FMovementDelta opDiv(float Size) const
	{
		FMovementDelta Out = this;
		Out.Delta /= Size;
		Out.Velocity /= Size;
		return Out;
	}

	FMovementDelta GetHorizontalPart(FVector Up) const
	{	
		FMovementDelta Out = this;
		Out.Delta = Delta.VectorPlaneProject(Up);
		Out.Velocity = Velocity.VectorPlaneProject(Up);
		return Out;
	}

	FMovementDelta GetVerticalPart(FVector Up) const
	{
		FMovementDelta Out = this;
		Out.Delta = Delta.ProjectOnToNormal(Up);
		Out.Velocity = Velocity.ProjectOnToNormal(Up);
		return Out;
	}
}

/**
 * A struct containing both delta and the velocity representing the delta
 * Also has helper functions for rotating the world and constraining the
 * delta and velocity to different surfaces
 */

struct FMovementDeltaWithWorldUp
{
	FVector Delta = FVector::ZeroVector;
	FVector Velocity = FVector::ZeroVector;
	protected FVector WorldUpInternal = FVector::ZeroVector;
	
	FMovementDeltaWithWorldUp()
	{}

	FMovementDeltaWithWorldUp(FVector OriginalWorldUp)
	{
		WorldUpInternal = OriginalWorldUp;
	}

	FMovementDeltaWithWorldUp(FMovementDelta State, FVector OriginalWorldUp)
	{
		Delta = State.Delta;
        Velocity = State.Velocity;
		WorldUpInternal = OriginalWorldUp;
	}
	
	FMovementDeltaWithWorldUp(FVector InDelta, FVector InVelocity, FVector OriginalWorldUp)
	{
		Delta = InDelta;
        Velocity = InVelocity;
		WorldUpInternal = OriginalWorldUp;
	}

	FMovementDelta ConvertToDelta() const
	{
		return FMovementDelta(Delta, Velocity);
	}

	void Clear()
	{
		Delta = FVector::ZeroVector;
		Velocity = FVector::ZeroVector;
	}

	void ChangeWorldUp(FVector NewWorldUp)
	{
		if(NewWorldUp.Equals(WorldUpInternal))
			return;

		check(NewWorldUp.IsNormalized());

		if(!Delta.IsNearlyZero())
			TransformToNewWorldUp(Delta, WorldUpInternal, NewWorldUp);

		if(!Velocity.IsNearlyZero())
			TransformToNewWorldUp(Velocity, WorldUpInternal, NewWorldUp);
		
		WorldUpInternal = NewWorldUp;
	}

	/**
	 * Rotate Vector from the space of CurrentWorldUp to NewWorldUp.
	 */
	private void TransformToNewWorldUp(FVector& Vector, FVector CurrentWorldUp, FVector NewWorldUp) const
	{
		check(!Vector.IsNearlyZero());
		check(CurrentWorldUp.IsNormalized());
		check(NewWorldUp.IsNormalized());

		FQuat CurrentUp;
		FQuat NewUp;

		const bool bIsParallel = CurrentWorldUp.Parallel(NewWorldUp);
		if(!bIsParallel)
		{
			// The default way of defining a rotation
			// Construct a right vector from the two world ups, and create a rotation from that
			const FVector Right = NewWorldUp.CrossProduct(CurrentWorldUp).GetSafeNormal();
			check(Right.IsNormalized());

			CurrentUp = FQuat::MakeFromZY(CurrentWorldUp, Right);
			NewUp = FQuat::MakeFromZY(NewWorldUp, Right);
		}
		else
		{
			// If the world ups are parallel...
			if(Vector.VectorPlaneProject(NewWorldUp).IsNearlyZero())
			{
				// ... and the vector is fully along the plane, we can't create a valid rotation.
				// This can only mean one thing, that we must flip the vertical velocity along the world ups,
				// but keep the horizontal the same.
				const FVector Horizontal = Vector.VectorPlaneProject(NewWorldUp);
				const FVector Vertical = Vector - Horizontal;
				Vector = Horizontal - Vertical;
				return;
			}

			// Use the forward to construct a rotation
			CurrentUp = FQuat::MakeFromZX(CurrentWorldUp, Vector);
			NewUp = FQuat::MakeFromZX(NewWorldUp, Vector);
		}

		Vector = CurrentUp.UnrotateVector(Vector);
		Vector = NewUp.RotateVector(Vector);
	}

	FVector GetWorldUp() const property
	{
		return WorldUpInternal;
	}
	
	FMovementDeltaWithWorldUp GetHorizontalPart() const
	{	
		FMovementDeltaWithWorldUp Out = this;
		Out.Delta = Delta.VectorPlaneProject(WorldUpInternal);
		Out.Velocity = Velocity.VectorPlaneProject(WorldUpInternal);
		return Out;
	}

	FMovementDeltaWithWorldUp GetVerticalPart() const
	{
		FMovementDeltaWithWorldUp Out = this;
		Out.Delta = Delta.ProjectOnToNormal(WorldUpInternal);
		Out.Velocity = Velocity.ProjectOnToNormal(WorldUpInternal);
		return Out;
	}

	void OverrideHorizontal(FVector NewDelta, FVector NewVelocity, FVector UpVector)
	{
		const FMovementDelta InternalVertical = ConvertToDelta().GetVerticalPart(UpVector);
		Delta = NewDelta + InternalVertical.Delta;
		Velocity = NewVelocity + InternalVertical.Velocity;
	}

	void SetHorizontalPart(FVector NewDelta, FVector NewVelocity)
	{
		const FMovementDeltaWithWorldUp Vertical = GetVerticalPart();
		Delta = NewDelta + Vertical.Delta;
		Velocity = NewVelocity + Vertical.Velocity;
	}

	void SetVerticalPart(FVector NewDelta, FVector NewVelocity, FVector Up)
	{
		const FMovementDeltaWithWorldUp Horizontal = GetHorizontalPart();
		Delta = NewDelta + Horizontal.Delta;
		Velocity = NewVelocity + Horizontal.Velocity;
	}
	
	bool ContainsNaN() const
	{
		if(Delta.ContainsNaN())
			return true;
		else if(Velocity.ContainsNaN())
			return true;
		else
			return false;
	}
	
	bool IsNearlyZero(float Tolerance=KINDA_SMALL_NUMBER) const
	{
		if(!Delta.IsNearlyZero(Tolerance))
			return false;
		else if(!Velocity.IsNearlyZero(Tolerance))
			return false;
		else
			return true;
	}
	
	bool IsNormalized() const
	{
		return Delta.IsNormalized() && Velocity.IsNormalized();
	}

	void Normalize()
	{
		Delta.Normalize();
		Velocity.Normalize();
	}
	
	FMovementDeltaWithWorldUp GetNormalized() const
	{
		FMovementDeltaWithWorldUp Out = this;
		Out.Normalize();
		Out.Normalize();
		return Out;
	}

	void ClampToMaxVelocitySize(float Size)
	{
		if(Velocity.IsNearlyZero() || Size < SMALL_NUMBER)
			return;
	
		const float VelSq = Velocity.SizeSquared();
		const float SqSize = Math::Square(Size);
		if(VelSq <= SqSize)
			return;
	
		const FVector OriginalVelocity = Velocity;
		Velocity = Velocity.GetSafeNormal() * Size;
		Delta *= SqSize / VelSq;
	}
	
	void ClampToMaxDeltaSize(float Size)
	{
		if(Delta.IsNearlyZero() || Size < SMALL_NUMBER)
			return;

		const float DeltaSq = Delta.SizeSquared();
		const float SqSize = Math::Square(Size);
		if (DeltaSq <= SqSize)
			return;
	
		Delta = Delta.GetSafeNormal() * Size;
		Velocity *= SqSize / DeltaSq;
	}
	
	bool opEquals(FMovementDeltaWithWorldUp Other) const
	{
		return Equals(Other);
	}

	bool Equals(FMovementDeltaWithWorldUp Other, float Tolerance=KINDA_SMALL_NUMBER) const
	{
		return Delta.Equals(Other.Delta, Tolerance) && Velocity.Equals(Other.Velocity, Tolerance);
	}
	
	void opAddAssign(FMovementDeltaWithWorldUp Other)
	{
		this = opAdd(Other);
	}

	void opAddAssign(FMovementDelta Other)
	{
		this = opAdd(Other);
	}
	
	FMovementDeltaWithWorldUp opAdd(FMovementDeltaWithWorldUp Other) const
	{
		FMovementDeltaWithWorldUp Out = this;
		if(Out.WorldUpInternal.IsNearlyZero())
			Out.WorldUpInternal = Other.WorldUpInternal;
		else
			check(Out.WorldUpInternal.Equals(Other.WorldUpInternal));

		Out.Delta += Other.Delta;
		Out.Velocity += Other.Velocity;
		return Out;
	}

	FMovementDeltaWithWorldUp opAdd(FMovementDelta Other) const
	{
		check(WorldUpInternal.IsUnit());
		FMovementDeltaWithWorldUp Out = this;
		Out.Delta += Other.Delta;
		Out.Velocity += Other.Velocity;
		return Out;
	}
};

enum EMovementIterationDeltaStateType
{
	/**
	 * The default type used when adding velocities/deltas/accelerations to a movement data.
	 * Present on all resolvers.
	 */
	Movement,

	/**
	 * The type used when adding velocities/deltas/accelerations from impulses, usually from AddPendingImpulses.
	 * Present on all resolvers.
	 * 
	 * Differences to Movement:
	 * - Any impulse towards the WorldUp will make you leave the ground.
	 */
	Impulse,

	/**
	 * NOTE: This only exists on Stepping resolvers.
	 * "Horizontal" means velocity along the floor. When using Stepping resolvers, this is what is added to when calling AddHorizontal functions on movement data.
	 * This can contain "vertical" velocity, since the floor is not always completely flat.
	 * 
	 * As Tyko left no documentation about why this exists, here are my findings:
	 * - When moving along the floor and on landing redirects, this is the only delta type to not have its' vertical part removed.
	 * - When returning the resolved velocity to the movement component, this delta is only returned in the HorizontalVelocity parameter.
	 */
	Horizontal,

	/**
	 * The sum of all other delta states.
	 * This is not actually a type, so don't try to initialize it or add it, only get it.
	 */
	Sum,
};

struct FMovementIterationDeltaStates
{
	TMap<EMovementIterationDeltaStateType, FMovementDeltaWithWorldUp> States;

	void Init(EMovementIterationDeltaStateType Type, FVector UpVector)
	{
		check(Type != EMovementIterationDeltaStateType::Sum, "You can't initialize the Sum type, it's not actually a type!");
		States.Add(Type, FMovementDeltaWithWorldUp(UpVector));
	}

	void InitFromMovementData(const UBaseMovementData Data)
	{
		States = Data.DeltaStates.States;
	}
	
	FMovementDeltaWithWorldUp GetState(EMovementIterationDeltaStateType Type = EMovementIterationDeltaStateType::Sum) const
	{
		if(Type == EMovementIterationDeltaStateType::Sum)
		{
			FMovementDeltaWithWorldUp Out;
			for(auto It : States)
				Out += It.Value;
			return Out;
		}
		else
		{
			if(!devEnsure(States.Contains(Type), f"Trying to get a delta type {Type} without first initializing it!"))
				return FMovementDeltaWithWorldUp();

			return States[Type];
		}
	}

	FMovementDelta GetDelta(EMovementIterationDeltaStateType Type = EMovementIterationDeltaStateType::Sum) const
	{
		if(Type == EMovementIterationDeltaStateType::Sum)
		{
			FMovementDelta Out;
			for(auto It : States)
			{
				Out += It.Value;
			}
			return Out;
		}
		else
		{
			if(!devEnsure(States.Contains(Type), f"Trying to get a delta type {Type} without first initializing it!"))
				return FMovementDelta();

			return States[Type].ConvertToDelta();
		}
	}

	void Add(EMovementIterationDeltaStateType Type, FMovementDelta MovementDeltaToAdd)
	{	
		check(Type != EMovementIterationDeltaStateType::Sum, "You can't add to the Sum type, it's not actually a type!");

		if(!devEnsure(States.Contains(Type), f"You added delta type {Type} without first initializing it!"))
			return;

		States[Type] += MovementDeltaToAdd;
	}

	void Add(EMovementIterationDeltaStateType Type, FVector DeltaToAdd, FVector VelocityToAdd)
	{	
		Add(Type, FMovementDelta(DeltaToAdd, VelocityToAdd));
	}

	void Reset()
	{
		States.Reset();
	}
}
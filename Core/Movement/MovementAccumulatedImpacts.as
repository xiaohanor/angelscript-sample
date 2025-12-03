/**
 * Contains all movement impacts from the last move
 */
struct FMovementAccumulatedImpacts
{
	private TArray<FMovementHitResult> AllImpacts;
	private TArray<FHitResult> GroundImpacts;
	private TArray<FHitResult> WallImpacts;
	private TArray<FHitResult> CeilingImpacts;

	void Reset(int MaxIterationCount = 0)
	{
		AllImpacts.Reset(MaxIterationCount * 3);
		GroundImpacts.Reset(MaxIterationCount);
		WallImpacts.Reset(MaxIterationCount);
		CeilingImpacts.Reset(MaxIterationCount);
	}

	void AppendAccumulatedImpacts(FMovementAccumulatedImpacts OtherAccumulatedImpacts)
	{
		AllImpacts.Append(OtherAccumulatedImpacts.AllImpacts);
		GroundImpacts.Append(OtherAccumulatedImpacts.GroundImpacts);
		WallImpacts.Append(OtherAccumulatedImpacts.WallImpacts);
		CeilingImpacts.Append(OtherAccumulatedImpacts.CeilingImpacts);
	}

	void AddImpact(FMovementHitResult Impact)
	{
		if(!Impact.IsValidBlockingHit())
			return;

		AllImpacts.Add(Impact);

		const FHitResult Hit = Impact.ConvertToHitResult();

		if(Impact.IsAnyGroundContact())
		{
			AddImpactInternal(GroundImpacts, Hit);
		}
		else if(Impact.IsWallImpact())
		{
			AddImpactInternal(WallImpacts, Hit);
		}
		else if(Impact.IsCeilingImpact())
		{
			AddImpactInternal(CeilingImpacts, Hit);
		}
	}

	private void AddImpactInternal(TArray<FHitResult>& Impacts, FHitResult Hit)
	{
		check(Impacts.Num() + 1 < Impacts.AllocatedSize, "We allocated too few impacts, increase it in UBaseMovementData");
		Impacts.Add(Hit);
	}

	bool HasImpactedAnything() const
	{
		return !AllImpacts.IsEmpty();
	}

	bool HasImpactedGround() const
	{
		return !GroundImpacts.IsEmpty();
	}

	bool HasImpactedWall() const
	{
		return !WallImpacts.IsEmpty();
	}

	bool HasImpactedCeiling() const
	{
		return !CeilingImpacts.IsEmpty();
	}

	const TArray<FMovementHitResult>& GetAllImpacts() const
	{
		return AllImpacts;
	}

	const TArray<FHitResult>& GetGroundImpacts() const
	{
		return GroundImpacts;
	}

	const TArray<FHitResult>& GetWallImpacts() const
	{
		return WallImpacts;
	}

	const TArray<FHitResult>& GetCeilingImpacts() const
	{
		return CeilingImpacts;
	}

	/**
	 * Get the first impact that is valid of any type.
	 * @param Order The priority order used when returning valid impacts.
	 * @return True if a valid impact was found.
	 */
	bool GetFirstValidImpact(FHitResult&out OutImpact, EMovementAnyContactOrder Order = EMovementAnyContactOrder::GroundWallCeiling) const no_discard
	{
		switch(Order)
		{
			case EMovementAnyContactOrder::GroundWallCeiling:
			{
				if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::GroundCeilingWall:
			{
				if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::WallGroundCeiling:
			{
				if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::WallCeilingGround:
			{
				if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::CeilingGroundWall:
			{
				if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else
					return false;
			}

			case EMovementAnyContactOrder::CeilingWallGround:
			{
				if(GetFirstValidImpact(EMovementImpactType::Ceiling, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Wall, OutImpact))
					return true;
				else if(GetFirstValidImpact(EMovementImpactType::Ground, OutImpact))
					return true;
				else
					return false;
			}
		}
	}

	/**
	 * Get the first impact of ContactType. Only Ground, Wall and Ceiling are valid options.
	 * @return True if an impact is found.
	 */
	bool GetFirstValidImpact(EMovementImpactType ContactType, FHitResult&out OutContact) const
	{
		switch(ContactType)
		{
			case EMovementImpactType::Ground:
			{
				if(!HasImpactedGround())
					return false;

				OutContact = GroundImpacts[0];
				return true;
			}

			case EMovementImpactType::Wall:
			{
				if(!HasImpactedWall())
					return false;

				OutContact = WallImpacts[0];
				return true;
			}

			case EMovementImpactType::Ceiling:
			{
				if(!HasImpactedCeiling())
					return false;

				OutContact = CeilingImpacts[0];
				return true;
			}

			default:
				devError("Invalid ContactType");
				return false;
		}
	}

	/**
	 * Swaps the content of this and Other, faster than copying
	 */
	void Swap(FMovementAccumulatedImpacts& Other)
	{
		FMovementAccumulatedImpacts Temp;
		MoveAssignFrom(Temp, this);
		MoveAssignFrom(this, Other);
		MoveAssignFrom(Other, Temp);
	}

	/**
	 * Moves the internal data between the internal arrays, faster than copying
	 */
	private void MoveAssignFrom(FMovementAccumulatedImpacts& To, FMovementAccumulatedImpacts& From) const
	{
		To.AllImpacts.MoveAssignFrom(From.AllImpacts);
		To.GroundImpacts.MoveAssignFrom(From.GroundImpacts);
		To.WallImpacts.MoveAssignFrom(From.WallImpacts);
		To.CeilingImpacts.MoveAssignFrom(From.CeilingImpacts);
	}
}